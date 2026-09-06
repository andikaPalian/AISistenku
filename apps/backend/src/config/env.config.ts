import { z } from 'zod';
import { SignOptions } from 'jsonwebtoken';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),

  // Database
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  // JWT
  JWT_SECRET: z.string().min(16, 'JWT_SECRET must be at least 16 characters long'),
  JWT_REFRESH_SECRET: z.string().min(16, 'JWT_REFRESH_SECRET must be at least 16 characters long'),
  JWT_ACCESS_EXPIRES: z.string().default('15m') as z.ZodType<SignOptions['expiresIn']>,
  JWT_REFRESH_EXPIRES: z.string().default('7d') as z.ZodType<SignOptions['expiresIn']>,

  // Cloudinary
  CLOUDINARY_CLOUD_NAMES: z.string().min(1, 'CLOUDINARY_CLOUD_NAMES is required'),
  CLOUDINARY_API_KEYS: z.string().min(1, 'CLOUDINARY_API_KEYS is required'),
  CLOUDINARY_API_SECRET: z.string().min(1, 'CLOUDINARY_API_SECRET is required'),

  // Rate Limiting
  AUTH_LIMIT_WINDOW_MINS: z.coerce.number().positive().default(15),
  AUTH_LIMIT_MAX_ATTEMPTS: z.coerce.number().positive().default(10),
  EMAIL_LIMIT_WINDOW_MINS: z.coerce.number().positive().default(5),
  EMAIL_LIMIT_MAX_ATTEMPTS: z.coerce.number().positive().default(3),
  GLOBAL_LIMIT_WINDOW_MINS: z.coerce.number().positive().default(1),
  GLOBAL_LIMIT_MAX_ATTEMPTS: z.coerce.number().positive().default(100),
});

const parseResult = envSchema.safeParse(process.env);
if (!parseResult.success) {
  console.error('Invalid environment configuration:');
  console.error(JSON.stringify(parseResult.error.format(), null, 2));
  process.exit(1);
}

export const env = parseResult.data;
export type Env = typeof env;
