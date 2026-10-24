-- Nutritionist booking MVP. Apply in a dedicated Supabase project.
create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create type public.appointment_status as enum ('booked', 'done', 'no_show', 'cancelled');
create type public.app_user_role as enum ('client', 'nutritionist');

create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role public.app_user_role not null default 'client',
  created_at timestamptz not null default now()
);

create table public.business_settings (
  id boolean primary key default true check (id),
  timezone text not null default 'Asia/Kolkata',
  slot_minutes integer not null default 30 check (slot_minutes between 15 and 240),
  updated_at timestamptz not null default now()
);
insert into public.business_settings(id, timezone, slot_minutes)
values(true, 'Asia/Kolkata', 30) on conflict(id) do nothing;

create table public.weekly_availability (
  weekday smallint not null check (weekday between 0 and 6),
  opens_at time not null,
  closes_at time not null check(closes_at > opens_at),
  enabled boolean not null default true,
  primary key (weekday, opens_at)
);
-- Clearly labeled editable development defaults, not a representation of actual business hours.
insert into public.weekly_availability(weekday,opens_at,closes_at,enabled) values
 (1,'09:00','17:00',true),(2,'09:00','17:00',true),(3,'09:00','17:00',true),
 (4,'09:00','17:00',true),(5,'09:00','17:00',true)
on conflict do nothing;

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  client_user_id uuid references auth.users(id) on delete set null,
  client_name text not null check (length(trim(client_name)) between 1 and 160),
  client_phone text check (client_phone is null or length(client_phone) <= 40),
  client_email text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.appointment_status not null default 'booked',
  source text not null default 'client' check (source in ('client','staff','sample')),
  is_sample boolean generated always as (source = 'sample') stored,
  sample_key text unique,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check(ends_at > starts_at),
  check(client_email is null or length(client_email) <= 320)
);
-- A partial unique index is the final same-slot race guard. Cancelled rows release the slot.
create unique index appointments_active_start_unique on public.appointments(starts_at) where status <> 'cancelled';
alter table public.appointments add constraint appointments_active_no_overlap
  exclude using gist (tstzrange(starts_at,ends_at,'[)') with &&) where (status <> 'cancelled');
create index appointments_client_schedule on public.appointments(client_user_id, starts_at desc);
create index appointments_schedule on public.appointments(starts_at);
create index appointments_client_name on public.appointments using gin (to_tsvector('simple', client_name));

create table public.appointment_events (
  id bigint generated always as identity primary key,
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null check(event_type in ('created','rescheduled','cancelled','status_changed','claimed')),
  old_starts_at timestamptz,
  new_starts_at timestamptz,
  old_status public.appointment_status,
  new_status public.appointment_status,
  created_at timestamptz not null default now()
);

create or replace function public.is_nutritionist()
returns boolean language sql stable security definer set search_path = public, auth
as $$ select exists(select 1 from public.user_roles where user_id = auth.uid() and role = 'nutritionist'); $$;

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public, auth
as $$ begin
  insert into public.user_roles(user_id, role) values(new.id, 'client') on conflict(user_id) do nothing;
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_auth_user();

alter table public.user_roles enable row level security;
alter table public.business_settings enable row level security;
alter table public.weekly_availability enable row level security;
alter table public.appointments enable row level security;
alter table public.appointment_events enable row level security;

create policy "users read own role or staff roles" on public.user_roles for select to authenticated
 using(user_id = auth.uid() or public.is_nutritionist());
create policy "anyone reads published availability" on public.weekly_availability for select to anon, authenticated using(enabled);
create policy "staff manages availability" on public.weekly_availability for all to authenticated
 using(public.is_nutritionist()) with check(public.is_nutritionist());
create policy "authenticated reads business settings" on public.business_settings for select to authenticated using(true);
create policy "staff manages business settings" on public.business_settings for update to authenticated
 using(public.is_nutritionist()) with check(public.is_nutritionist());
create policy "clients read own and staff read all appointments" on public.appointments for select to authenticated
 using(client_user_id = auth.uid() or public.is_nutritionist());
create policy "staff read appointment event history" on public.appointment_events for select to authenticated using(public.is_nutritionist());
-- No direct appointment INSERT/UPDATE/DELETE policies: all mutations use guarded RPCs below.

