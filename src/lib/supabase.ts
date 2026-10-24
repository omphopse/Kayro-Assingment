import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined;

export const isSupabaseConfigured = Boolean(url && key && !url.includes('your-project-ref'));
export const supabase = isSupabaseConfigured
  ? createClient(url!, key!)
  : null;

export function missingSupabaseMessage() {
  return 'Connect your Supabase project by copying its Project URL and publishable key into .env.local. No booking or authentication data is simulated.';
}
