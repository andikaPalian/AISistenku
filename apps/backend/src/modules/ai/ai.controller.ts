import { Request, Response } from 'express';
import * as aiService from './ai.service.js';
import { sendEmptySuccess, sendSuccess } from '@/http/response.js';

export const chat = async (req: Request, res: Response): Promise<void> => {
  const messageText = req.body.message || req.body.text;
  const result = await aiService.handleChat(
    req.businessId!,
    req.user?.id ?? null,
    messageText
  );

  res.status(200).json({
    success: true,
    data: {
      type: result.type,
      message: result.message,
      ...(result.action ? { action: result.action } : {}),
      userMessage: result.userMessage,
      aiResponse: result.aiResponse,
    },
    // Compatibility fields with existing frontend hook
    userMessage: result.userMessage,
    aiResponse: result.aiResponse,
    type: result.type,
    action: result.action,
    message: result.message,
  });
};

export const confirmAction = async (req: Request, res: Response): Promise<void> => {
  const result = await aiService.confirmAction(
    req.params.id as string,
    req.businessId!,
    req.user?.id ?? null
  );
  sendSuccess(res, result.action, result.message);
};

export const cancelAction = async (req: Request, res: Response): Promise<void> => {
  const result = await aiService.cancelAction(req.params.id as string, req.businessId!);
  sendSuccess(res, result.action, result.message);
};

export const getContentIdeas = async (req: Request, res: Response): Promise<void> => {
  const ideas = await aiService.generateContentIdeas(req.businessId!, req.body);
  sendSuccess(res, ideas, 'Ide konten promosi berhasil dihasilkan');
};

export const getMessages = async (req: Request, res: Response): Promise<void> => {
  const messages = await aiService.listMessages(req.businessId!);
  res.status(200).json({
    success: true,
    message: 'Riwayat pesan AI berhasil diambil',
    data: messages,
    messages, // Interop with frontend prototype hook
  });
};

export const clearMessages = async (req: Request, res: Response): Promise<void> => {
  await aiService.clearMessages(req.businessId!);
  sendEmptySuccess(res, 'Riwayat pesan berhasil dibersihkan');
};