create or replace function public.available_slots(p_date date)
returns table(slot_time time)
language plpgsql stable security definer set search_path = public, auth
as $$
declare v_tz text; v_minutes int;
begin
  select timezone, slot_minutes into v_tz, v_minutes from public.business_settings where id;
  return query
    with candidates as (
      select (p_date + a.opens_at + (n * make_interval(mins => v_minutes)))::time as local_time
      from public.weekly_availability a
      cross join lateral generate_series(0, 480) n
      where a.enabled and a.weekday = extract(dow from p_date)::int
        and p_date + a.opens_at + (n * make_interval(mins => v_minutes)) + make_interval(mins => v_minutes) <= p_date + a.closes_at
    )
    select c.local_time from candidates c
    where (p_date + c.local_time) at time zone v_tz > now()
      and not exists(select 1 from public.appointments ap
        where ap.status <> 'cancelled' and tstzrange(ap.starts_at,ap.ends_at,'[)') &&
          tstzrange(((p_date + c.local_time) at time zone v_tz),((p_date + c.local_time) at time zone v_tz)+make_interval(mins=>v_minutes),'[)'))
    order by c.local_time;
end $$;
grant execute on function public.available_slots(date) to anon, authenticated;

create or replace function public.create_booking(p_client_name text,p_client_phone text,p_starts_at timestamptz)
returns uuid language plpgsql security definer set search_path = public, auth
as $$
declare v_id uuid; v_email text; v_tz text; v_minutes int; v_local timestamp; v_weekday int;
begin
  if auth.uid() is null then raise exception 'Sign in before booking.' using errcode='42501'; end if;
  if length(trim(coalesce(p_client_name,''))) not between 1 and 160 then raise exception 'Enter a valid name.'; end if;
  if length(regexp_replace(coalesce(p_client_phone,''),'\D','','g')) not between 7 and 15 then raise exception 'Enter a valid phone number.'; end if;
  select timezone,slot_minutes into v_tz,v_minutes from public.business_settings where id;
  v_email := (auth.jwt()->>'email'); v_local := p_starts_at at time zone v_tz; v_weekday := extract(dow from v_local)::int;
  if p_starts_at <= now() then raise exception 'That time has already passed.'; end if;
  if mod(extract(epoch from v_local::time)::int, v_minutes*60) <> 0 then raise exception 'That is not a valid appointment slot.'; end if;
  if not exists(select 1 from public.weekly_availability a where a.enabled and a.weekday=v_weekday
    and v_local::time >= a.opens_at and v_local::time + make_interval(mins=>v_minutes) <= a.closes_at) then raise exception 'That time is outside the configured availability.'; end if;
  insert into public.appointments(client_user_id,client_name,client_phone,client_email,starts_at,ends_at,source,created_by)
  values(auth.uid(),trim(p_client_name),trim(p_client_phone),v_email,p_starts_at,p_starts_at+make_interval(mins=>v_minutes),'client',auth.uid()) returning id into v_id;
  insert into public.appointment_events(appointment_id,actor_id,event_type,new_starts_at,new_status) values(v_id,auth.uid(),'created',p_starts_at,'booked');
  return v_id;
exception when unique_violation then raise exception 'That time was just booked. Please choose another available slot.' using errcode='23P01';
when exclusion_violation then raise exception 'That time overlaps another appointment. Please choose another available slot.' using errcode='23P01';
end $$;
grant execute on function public.create_booking(text,text,timestamptz) to authenticated;
revoke execute on function public.create_booking(text,text,timestamptz) from public, anon;

create or replace function public.cancel_appointment(p_appointment_id uuid)
returns void language plpgsql security definer set search_path = public, auth
as $$ declare v_start timestamptz; v_status public.appointment_status; begin
  select starts_at,status into v_start,v_status from public.appointments where id=p_appointment_id and client_user_id=auth.uid() for update;
  if not found then raise exception 'Appointment not found.' using errcode='P0002'; end if;
  if v_status <> 'booked' or v_start <= now() then raise exception 'This appointment can no longer be cancelled.'; end if;
  update public.appointments set status='cancelled',updated_at=now() where id=p_appointment_id;
  insert into public.appointment_events(appointment_id,actor_id,event_type,old_starts_at,new_starts_at,old_status,new_status) values(p_appointment_id,auth.uid(),'cancelled',v_start,v_start,'booked','cancelled');
end $$;
grant execute on function public.cancel_appointment(uuid) to authenticated;
revoke execute on function public.cancel_appointment(uuid) from public, anon;

