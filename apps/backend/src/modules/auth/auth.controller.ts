import { Request, Response } from 'express';
import * as authService from './auth.service.js';
import { LoginBody, RegisterBody } from './auth.validator.js';
import { sendCreated, sendEmptySuccess, sendSuccess } from '@/http/response.js';
import { clearAuthCookies, setAuthCookies } from '@/http/cookie.js';
import { UnauthorizedError } from '@/errors/http.error.js';

export const register = async (
  req: Request<any, any, RegisterBody>,
  res: Response
): Promise<void> => {
  const result = await authService.register(req.body);
  setAuthCookies(res, result.accessToken, result.refreshToken);
  sendCreated(res, result, 'User registered successfully');
};

export const login = async (req: Request<any, any, LoginBody>, res: Response): Promise<void> => {
  const { user, accessToken, refreshToken } = await authService.login(req.body);

  setAuthCookies(res, accessToken, refreshToken);
  sendSuccess(
    res,
    {
      accessToken,
      refreshToken,
      user,
    },
    'Login successful'
  );
};

export const refreshToken = async (req: Request, res: Response): Promise<void> => {
  const token = req.body?.refreshToken || req.cookies?.refreshToken;

  if (!token) {
    throw new UnauthorizedError('Refresh token missing.', 'REFRESH_TOKEN_REQUIRED');
  }

  const { accessToken, refreshToken } = await authService.refreshSession(token);

  setAuthCookies(res, accessToken, refreshToken);
  sendSuccess(res, { accessToken, refreshToken }, 'Session refreshed.');
};

export const logout = async (req: Request, res: Response): Promise<void> => {
  const token = req.body?.refreshToken || req.cookies?.refreshToken;
  if (token) await authService.logout(token);

  clearAuthCookies(res);
  sendEmptySuccess(res, 'Logout successful.');
};

export const getMe = async (req: Request, res: Response): Promise<void> => {
  if (!req.user) {
    throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
  }
  const user = await authService.getMe(req.user.id);
  sendSuccess(res, user, 'User profile retrieved');
};

export const updateMe = async (req: Request, res: Response): Promise<void> => {
  if (!req.user) {
    throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
  }
  const user = await authService.updateMe(req.user.id, req.body);
  sendSuccess(res, user, 'User profile updated successfully');
};


