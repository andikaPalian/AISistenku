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
});

const parseResult = envSchema.safeParse(process.env);
if (!parseResult.success) {
  console.error('❌ Invalid environment configuration:');
  console.error(JSON.stringify(parseResult.error.format(), null, 2));
  process.exit(1);
}

export const env = parseResult.data;
export type Env = typeof env;
