import { supabase } from '../lib/supabase.js';

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
