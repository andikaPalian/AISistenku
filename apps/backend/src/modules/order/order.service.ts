import * as orderRepo from './order.repository.js';
import { NotFoundError } from '@/errors/http.error.js';
import { CreateOrderDTO, ListOrdersQuery, RefundOrderDTO } from './order.validator.js';

export const createOrder = async (
  businessId: string,
  userId: string | null,
  input: CreateOrderDTO
) => {
  const normalizedItems = input.items.map((item) => ({
    productId: item.productId || item.product_id || '',
    quantity: item.quantity,
    variant: item.variant,
    note: item.note,
  }));

  return await orderRepo.createOrderAtomic(businessId, userId, {
    orderType: input.orderType,
    tableNumber: input.tableNumber,
    customerName: input.customerName,
    paymentMethod: input.paymentMethod,
    cashGiven: input.cashGiven,
    items: normalizedItems,
  });
};

export const listOrders = async (businessId: string, query: ListOrdersQuery) => {
  const page = query.page ?? 1;
  const limit = query.limit ?? 50;
  const offset = (page - 1) * limit;

  const fromDate = query.from ? new Date(query.from) : undefined;
  const toDate = query.to ? new Date(query.to) : undefined;

  const { orders, total } = await orderRepo.findOrdersByBusinessId(businessId, {
    from: fromDate,
    to: toDate,
    status: query.status,
    orderType: query.orderType,
    limit,
    offset,
  });

  return {
    orders,
    meta: {
      total,
      page,
      limit,
      hasNextPage: offset + orders.length < total,
    },
  };
};

export const getOrderById = async (id: string, businessId: string) => {
  const order = await orderRepo.findOrderById(id, businessId);
  if (!order) {
    throw new NotFoundError('Pesanan', 'ORDER_NOT_FOUND');
  }
  return order;
};

export const refundOrder = async (
  id: string,
  businessId: string,
  userId: string | null,
  input: RefundOrderDTO,
  operatorName?: string
) => {
  return await orderRepo.refundOrderAtomic(id, businessId, userId, {
    reason: input?.reason,
    targetStatus: input?.targetStatus,
    restoreStock: input?.restoreStock,
    operatorName,
  });
};
