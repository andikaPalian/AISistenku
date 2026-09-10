import { z } from 'zod';
import { BusinessRole } from '@prisma/client';

export const createBusinessSchema = z.object({
  body: z.object({
    name: z.string().trim().min(1, 'Nama bisnis wajib diisi').max(100),
    address: z.string().trim().max(255).optional(),
    phone: z.string().trim().max(30).optional(),
  }),
});

export const updateBusinessSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID bisnis tidak valid'),
  }),
  body: z.object({
    name: z.string().trim().min(1, 'Nama bisnis tidak boleh kosong').max(100).optional(),
    address: z.string().trim().max(255).optional().nullable(),
    phone: z.string().trim().max(30).optional().nullable(),
  }),
});

export const businessIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID bisnis tidak valid'),
  }),
});

export const addMemberSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID bisnis tidak valid'),
  }),
  body: z.object({
    email: z.string().trim().email('Email tidak valid').toLowerCase(),
    role: z.nativeEnum(BusinessRole, { message: 'Role harus OWNER atau CASHIER' }),
  }),
});

export const updateMemberRoleSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID bisnis tidak valid'),
    memberId: z.string().uuid('ID anggota tidak valid'),
  }),
  body: z.object({
    role: z.nativeEnum(BusinessRole, { message: 'Role harus OWNER atau CASHIER' }),
  }),
});

export const deleteMemberSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID bisnis tidak valid'),
    memberId: z.string().uuid('ID anggota tidak valid'),
  }),
});

export type CreateBusinessInput = z.infer<typeof createBusinessSchema>['body'];
export type UpdateBusinessInput = z.infer<typeof updateBusinessSchema>['body'];
export type AddMemberInput = z.infer<typeof addMemberSchema>['body'];
export type UpdateMemberRoleInput = z.infer<typeof updateMemberRoleSchema>['body'];
