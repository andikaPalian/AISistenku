import { Router } from 'express';
import authRoutes from './auth.js';
import dashboardRoutes from './dashboard.js';
import productRoutes from './products.js';
import orderRoutes from './orders.js';
import stockRoutes from './stocks.js';
import financeRoutes from './finance.js';
import aiRoutes from './ai.js';
import uploadRoutes from './uploads.js';

const router = Router();

router.get('/', (_req, res) => {
  res.json({
    name: 'Tiga Angkatan API',
    version: '1.0.0',
    status: 'online',
    timestamp: new Date().toISOString(),
  });
});

router.use('/auth', authRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/products', productRoutes);
router.use('/orders', orderRoutes);
router.use('/stocks', stockRoutes);
router.use('/finance', financeRoutes);
router.use('/ai', aiRoutes);
router.use('/uploads', uploadRoutes);

export default router;
