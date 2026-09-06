import { z } from 'zod';

const PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
const NAME_REGEX = /^[a-zA-Z]+$/;
const PHONE_REGEX = /^(\+62|62|0)[0-9]{9,12}$/;

export const registerSchema = z.object({
  body: z.object({
    name: z
      .string()
      .trim()
      .min(1, 'Name is required')
      .max(50, 'Name too long')
      .regex(NAME_REGEX, 'Name must only contain letters'),
    email: z.string().trim().email('Invalid email').toLowerCase(),
    password: z
      .string()
      .trim()
      .regex(
        PASSWORD_REGEX,
        'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character'
      ),
    businessName: z
      .string()
      .trim()
      .min(1, 'Business name is required')
      .max(50, 'Business name too long'),
    businessAddress: z
      .string()
      .trim()
      .min(1, 'Business address is required')
      .max(100, 'Business address too long'),
    businessPhone: z.coerce.string().regex(PHONE_REGEX, 'Invalid phone number'),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().trim().email('Invalid email').toLowerCase(),
    password: z
      .string()
      .trim()
      .regex(
        PASSWORD_REGEX,
        'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character'
      ),
  }),
});

export const logoutSchema = z.object({
  cookies: z.object({
    refreshToken: z.string().trim().min(1, 'Refresh Token is not found in cookies'),
  }),
});

export const refreshTokenSchema = z.object({
  cookies: z.object({
    refreshToken: z.string().trim().min(1, 'Refresh Token is not found in cookies'),
  }),
});

export type RegisterBody = z.infer<typeof registerSchema>['body'];
export type LoginBody = z.infer<typeof loginSchema>['body'];