create or replace function public.reschedule_appointment(p_appointment_id uuid,p_new_starts_at timestamptz)
returns void language plpgsql security definer set search_path = public, auth
as $$ declare v_old timestamptz; v_status public.appointment_status; v_tz text; v_minutes int; v_local timestamp; begin
  select starts_at,status into v_old,v_status from public.appointments where id=p_appointment_id and client_user_id=auth.uid() for update;
  if not found then raise exception 'Appointment not found.' using errcode='P0002'; end if;
  if v_status <> 'booked' or v_old <= now() then raise exception 'This appointment can no longer be rescheduled.'; end if;
  select timezone,slot_minutes into v_tz,v_minutes from public.business_settings where id; v_local:=p_new_starts_at at time zone v_tz;
  if p_new_starts_at<=now() or mod(extract(epoch from v_local::time)::int,v_minutes*60)<>0 then raise exception 'Choose a valid future appointment time.'; end if;
  if not exists(select 1 from public.weekly_availability a where a.enabled and a.weekday=extract(dow from v_local)::int and v_local::time>=a.opens_at and v_local::time+make_interval(mins=>v_minutes)<=a.closes_at) then raise exception 'That time is outside the configured availability.'; end if;
  update public.appointments set starts_at=p_new_starts_at,ends_at=p_new_starts_at+make_interval(mins=>v_minutes),updated_at=now() where id=p_appointment_id;
  insert into public.appointment_events(appointment_id,actor_id,event_type,old_starts_at,new_starts_at) values(p_appointment_id,auth.uid(),'rescheduled',v_old,p_new_starts_at);
exception when unique_violation or exclusion_violation then raise exception 'That time was just booked. Your original time is still saved.' using errcode='23P01';
end $$;
grant execute on function public.reschedule_appointment(uuid,timestamptz) to authenticated;
revoke execute on function public.reschedule_appointment(uuid,timestamptz) from public, anon;

create or replace function public.set_appointment_status(p_appointment_id uuid,p_status public.appointment_status)
returns void language plpgsql security definer set search_path = public, auth
as $$ declare v_old public.appointment_status; begin
  if not public.is_nutritionist() then raise exception 'Nutritionist access required.' using errcode='42501'; end if;
  if p_status not in ('booked','done','no_show','cancelled') then raise exception 'Invalid status.'; end if;
  select status into v_old from public.appointments where id=p_appointment_id for update;
  if not found then raise exception 'Appointment not found.' using errcode='P0002'; end if;
  if v_old <> 'booked' and p_status <> v_old then raise exception 'Completed, no-show, and cancelled appointments are terminal.'; end if;
  if v_old='cancelled' and p_status<>'cancelled' then raise exception 'Cancelled appointments cannot be reopened.'; end if;
  update public.appointments set status=p_status,updated_at=now() where id=p_appointment_id;
  insert into public.appointment_events(appointment_id,actor_id,event_type,old_status,new_status) values(p_appointment_id,auth.uid(),'status_changed',v_old,p_status);
end $$;
grant execute on function public.set_appointment_status(uuid,public.appointment_status) to authenticated;
revoke execute on function public.set_appointment_status(uuid,public.appointment_status) from public, anon;

create or replace function public.staff_create_appointment(p_client_name text,p_client_phone text,p_client_email text,p_starts_at timestamptz)
returns uuid language plpgsql security definer set search_path = public, auth
as $$ declare v_id uuid; v_user uuid; v_mins int; begin
  if not public.is_nutritionist() then raise exception 'Nutritionist access required.' using errcode='42501'; end if;
  if length(trim(coalesce(p_client_name,''))) not between 1 and 160 then raise exception 'Enter a valid name.'; end if;
  if p_client_email is not null then select id into v_user from auth.users where lower(email)=lower(trim(p_client_email)) and email_confirmed_at is not null; end if;
  select slot_minutes into v_mins from public.business_settings where id;
  if p_starts_at<=now() then raise exception 'Manual appointments must be in the future.'; end if;
  if mod(extract(epoch from (p_starts_at at time zone (select timezone from public.business_settings where id))::time)::int,v_mins*60)<>0 then raise exception 'Choose a valid appointment slot.'; end if;
  if not exists(select 1 from public.weekly_availability a where a.enabled
    and a.weekday=extract(dow from (p_starts_at at time zone (select timezone from public.business_settings where id)))::int
    and (p_starts_at at time zone (select timezone from public.business_settings where id))::time>=a.opens_at
    and (p_starts_at at time zone (select timezone from public.business_settings where id))::time+make_interval(mins=>v_mins)<=a.closes_at) then raise exception 'Choose a time inside configured availability.'; end if;
  insert into public.appointments(client_user_id,client_name,client_phone,client_email,starts_at,ends_at,source,created_by)
    values(v_user,trim(p_client_name),nullif(trim(p_client_phone),''),lower(nullif(trim(p_client_email),'')),p_starts_at,p_starts_at+make_interval(mins=>v_mins),'staff',auth.uid()) returning id into v_id;
  insert into public.appointment_events(appointment_id,actor_id,event_type,new_starts_at,new_status) values(v_id,auth.uid(),'created',p_starts_at,'booked'); return v_id;
