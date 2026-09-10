import { Router } from 'express';
import * as productController from './product.controller.js';
import * as productValidator from './product.validator.js';
import { requireAuth } from '@/middleware/auth.middleware.js';
import { requireBusinessContext } from '@/middleware/business-context.middleware.js';
import { requireOwner } from '@/middleware/role.middleware.js';
import { validate } from '@/middleware/validate.middleware.js';

export const productRouter = Router();

// Semua rute produk wajib auth dan konteks tenant bisnis aktif
productRouter.use(requireAuth);
productRouter.use(requireBusinessContext);

productRouter.get(
  '/',
  validate(productValidator.listProductQuerySchema),
  productController.listProducts
);

productRouter.get(
  '/:id',
  validate(productValidator.productIdParamSchema),
  productController.getProduct
);

productRouter.post(
  '/',
  validate(productValidator.createProductSchema),
  productController.createProduct
);

productRouter.patch(
  '/:id',
  validate(productValidator.updateProductSchema),
  productController.updateProduct
);

productRouter.delete(
  '/:id',
  requireOwner,
  validate(productValidator.productIdParamSchema),
  productController.deleteProduct
);

productRouter.get(
  '/:id/recipe',
  validate(productValidator.productIdParamSchema),
  productController.getRecipe
);

productRouter.put(
  '/:id/recipe',
  requireOwner,
  validate(productValidator.replaceRecipeSchema),
  productController.setRecipe
);
