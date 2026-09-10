import { z } from 'zod';

export const chatSchema = z.object({
  body: z
    .object({
      message: z.string().trim().min(1).optional(),
      text: z.string().trim().min(1).optional(),
    })
    .refine((data) => Boolean(data.message || data.text), {
      message: 'Pesan chat wajib diisi (field "message" atau "text")',
    }),
});

export const actionIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID aksi tidak valid'),
  }),
});

export const contentIdeasSchema = z.object({
  body: z.object({
    theme: z.string().trim().min(1, 'Tema promosi wajib diisi').max(200),
    tone: z.string().trim().max(50).optional(),
    platform: z.string().trim().max(50).optional(),
  }),
});

export type ChatDTO = z.infer<typeof chatSchema>['body'];
export type ContentIdeasDTO = z.infer<typeof contentIdeasSchema>['body'];
