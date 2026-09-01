import { Router } from 'express';

const router = Router();

// TODO: tambahkan routes di sini
// Contoh:
// import userRoutes from './users.js';
// router.use('/users', userRoutes);

router.get('/', (_req, res) => {
  res.json({ message: 'Tiga Angkatan API v1' });
});

export default router;
