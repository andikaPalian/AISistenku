import { FormattedFieldError } from '@/errors/validation.error.js';

export interface ApiErrorDetail {
  code: string;
  message: string;
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
  error?: ApiErrorDetail;
  errors?: FormattedFieldError[];
  meta?: PaginationMeta;
}

export interface PaginationMeta {
  nextCursor?: string | null;
  hasNextPage?: boolean;
  total?: number;
  page?: number;
  limit?: number;
}

export interface PaginatedResult<T> {
  data: T[];
  meta: PaginationMeta;
}

export interface AuthenticatedUser {
  id: string;
  name: string;
  email?: string;
}
