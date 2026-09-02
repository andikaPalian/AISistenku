import { supabase } from '../lib/supabase.js';
import { store, DEMO_USER_ID } from '../lib/store.js';

export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    if (!supabase) {
      // Find existing user in store.users
      let user = store.users.find((u) => u.email.toLowerCase() === email.toLowerCase());
      if (!user) {
        if (email.toLowerCase() === 'owner@tigaangkatan.id') {
          user = store.users.find((u) => u.user_id === DEMO_USER_ID);
        } else {
          user = {
            user_id: `user-${Date.now()}`,
            email: email,
            name: email.split('@')[0] || 'Owner',
            role: 'owner',
            created_at: new Date().toISOString(),
          };
          store.users.push(user);
        }
      }

      const token = 'dev-token-' + Date.now();
      store.sessions[token] = {
        id: user.user_id,
        user_id: user.user_id,
        email: user.email,
        name: user.name,
        role: user.role,
      };

      return res.json({
        access_token: token,
        refresh_token: 'dev-refresh-token',
        user: {
          id: user.user_id,
          email: user.email,
          name: user.name,
          role: user.role,
        },
      });
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

    const newUserId = `user-${Date.now()}`;
    const newUser = {
      user_id: newUserId,
      email: email,
      name: name || 'Owner',
      role: 'owner',
      created_at: new Date().toISOString(),
    };

    store.users.push(newUser);
    const token = 'dev-token-' + Date.now();
    store.sessions[token] = {
      id: newUserId,
      user_id: newUserId,
      email: email,
      name: name || 'Owner',
      role: 'owner',
    };

    if (!supabase) {
      return res.status(201).json({
        access_token: token,
        refresh_token: 'dev-refresh-token',
        user: {
          id: newUserId,
          email: email,
          name: name || 'Owner',
          role: 'owner',
        },
        message: 'Registration successful',
      });
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

    const assignedId = data.user?.id || newUserId;
    store.sessions[token] = {
      id: assignedId,
      user_id: assignedId,
      email: email,
      name: name || 'Owner',
      role: 'owner',
    };

    return res.status(201).json({
      access_token: data.session?.access_token || token,
      refresh_token: data.session?.refresh_token || null,
      user: {
        id: assignedId,
        email: data.user?.email || email,
        name: name || 'Owner',
        role: 'owner',
      },
      message: 'Registration successful',
    });
  } catch (err) {
    console.error(`[auth/register] exception:`, err.message);
    next(err);
  }
};

export const logout = async (req, res, next) => {
  try {
    // Stateless JWT: revocation is best-effort client-side.
    // If Supabase is up we sign the user out server-side too.
    if (supabase) {
      const authHeader = req.headers.authorization || '';
      const token = authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;
      if (token) {
        await supabase.auth.admin.signOut(token).catch(() => null);
      }
    }
    return res.json({ message: 'Logged out' });
  } catch (err) { next(err); }
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
