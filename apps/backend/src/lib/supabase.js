import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

let supabaseClient = null;

if (supabaseUrl && supabaseServiceKey) {
  try {
    supabaseClient = createClient(supabaseUrl, supabaseServiceKey);
  } catch (err) {
    console.warn('⚠️ Supabase client initialization warning:', err.message);
  }
} else {
  console.warn('⚠️ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars. Running in hybrid/store mode.');
}

export const supabase = supabaseClient;
