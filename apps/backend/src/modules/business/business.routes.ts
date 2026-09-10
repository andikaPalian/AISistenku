import { Router } from 'express';
import * as businessController from './business.controller.js';
import * as businessValidator from './business.validator.js';
import { requireAuth } from '@/middleware/auth.middleware.js';
import { validate } from '@/middleware/validate.middleware.js';

export const businessRouter = Router();

// Semua rute bisnis memerlukan autentikasi
businessRouter.use(requireAuth);

// Business CRUD
businessRouter.get('/', businessController.listBusinesses);
businessRouter.post(
  '/',
  validate(businessValidator.createBusinessSchema),
  businessController.createBusiness
);
businessRouter.patch(
  '/:id',
  validate(businessValidator.updateBusinessSchema),
  businessController.updateBusiness
);

// Member management
businessRouter.get(
  '/:id/members',
  validate(businessValidator.businessIdParamSchema),
  businessController.listMembers
);
businessRouter.post(
  '/:id/members',
  validate(businessValidator.addMemberSchema),
  businessController.addMember
);
businessRouter.patch(
  '/:id/members/:memberId',
  validate(businessValidator.updateMemberRoleSchema),
  businessController.updateMemberRole
);
businessRouter.delete(
  '/:id/members/:memberId',
  validate(businessValidator.deleteMemberSchema),
  businessController.removeMember
);
