import { supabase } from '../lib/supabase.js';
import { store, DEMO_USER_ID } from '../lib/store.js';

export const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // Default demo fallback if unauthenticated
      req.user = {
        user_id: DEMO_USER_ID,
        name: 'Owner Cafe (Demo)',
        email: 'owner@tigaangkatan.id',
        role: 'owner',
      };
      return next();
    }

    const token = authHeader.split(' ')[1];

    // Check in-memory active sessions
    if (store.sessions && store.sessions[token]) {
      const u = store.sessions[token];
      req.user = {
        user_id: u.id || u.user_id,
        name: u.name || 'Owner',
        email: u.email || 'user@tigaangkatan.id',
        role: u.role || 'owner',
      };
      return next();
    }

    if (!supabase) {
      req.user = {
        user_id: DEMO_USER_ID,
        name: 'Owner Cafe',
        email: 'owner@tigaangkatan.id',
        role: 'owner',
      };
      return next();
    }

    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data?.user) {
      return res.status(401).json({ error: 'Unauthorized token' });
    }

    req.user = {
      user_id: data.user.id,
      email: data.user.email,
      name: data.user.user_metadata?.name || 'User',
      role: data.user.user_metadata?.role || 'owner',
    };

    next();
  } catch (err) {
    next(err);
  }
};
