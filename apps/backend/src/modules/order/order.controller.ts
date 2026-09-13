import { Request, Response } from 'express';
import * as orderService from './order.service.js';
import { sendSuccess } from '@/http/response.js';
import { ListOrdersQuery } from './order.validator.js';

export const createOrder = async (req: Request, res: Response): Promise<void> => {
  const order = await orderService.createOrder(
    req.businessId!,
    req.user?.id ?? null,
    req.body
  );

  const normalizedOrder = {
    ...order,
    order_id: order.id,
    order_code: order.orderCode,
    total_amount: order.totalAmount,
  };

  res.status(201).json({
    success: true,
    message: 'Transaksi pesanan berhasil dicatat',
    data: order,
    order: normalizedOrder,
    items: order.items,
  });
};

export const listOrders = async (req: Request, res: Response): Promise<void> => {
  const query = req.query as unknown as ListOrdersQuery;
  const result = await orderService.listOrders(req.businessId!, query);

  res.status(200).json({
    success: true,
    message: 'Daftar transaksi berhasil diambil',
    data: result.orders,
    orders: result.orders,
    meta: result.meta,
  });
};

export const getOrder = async (req: Request, res: Response): Promise<void> => {
  const order = await orderService.getOrderById(req.params.id as string, req.businessId!);
  sendSuccess(res, order, 'Detail transaksi berhasil diambil');
};

export const refundOrder = async (req: Request, res: Response): Promise<void> => {
  const result = await orderService.refundOrder(
    req.params.id as string,
    req.businessId!,
    req.user?.id ?? null,
    req.body,
    req.user?.name
  );

  sendSuccess(
    res,
    result,
    `Pesanan ${result.order.orderCode} berhasil dibatalkan/direfund, stok resep dikembalikan, dan jurnal balik dicatat.`
  );
};
