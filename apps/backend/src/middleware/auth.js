import { supabase } from '../lib/supabase.js';

export const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // Default fallback mock user for development
      req.user = {
        user_id: '00000000-0000-0000-0000-000000000001',
        name: 'Owner Cafe',
        email: 'owner@tigaangkatan.id',
        role: 'owner',
      };
      return next();
    }

    const token = authHeader.split(' ')[1];
    if (!supabase) {
      req.user = {
        user_id: '00000000-0000-0000-0000-000000000001',
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
