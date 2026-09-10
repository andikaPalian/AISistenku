import { Request, Response } from 'express';
import * as marketingService from './marketing.service.js';
import { sendCreated, sendEmptySuccess, sendSuccess } from '@/http/response.js';
import { ListMarketingContentQuery } from './marketing.validator.js';

export const listContents = async (req: Request, res: Response): Promise<void> => {
  const query = req.query as unknown as ListMarketingContentQuery;
  const contents = await marketingService.listMarketingContents(req.businessId!, query);
  sendSuccess(res, contents, 'Daftar konten promosi berhasil diambil');
};

export const getContent = async (req: Request, res: Response): Promise<void> => {
  const content = await marketingService.getMarketingContentById(req.params.id as string, req.businessId!);
  sendSuccess(res, content, 'Detail konten promosi berhasil diambil');
};

export const createContent = async (req: Request, res: Response): Promise<void> => {
  const content = await marketingService.createMarketingContent(req.businessId!, req.body);
  sendCreated(res, content, 'Konten promosi berhasil disimpan');
};

export const updateContent = async (req: Request, res: Response): Promise<void> => {
  const content = await marketingService.updateMarketingContent(
    req.params.id as string,
    req.businessId!,
    req.body
  );
  sendSuccess(res, content, 'Konten promosi berhasil diperbarui');
};

export const deleteContent = async (req: Request, res: Response): Promise<void> => {
  await marketingService.deleteMarketingContent(req.params.id as string, req.businessId!);
  sendEmptySuccess(res, 'Konten promosi berhasil dihapus');
};
