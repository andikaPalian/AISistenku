import { Request, Response } from 'express';
import * as businessService from './business.service.js';
import { sendCreated, sendEmptySuccess, sendSuccess } from '@/http/response.js';
import { UnauthorizedError } from '@/errors/http.error.js';

export const listBusinesses = async (req: Request, res: Response): Promise<void> => {
  if (!req.user) throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
  const businesses = await businessService.listUserBusinesses(req.user.id);
  sendSuccess(res, businesses, 'Daftar bisnis berhasil diambil');
};

export const createBusiness = async (req: Request, res: Response): Promise<void> => {
  if (!req.user) throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
  const business = await businessService.createBusiness(req.body, req.user.id);
  sendCreated(res, business, 'Bisnis berhasil dibuat');
};

export const updateBusiness = async (req: Request, res: Response): Promise<void> => {
  if (!req.user) throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
  const business = await businessService.updateBusiness(req.params.id as string, req.body, req.user.id);
  sendSuccess(res, business, 'Data bisnis berhasil diperbarui');
};

export const listMembers = async (req: Request, res: Response): Promise<void> => {
  if (!req.user) throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
  const members = await businessService.listBusinessMembers(req.params.id as string, req.user.id);
  sendSuccess(res, members, 'Daftar anggota berhasil diambil');
};

export const addMember = async (req: Request, res: Response): Promise<void> => {
  if (!req.user) throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
  const member = await businessService.addBusinessMember(req.params.id as string, req.body, req.user.id);
  sendCreated(res, member, 'Anggota baru berhasil ditambahkan');
};

export const updateMemberRole = async (req: Request, res: Response): Promise<void> => {
  if (!req.user) throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
  const member = await businessService.updateBusinessMemberRole(
    req.params.id as string,
    req.params.memberId as string,
    req.body.role,
    req.user.id
  );
  sendSuccess(res, member, 'Peran anggota berhasil diperbarui');
};

export const removeMember = async (req: Request, res: Response): Promise<void> => {
  if (!req.user) throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
  await businessService.removeBusinessMember(req.params.id as string, req.params.memberId as string, req.user.id);
  sendEmptySuccess(res, 'Anggota berhasil dikeluarkan dari bisnis');
};
