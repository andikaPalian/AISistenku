import { Router } from 'express';
import * as orderController from './order.controller.js';
import * as orderValidator from './order.validator.js';
import { requireAuth } from '@/middleware/auth.middleware.js';
import { requireBusinessContext } from '@/middleware/business-context.middleware.js';
import { validate } from '@/middleware/validate.middleware.js';

export const orderRouter = Router();

// Semua rute pesanan wajib auth dan konteks tenant bisnis aktif
orderRouter.use(requireAuth);
orderRouter.use(requireBusinessContext);

orderRouter.post(
  '/',
  validate(orderValidator.createOrderSchema),
  orderController.createOrder
);

orderRouter.get(
  '/',
  validate(orderValidator.listOrdersQuerySchema),
  orderController.listOrders
);

orderRouter.get(
  '/:id',
  validate(orderValidator.orderIdParamSchema),
  orderController.getOrder
);

orderRouter.post(
  '/:id/refund',
  validate(orderValidator.refundOrderSchema),
  orderController.refundOrder
);
