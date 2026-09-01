import { Router } from 'express';
import {
  getFinanceSummary,
  getTransactions,
  createTransaction,
  deleteTransaction,
} from '../controllers/financeController.js';
import { authMiddleware } from '../middleware/auth.js';

const router = Router();

router.get('/summary', authMiddleware, getFinanceSummary);
router.get('/transactions', authMiddleware, getTransactions);
router.post('/transactions', authMiddleware, createTransaction);
router.delete('/transactions/:id', authMiddleware, deleteTransaction);

export default router;
