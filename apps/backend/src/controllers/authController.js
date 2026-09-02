import { supabase } from '../lib/supabase.js';
import { store, DEMO_USER_ID } from '../lib/store.js';

export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const cleanEmail = email.toLowerCase().trim();
    const isDemo = cleanEmail === 'owner@tigaangkatan.id';

    // 1. Instant Demo Account Login
    if (isDemo) {
      const demoToken = 'demo-token-' + Date.now();
      store.sessions[demoToken] = {
        id: DEMO_USER_ID,
        user_id: DEMO_USER_ID,
        email: 'owner@tigaangkatan.id',
        name: 'Pemilik Kafe (Demo)',
        role: 'owner',
      };
      return res.json({
        access_token: demoToken,
        refresh_token: 'demo-refresh-token',
        user: {
          id: DEMO_USER_ID,
          email: 'owner@tigaangkatan.id',
          name: 'Pemilik Kafe (Demo)',
          role: 'owner',
        },
      });
    }

    // 2. Check in-memory store users (e.g. users registered during dev/session)
    const localUser = store.users.find(
      (u) => u.email.toLowerCase() === cleanEmail
    );

    // If Supabase is connected, try Supabase Auth first
    if (supabase) {
      try {
        const { data, error } = await supabase.auth.signInWithPassword({ email: cleanEmail, password });
        if (!error && data?.user && data?.session) {
          const token = data.session.access_token;
          store.sessions[token] = {
            id: data.user.id,
            user_id: data.user.id,
            email: data.user.email,
            name: data.user.user_metadata?.name || 'Owner',
            role: data.user.user_metadata?.role || 'owner',
          };
          return res.json({
            access_token: token,
            refresh_token: data.session.refresh_token,
            user: {
              id: data.user.id,
              email: data.user.email,
              name: data.user.user_metadata?.name || 'Owner',
              role: data.user.user_metadata?.role || 'owner',
            },
          });
        } else if (error) {
           if (error.message.includes('Invalid login credentials')) {
               return res.status(401).json({ error: 'Email atau password salah. Pastikan Anda telah mendaftar.' });
           }
           return res.status(401).json({ error: error.message });
        }
      } catch (err) {
        console.warn('[auth/login] Supabase auth attempt error:', err?.message);
      }
    }

    // 3. If local user exists in store, allow login with session token
    if (localUser) {
      const token = 'dev-token-' + Date.now();
      store.sessions[token] = {
        id: localUser.user_id,
        user_id: localUser.user_id,
        email: localUser.email,
        name: localUser.name,
        role: localUser.role,
      };
      return res.json({
        access_token: token,
        refresh_token: 'dev-refresh-token',
        user: {
          id: localUser.user_id,
          email: localUser.email,
          name: localUser.name,
          role: localUser.role,
        },
      });
    }

    // 4. If user not found anywhere:
    return res.status(401).json({
      error: 'Akun belum terdaftar. Silakan klik tab "Daftar Baru" untuk membuat akun toko Anda.',
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

    let assignedId = newUserId;
    let accessToken = token;

    if (supabase) {
      try {
        const { data, error } = await supabase.auth.signUp({
          email,
          password,
          options: { data: { name: name || 'Owner', role: 'owner' } },
        });
        if (!error && data?.user) {
          assignedId = data.user.id;
          accessToken = data.session?.access_token || token;
        } else if (error) {
          console.warn('[auth/register] Supabase signup note (fallback to isolated session):', error.message);
        }
      } catch (err) {
        console.warn('[auth/register] Supabase signUp exception:', err?.message);
      }
    }

    store.sessions[accessToken] = {
      id: assignedId,
      user_id: assignedId,
      email: email,
      name: name || 'Owner',
      role: 'owner',
    };

    return res.status(201).json({
      access_token: accessToken,
      refresh_token: 'dev-refresh-token',
      user: {
        id: assignedId,
        email: email,
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
