import { Request, Response } from 'express';
import * as dashboardService from './dashboard.service.js';
import { sendSuccess } from '@/http/response.js';

export const getSummary = async (req: Request, res: Response): Promise<void> => {
  const summary = await dashboardService.getDashboardSummary(req.businessId!);
  
  res.status(200).json({
    success: true,
    message: 'Ringkasan performa bisnis berhasil diambil',
    data: summary,
    ...summary, // Interop for frontend prototype direct access
  });
};

export const getSalesTrend = async (req: Request, res: Response): Promise<void> => {
  const range = (req.query.range as '7d' | '30d' | '90d') || '7d';
  const trend = await dashboardService.getSalesTrend(req.businessId!, range);
  sendSuccess(res, trend, 'Data tren penjualan berhasil diambil');
};

export const getTopProducts = async (req: Request, res: Response): Promise<void> => {
  const range = (req.query.range as '7d' | '30d' | '90d') || '7d';
  const limit = req.query.limit ? Number(req.query.limit) : 5;
  const topProducts = await dashboardService.getTopProducts(req.businessId!, range, limit);
  sendSuccess(res, topProducts, 'Daftar produk terlaris berhasil diambil');
};
