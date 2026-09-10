import { AppError } from './base.error.js';

export abstract class DomainError extends AppError {
  public abstract override readonly statusCode: number;
  public override readonly code: string;

  constructor(message: string, code: string) {
    super(message);
    this.code = code;
  }
}

export class DuplicateEntryError extends DomainError {
  public override readonly statusCode = 409;
  constructor(public readonly field: string) {
    super(`Duplicate entry for ${field}`, 'DUPLICATE_ENTRY');
  }
}

export class RecordNotFoundError extends DomainError {
  public override readonly statusCode = 404;
  constructor(public readonly entityName: string) {
    super(`${entityName} not found`, 'RECORD_NOT_FOUND');
  }
}

export class RelatedRecordNotFoundError extends DomainError {
  public override readonly statusCode = 404;
  constructor(public readonly entityName: string) {
    super(`Related record ${entityName} not found`, 'RELATED_RECORD_NOT_FOUND');
  }
}

export class DatabaseError extends DomainError {
  public override readonly statusCode = 500;
  constructor(
    message: string,
    public readonly originalCode?: string
  ) {
    super(message, 'DATABASE_ERROR');
  }
}