exception when unique_violation or exclusion_violation then raise exception 'That time overlaps another appointment.' using errcode='23P01'; end $$;
grant execute on function public.staff_create_appointment(text,text,text,timestamptz) to authenticated;
revoke execute on function public.staff_create_appointment(text,text,text,timestamptz) from public, anon;

create or replace function public.save_business_schedule(p_timezone text,p_slot_minutes integer,p_days jsonb)
returns void language plpgsql security definer set search_path = public, auth
as $$ begin
  if not public.is_nutritionist() then raise exception 'Nutritionist access required.' using errcode='42501'; end if;
  if not exists(select 1 from pg_timezone_names where name=p_timezone) then raise exception 'Use a valid IANA timezone.'; end if;
  if p_slot_minutes not between 15 and 240 then raise exception 'Slot duration must be between 15 and 240 minutes.'; end if;
  if jsonb_typeof(p_days)<>'array' then raise exception 'Schedule must be a list of weekdays.'; end if;
  delete from public.weekly_availability where weekday between 0 and 6;
  insert into public.weekly_availability(weekday,opens_at,closes_at,enabled)
    select (d->>'weekday')::smallint,(d->>'opens_at')::time,(d->>'closes_at')::time,coalesce((d->>'enabled')::boolean,false)
    from jsonb_array_elements(p_days) d where coalesce((d->>'enabled')::boolean,false);
  update public.business_settings set timezone=p_timezone,slot_minutes=p_slot_minutes,updated_at=now() where id;
end $$;
grant execute on function public.save_business_schedule(text,integer,jsonb) to authenticated;
revoke execute on function public.save_business_schedule(text,integer,jsonb) from public, anon;

create or replace function public.claim_staff_appointments()
returns integer language plpgsql security definer set search_path = public, auth
as $$ declare v_email text; v_count int; begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
  v_email:=lower(auth.jwt()->>'email');
  with claimed as (
    update public.appointments set client_user_id=auth.uid(),updated_at=now()
    where client_user_id is null and source='staff' and lower(client_email)=v_email returning id
  )
  insert into public.appointment_events(appointment_id,actor_id,event_type)
    select id,auth.uid(),'claimed' from claimed;
  get diagnostics v_count=row_count;
  return v_count;
end $$;
grant execute on function public.claim_staff_appointments() to authenticated;
revoke execute on function public.claim_staff_appointments() from public, anon;

-- Sample rows are intentionally staff-only legacy examples and do not create fake auth users.
-- Values and dates are preserved from the assignment; missing phone remains NULL.
insert into public.appointments(client_name,client_phone,starts_at,ends_at,status,source,sample_key)
select v.name,v.phone,v.local_start at time zone 'Asia/Kolkata',v.local_start at time zone 'Asia/Kolkata'+interval '30 minutes',v.status,'sample',v.sample_key
from (values
 ('Riya Shah','98200 11111',timestamp '2026-10-24 10:00', 'booked'::public.appointment_status,'sample-riya-20261024-1000'),
 ('Arjun Mehta','98200 22222',timestamp '2026-10-24 11:30', 'booked'::public.appointment_status,'sample-arjun-20261024-1130'),
 ('Riya Shah','9820011111',timestamp '2026-10-25 16:00', 'booked'::public.appointment_status,'sample-riya-20261025-1600'),
 ('Meera Iyer',null,timestamp '2026-10-23 09:00', 'done'::public.appointment_status,'sample-meera-20261023-0900'),
 ('Kabir Rao','98200 33333',timestamp '2026-10-22 14:00', 'no_show'::public.appointment_status,'sample-kabir-20261022-1400')
) as v(name,phone,local_start,status,sample_key)
where not exists(select 1 from public.appointments a where a.sample_key=v.sample_key);

-- Promote the chosen staff account by running as project owner after that Auth user exists:
-- insert into public.user_roles(user_id, role) values('<AUTH_USER_UUID>', 'nutritionist')
-- on conflict(user_id) do update set role='nutritionist';
