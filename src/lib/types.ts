export type AppointmentStatus = 'booked' | 'done' | 'no_show' | 'cancelled';
export type Appointment = {
  id: string;
  client_name: string;
  client_phone: string | null;
  client_email?: string;
  starts_at: string;
  ends_at: string;
  status: AppointmentStatus;
  is_sample?: boolean;
};

export function prettyStatus(status: AppointmentStatus) {
  return ({ booked: 'Booked', done: 'Done', no_show: 'No-show', cancelled: 'Cancelled' })[status];
}
