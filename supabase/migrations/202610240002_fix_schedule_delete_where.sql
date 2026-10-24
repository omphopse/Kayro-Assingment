-- Allow availability edits when Supabase's safe-update guard requires a WHERE clause.
-- The weekday constraint limits every stored row to 0 through 6, so this clears
-- the complete weekly schedule while retaining the original staff authorization.
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
