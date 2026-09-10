import { AppError } from '@/errors/base.error.js';
import {
  DatabaseError,
  DuplicateEntryError,
  RecordNotFoundError,
  RelatedRecordNotFoundError,
} from '@/errors/persistence.error.js';
import { Prisma } from '@prisma/client';

export function mapPrismaError(error: unknown, entityName = 'Data'): Error {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    switch (error.code) {
      case 'P2002': {
        const field = (error.meta?.target as string[] | undefined)?.join(', ') ?? entityName;
        return new DuplicateEntryError(field);
      }
      case 'P2025':
        return new RecordNotFoundError(entityName);
      case 'P2003':
      case 'P2014':
        return new RelatedRecordNotFoundError(entityName);
      default:
        return new DatabaseError(`Unhandled Prisma error on ${entityName}`, error.code);
    }
  }
  if (error instanceof Prisma.PrismaClientValidationError) {
    return new DatabaseError(`Invalid data shape for ${entityName}`, undefined);
  }

  if (error instanceof Prisma.PrismaClientValidationError) {
    return new DatabaseError(`Invalid data shape for ${entityName}`);
  }

  return error instanceof Error ? error : new Error('An unknown error occurred');
}

export function withPrismaErrorHandling<Args extends unknown[], Return>(
  fn: (...args: Args) => Promise<Return>,
  entityName?: string
) {
  return async (...args: Args): Promise<Return> => {
    try {
      return await fn(...args);
    } catch (error) {
      if (error instanceof AppError) throw error;
      throw mapPrismaError(error, entityName);
    }
  };
}
