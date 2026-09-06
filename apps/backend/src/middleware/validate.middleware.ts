import { ValidationError } from '@/errors/validation.error.js';
import { Request, Response, NextFunction, RequestHandler } from 'express';
import { ZodType, ZodError } from 'zod';

export const validate = (schema: ZodType): RequestHandler => {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    try {
      const parsed = (await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
        file: req.file,
        files: req.files,
      })) as { body?: unknown; query?: unknown; params?: unknown };

      req.validatedBody = parsed.body;
      req.validatedQuery = parsed.query;
      req.validatedParams = parsed.params;

      if (parsed.body !== undefined) req.body = parsed.body;

      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const formattedErrors = error.issues.map((err) => ({
          field: err.path.join('.'),
          message: err.message,
        }));
        next(new ValidationError(formattedErrors));
        return;
      }
      next(error);
    }
  };
};
