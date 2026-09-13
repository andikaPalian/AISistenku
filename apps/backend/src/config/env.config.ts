import 'dotenv/config';
import { z } from 'zod';
import { SignOptions } from 'jsonwebtoken';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  FRONTEND_ORIGIN: z.string().optional().default(process.env.FRONTEND_ORIGIN || 'http://localhost:5173'),

  // Database
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  // JWT
  JWT_SECRET: z.string().min(16, 'JWT_SECRET must be at least 16 characters long').default(process.env.JWT_ACCESS_SECRET || process.env.JWT_SECRET || 'default_jwt_access_secret_super_secret_key_32'),
  JWT_REFRESH_SECRET: z.string().min(16, 'JWT_REFRESH_SECRET must be at least 16 characters long').default(process.env.JWT_REFRESH_SECRET || 'default_jwt_refresh_secret_super_secret_key_32'),
  JWT_ACCESS_EXPIRES: z.string().default('7d') as z.ZodType<SignOptions['expiresIn']>,
  JWT_REFRESH_EXPIRES: z.string().default('30d') as z.ZodType<SignOptions['expiresIn']>,

  // AI Assistant (Gemini)
  GEMINI_API_KEY: z.string().optional().default(process.env.GEMINI_API_KEY || ''),
  KELONTONG_API_KEY: z.string().optional().default(process.env.KELONTONG_API_KEY || ''),
  KELONTONG_API_URL: z.string().optional().default(process.env.KELONTONG_API_URL || 'https://api.kelontongai.my.id/v1'),
  KELONTONG_MODEL: z.string().optional().default(process.env.KELONTONG_MODEL || 'mimo-v2.5'),

  // Cloudinary
  CLOUDINARY_CLOUD_NAMES: z.string().optional().default(process.env.CLOUDINARY_CLOUD_NAMES || process.env.CLOUDINARY_CLOUD_NAME || ''),
  CLOUDINARY_API_KEYS: z.string().optional().default(process.env.CLOUDINARY_API_KEYS || process.env.CLOUDINARY_API_KEY || ''),
  CLOUDINARY_API_SECRET: z.string().optional().default(process.env.CLOUDINARY_API_SECRET || ''),

  // Rate Limiting
  AUTH_LIMIT_WINDOW_MINS: z.coerce.number().positive().default(15),
  AUTH_LIMIT_MAX_ATTEMPTS: z.coerce.number().positive().default(30),
  EMAIL_LIMIT_WINDOW_MINS: z.coerce.number().positive().default(5),
  EMAIL_LIMIT_MAX_ATTEMPTS: z.coerce.number().positive().default(5),
  AI_LIMIT_WINDOW_MINS: z.coerce.number().positive().default(1),
  AI_LIMIT_MAX_ATTEMPTS: z.coerce.number().positive().default(30),
  GLOBAL_LIMIT_WINDOW_MINS: z.coerce.number().positive().default(1),
  GLOBAL_LIMIT_MAX_ATTEMPTS: z.coerce.number().positive().default(200),
});

const parseResult = envSchema.safeParse(process.env);
if (!parseResult.success) {
  console.error('Invalid environment configuration:');
  console.error(JSON.stringify(parseResult.error.format(), null, 2));
  process.exit(1);
}

export const env = parseResult.data;
export type Env = typeof env;
