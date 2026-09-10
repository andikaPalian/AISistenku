import { Router } from 'express';
import * as marketingController from './marketing.controller.js';
import * as marketingValidator from './marketing.validator.js';
import { requireAuth } from '@/middleware/auth.middleware.js';
import { requireBusinessContext } from '@/middleware/business-context.middleware.js';
import { validate } from '@/middleware/validate.middleware.js';

export const marketingRouter = Router();

// Semua rute marketing-content wajib auth dan konteks tenant bisnis aktif
marketingRouter.use(requireAuth);
marketingRouter.use(requireBusinessContext);

marketingRouter.get(
  '/',
  validate(marketingValidator.listMarketingContentQuerySchema),
  marketingController.listContents
);

marketingRouter.get(
  '/:id',
  validate(marketingValidator.marketingContentIdParamSchema),
  marketingController.getContent
);

marketingRouter.post(
  '/',
  validate(marketingValidator.createMarketingContentSchema),
  marketingController.createContent
);

marketingRouter.patch(
  '/:id',
  validate(marketingValidator.updateMarketingContentSchema),
  marketingController.updateContent
);

marketingRouter.delete(
  '/:id',
  validate(marketingValidator.marketingContentIdParamSchema),
  marketingController.deleteContent
);
