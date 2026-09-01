import { Router } from 'express';
import {
  getStocks,
  getStockSummary,
  getStockLogs,
  createStock,
  updateStock,
  deleteStock,
  restockItem,
  adjustStock,
} from '../controllers/stockController.js';
import { authMiddleware } from '../middleware/auth.js';

const router = Router();

router.get('/', authMiddleware, getStocks);
router.get('/summary', authMiddleware, getStockSummary);
router.get('/:id/logs', authMiddleware, getStockLogs);
router.post('/', authMiddleware, createStock);
router.put('/:id', authMiddleware, updateStock);
router.delete('/:id', authMiddleware, deleteStock);
router.post('/:id/restock', authMiddleware, restockItem);
router.post('/:id/adjust', authMiddleware, adjustStock);

export default router;
