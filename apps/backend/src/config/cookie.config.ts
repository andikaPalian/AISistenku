import { CookieOptions } from 'express';
import { env } from './env.config.js';

export const COOKIE = {
  ACCESS_TOKEN_MS: 15 * 60 * 1000,
  REFRESH_TOKEN_MS: 7 * 24 * 60 * 60 * 1000,
} as const;

export const COOKIE_OPTIONS: CookieOptions = {
  httpOnly: true,
  secure: env.NODE_ENV === 'production',
  sameSite: env.NODE_ENV === 'production' ? 'none' : 'lax',
};

export const TOKEN_EXPIRY = {
  ACCESS_TOKEN_MS: COOKIE.ACCESS_TOKEN_MS,
  REFRESH_TOKEN_MS: COOKIE.REFRESH_TOKEN_MS,
} as const;
