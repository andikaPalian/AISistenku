import { Router } from 'express';
import * as financeController from './finance.controller.js';
import * as financeValidator from './finance.validator.js';
import { requireAuth } from '@/middleware/auth.middleware.js';
import { requireBusinessContext } from '@/middleware/business-context.middleware.js';
import { requireOwner } from '@/middleware/role.middleware.js';
import { validate } from '@/middleware/validate.middleware.js';

export const financeRouter = Router();

// Semua rute keuangan wajib auth dan konteks tenant bisnis aktif
financeRouter.use(requireAuth);
financeRouter.use(requireBusinessContext);

// Primary endpoints according to API-CONTRACT.md
financeRouter.get(
  '/',
  validate(financeValidator.listFinanceQuerySchema),
  financeController.listTransactions
);

financeRouter.post(
  '/',
  validate(financeValidator.createFinanceSchema),
  financeController.createTransaction
);

financeRouter.delete(
  '/:id',
  requireOwner,
  validate(financeValidator.financeIdParamSchema),
  financeController.deleteTransaction
);

// Alias endpoints for compatibility (/finance/transactions)
financeRouter.get(
  '/transactions',
  validate(financeValidator.listFinanceQuerySchema),
  financeController.listTransactions
);

financeRouter.post(
  '/transactions',
  validate(financeValidator.createFinanceSchema),
  financeController.createTransaction
);

financeRouter.delete(
  '/transactions/:id',
  requireOwner,
  validate(financeValidator.financeIdParamSchema),
  financeController.deleteTransaction
);
