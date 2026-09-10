import { Router } from 'express';
import * as stockController from './stock.controller.js';
import * as stockValidator from './stock.validator.js';
import { requireAuth } from '@/middleware/auth.middleware.js';
import { requireBusinessContext } from '@/middleware/business-context.middleware.js';
import { requireOwner } from '@/middleware/role.middleware.js';
import { validate } from '@/middleware/validate.middleware.js';

export const stockRouter = Router();

// Semua rute stok wajib auth dan konteks tenant bisnis aktif
stockRouter.use(requireAuth);
stockRouter.use(requireBusinessContext);

stockRouter.get(
  '/',
  validate(stockValidator.listStockQuerySchema),
  stockController.listStocks
);

stockRouter.get(
  '/:id',
  validate(stockValidator.stockIdParamSchema),
  stockController.getStock
);

stockRouter.post(
  '/',
  validate(stockValidator.createStockSchema),
  stockController.createStock
);

stockRouter.patch(
  '/:id',
  validate(stockValidator.updateStockSchema),
  stockController.updateStock
);

stockRouter.put(
  '/:id',
  validate(stockValidator.updateStockSchema),
  stockController.updateStock
);

stockRouter.delete(
  '/:id',
  requireOwner,
  validate(stockValidator.stockIdParamSchema),
  stockController.deleteStock
);

stockRouter.post(
  '/:id/adjust',
  validate(stockValidator.adjustStockSchema),
  stockController.adjustStock
);

stockRouter.post(
  '/:id/restock',
  validate(stockValidator.restockSchema),
  stockController.restock
);

stockRouter.get(
  '/:id/logs',
  validate(stockValidator.stockIdParamSchema),
  stockController.getStockLogs
);
