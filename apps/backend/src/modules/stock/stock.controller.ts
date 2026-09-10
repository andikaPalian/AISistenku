import { Request, Response } from 'express';
import * as stockService from './stock.service.js';
import { sendEmptySuccess, sendSuccess } from '@/http/response.js';
import { ListStockQuery } from './stock.validator.js';

export const listStocks = async (req: Request, res: Response): Promise<void> => {
  const query = req.query as unknown as ListStockQuery;
  const stocks = await stockService.listStocks(req.businessId!, query);

  res.status(200).json({
    success: true,
    message: 'Daftar stok berhasil diambil',
    data: stocks,
    stocks, // Interop with frontend prototype hook
  });
};

export const getStock = async (req: Request, res: Response): Promise<void> => {
  const stock = await stockService.getStockById(req.params.id as string, req.businessId!);
  sendSuccess(res, stock, 'Detail stok berhasil diambil');
};

export const createStock = async (req: Request, res: Response): Promise<void> => {
  const stock = await stockService.createStock(req.businessId!, req.body);
  res.status(201).json({
    success: true,
    message: 'Item stok berhasil ditambahkan',
    data: stock,
    stock,
  });
};

export const updateStock = async (req: Request, res: Response): Promise<void> => {
  const stock = await stockService.updateStock(req.params.id as string, req.businessId!, req.body);
  res.status(200).json({
    success: true,
    message: 'Item stok berhasil diperbarui',
    data: stock,
    stock,
  });
};

export const deleteStock = async (req: Request, res: Response): Promise<void> => {
  await stockService.deleteStock(req.params.id as string, req.businessId!);
  sendEmptySuccess(res, 'Item stok berhasil dihapus');
};

export const adjustStock = async (req: Request, res: Response): Promise<void> => {
  const result = await stockService.adjustStock(
    req.params.id as string,
    req.businessId!,
    req.body,
    req.user
  );
  res.status(200).json({
    success: true,
    message: 'Stok berhasil disesuaikan',
    data: result,
    stock: result.stock,
    log: result.log,
  });
};

export const restock = async (req: Request, res: Response): Promise<void> => {
  const stock = await stockService.restock(
    req.params.id as string,
    req.businessId!,
    req.body,
    req.user
  );
  res.status(200).json({
    success: true,
    message: 'Restock berhasil dicatat',
    data: stock,
    stock,
  });
};

export const getStockLogs = async (req: Request, res: Response): Promise<void> => {
  const logs = await stockService.getStockLogs(req.params.id as string, req.businessId!);
  sendSuccess(res, logs, 'Riwayat mutasi stok berhasil diambil');
};
