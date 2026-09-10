import { Router } from 'express';
import * as dashboardController from './dashboard.controller.js';
import { requireAuth } from '@/middleware/auth.middleware.js';
import { requireBusinessContext } from '@/middleware/business-context.middleware.js';

export const dashboardRouter = Router();

// Semua rute dashboard wajib auth dan konteks tenant bisnis aktif
dashboardRouter.use(requireAuth);
dashboardRouter.use(requireBusinessContext);

// API Contract standard endpoints
dashboardRouter.get('/summary', dashboardController.getSummary);
dashboardRouter.get('/overview', dashboardController.getSummary); // Alias for frontend
dashboardRouter.get('/sales-trend', dashboardController.getSalesTrend);
dashboardRouter.get('/top-products', dashboardController.getTopProducts);
