import { supabase } from '../lib/supabase.js';

export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    if (!supabase) {
      return res.status(503).json({ error: 'Supabase not configured on server' });
    }
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error || !data?.user) {
      return res.status(401).json({ error: error?.message || 'Invalid credentials' });
    }
    return res.json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      user: {
        id: data.user.id,
        email: data.user.email,
        name: data.user.user_metadata?.name || 'Owner',
        role: data.user.user_metadata?.role || 'owner',
      },
    });
  } catch (err) {
    next(err);
  }
};

export const register = async (req, res, next) => {
  try {
    const { email, password, name } = req.body;
    console.log(`[auth/register] attempt email=${email} name=${name}`);
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    if (!supabase) {
      return res.status(503).json({ error: 'Supabase not configured on server' });
    }
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { name: name || 'Owner', role: 'owner' } },
    });
    if (error) {
      console.error(`[auth/register] supabase error:`, error.message, error.status);
      return res.status(400).json({ error: error.message });
    }
    console.log(`[auth/register] success user_id=${data.user?.id} has_session=${!!data.session}`);
    return res.status(201).json({
      access_token: data.session?.access_token || null,
      refresh_token: data.session?.refresh_token || null,
      user: {
        id: data.user?.id,
        email: data.user?.email,
        name: name || 'Owner',
        role: 'owner',
      },
      message: data.session
        ? 'Registration successful'
        : 'Registrasi berhasil. Cek email Anda untuk konfirmasi, lalu login.',
    });
  } catch (err) {
    console.error(`[auth/register] exception:`, err.message);
    next(err);
  }
};

export const getMe = async (req, res, next) => {
  try {
    if (supabase) {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('user_id', req.user.user_id)
        .maybeSingle();

      if (!error && data) {
        return res.json({ user: data });
      }
    }

    // Fallback info
    return res.json({
      user: {
        user_id: req.user.user_id,
        name: req.user.name || 'Owner Tiga Angkatan',
        email: req.user.email || 'owner@tigaangkatan.id',
        role: req.user.role || 'owner',
        created_at: new Date().toISOString(),
      },
    });
  } catch (err) {
    next(err);
  }
};
