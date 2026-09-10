import { Request, Response } from 'express';
import * as financeService from './finance.service.js';
import { sendCreated, sendEmptySuccess } from '@/http/response.js';
import { ListFinanceQuery } from './finance.validator.js';

export const listTransactions = async (req: Request, res: Response): Promise<void> => {
  const query = req.query as unknown as ListFinanceQuery;
  const result = await financeService.listTransactions(req.businessId!, query);

  res.status(200).json({
    success: true,
    message: 'Daftar transaksi keuangan berhasil diambil',
    data: result.transactions,
    transactions: result.transactions,
    meta: result.meta,
  });
};

export const createTransaction = async (req: Request, res: Response): Promise<void> => {
  const tx = await financeService.createTransaction(
    req.businessId!,
    req.user?.id ?? null,
    req.body
  );
  sendCreated(res, tx, 'Transaksi keuangan berhasil dicatat');
};

export const deleteTransaction = async (req: Request, res: Response): Promise<void> => {
  await financeService.deleteTransaction(req.params.id as string, req.businessId!);
  sendEmptySuccess(res, 'Transaksi keuangan berhasil dihapus');
};
