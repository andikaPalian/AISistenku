import { Request, Response } from 'express';
import * as authService from './auth.service.js';
import { LoginBody, RegisterBody } from './auth.validator.js';
import { sendCreated, sendEmptySuccess, sendSuccess } from '@/http/response.js';
import { clearAuthCookies, setAuthCookies } from '@/http/cookie.js';

export const register = async (
  req: Request<any, any, RegisterBody>,
  res: Response
): Promise<void> => {
  const user = await authService.register(req.body);
  sendCreated(res, user, 'User registered successfully');
};

export const login = async (req: Request<any, any, LoginBody>, res: Response): Promise<void> => {
  const { user, accessToken, refreshToken } = await authService.login(req.body);

  setAuthCookies(res, accessToken, refreshToken);
  sendSuccess(res, user, 'Login successful');
};

export const refreshToken = async (req: Request, res: Response): Promise<void> => {
  const oldRefreshToken = req.cookies.refreshToken;

  if (!oldRefreshToken) {
    res.status(401).json({
      success: false,
      message: 'Refresh token missing.',
    });
    return;
  }

  const { accessToken, refreshToken } = await authService.refreshSession(oldRefreshToken);

  setAuthCookies(res, accessToken, refreshToken);
  sendEmptySuccess(res, 'Session refreshed.');
};

export const logout = async (req: Request, res: Response): Promise<void> => {
  const { refreshToken } = req.cookies;
  if (refreshToken) await authService.logout(refreshToken);

  clearAuthCookies(res);
  sendEmptySuccess(res, 'Logout successful.');
};
