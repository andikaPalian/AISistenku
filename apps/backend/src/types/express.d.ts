import { AuthenticatedUser } from './common.types.js';
import { BusinessRole } from '@prisma/client';

declare global {
  namespace Express {
    interface User extends AuthenticatedUser {}
    interface Request {
      user?: User;
      businessId?: string;
      role?: BusinessRole;
      validatedBody?: unknown;
      validatedQuery?: unknown;
      validatedParams?: unknown;
    }
  }
}
