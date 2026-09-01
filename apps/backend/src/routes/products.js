import { Router } from 'express';
import {
  getProducts,
  createProduct,
  updateProduct,
  deleteProduct,
} from '../controllers/productController.js';
import { authMiddleware } from '../middleware/auth.js';

const router = Router();

router.get('/', authMiddleware, getProducts);
router.post('/', authMiddleware, createProduct);
router.put('/:id', authMiddleware, updateProduct);
router.delete('/:id', authMiddleware, deleteProduct);

export default router;
