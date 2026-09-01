import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

let supabaseClient = null;
let connectionStatus = 'uninitialized';

function validateEnv() {
  const missing = [];
  if (!supabaseUrl) missing.push('SUPABASE_URL');
  if (!supabaseServiceKey) missing.push('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseAnonKey) missing.push('SUPABASE_ANON_KEY');

  if (missing.length > 0) {
    connectionStatus = 'missing_env';
    return false;
  }

  // Basic format check — Supabase service keys are JWT tokens starting with 'eyJ'
  if (!supabaseServiceKey.startsWith('eyJ')) {
    console.warn(
      '⚠️  SUPABASE_SERVICE_ROLE_KEY does not look like a valid JWT. ' +
      'Expected format: "eyJhbGciOi...". ' +
      'Get the correct key from Supabase Dashboard → Settings → API.'
    );
    connectionStatus = 'invalid_key_format';
    return false;
  }

  return true;
}

if (validateEnv()) {
  try {
    supabaseClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });
    connectionStatus = 'initialized';
  } catch (err) {
    console.error('❌ Supabase client initialization failed:', err.message);
    connectionStatus = 'init_error';
  }
} else {
  console.warn(
    '⚠️  Missing Supabase env vars. Backend will run but database queries will fail. ' +
    'Copy .env.example to .env and fill in real keys.'
  );
}

export const supabase = supabaseClient;
export const getConnectionStatus = () => connectionStatus;

/**
 * Lightweight connectivity check — call at server startup to fail fast
 * if Supabase is unreachable or credentials are wrong.
 */
export async function pingSupabase() {
  if (!supabaseClient) {
    return { ok: false, reason: 'client_not_initialized', status: connectionStatus };
  }
  try {
    const { error } = await supabaseClient.from('products').select('product_id').limit(1);
    if (error) {
      return { ok: false, reason: 'query_failed', error: error.message, code: error.code };
    }
    return { ok: true };
  } catch (err) {
    return { ok: false, reason: 'network_error', error: err.message };
  }
}