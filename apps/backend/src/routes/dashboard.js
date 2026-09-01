import { Router } from 'express';
import { getDashboardOverview } from '../controllers/dashboardController.js';
import { authMiddleware } from '../middleware/auth.js';

const router = Router();

router.get('/overview', authMiddleware, getDashboardOverview);

export default router;
