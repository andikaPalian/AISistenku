import { z } from 'zod';

const NAME_REGEX = /^[a-zA-Z0-9\s'.-]+$/;
const PHONE_REGEX = /^(\+62|62|0)[0-9]{8,15}$/;

export const registerSchema = z.object({
  body: z.object({
    name: z
      .string()
      .trim()
      .min(2, 'Name must be at least 2 characters')
      .max(60, 'Name too long')
      .regex(NAME_REGEX, 'Name contains invalid characters'),
    email: z.string().trim().email('Invalid email').toLowerCase(),
    password: z
      .string()
      .trim()
      .min(6, 'Password must be at least 6 characters long'),
    businessName: z
      .string()
      .trim()
      .min(1, 'Business name is required')
      .max(60, 'Business name too long')
      .optional(),
    businessAddress: z
      .string()
      .trim()
      .max(150, 'Business address too long')
      .optional(),
    businessPhone: z
      .string()
      .regex(PHONE_REGEX, 'Invalid phone number format')
      .optional(),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().trim().email('Invalid email').toLowerCase(),
    password: z.string().min(1, 'Password is required'),
  }),
});

export const logoutSchema = z.object({
  body: z
    .object({
      refreshToken: z.string().trim().min(1).optional(),
    })
    .optional(),
  cookies: z
    .object({
      refreshToken: z.string().trim().min(1).optional(),
    })
    .optional(),
});

export const refreshTokenSchema = z.object({
  body: z
    .object({
      refreshToken: z.string().trim().min(1).optional(),
    })
    .optional(),
  cookies: z
    .object({
      refreshToken: z.string().trim().min(1).optional(),
    })
    .optional(),
});

export type RegisterBody = z.infer<typeof registerSchema>['body'];
export type LoginBody = z.infer<typeof loginSchema>['body'];

