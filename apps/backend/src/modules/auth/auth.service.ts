import bcrypt from 'bcrypt';
import * as userRepository from '../user/user.repository.js';
import * as authRepository from './auth.repository.js';
import { LoginDTO, RegisterDTO } from './dto/auth.request.dto.js';
import {
  LoginResponseDTO,
  TokenResponseDTO,
} from './dto/auth.response.dto.js';
import { ConflictError, NotFoundError, UnauthorizedError } from '@/errors/http.error.js';
import { logger } from '@/utils/logger.js';
import { DuplicateEntryError } from '@/errors/persistence.error.js';
import {
  generateAccessToken,
  generateJti,
  generateRefreshToken,
  getRefreshTokenExpiry,
  RefreshTokenPayload,
  verifyToken,
} from '@/utils/jwt.util.js';
import { env } from '@/config/env.config.js';

const generateUserSession = async (userId: string, username: string): Promise<TokenResponseDTO> => {
  const jti = generateJti();
  const accessToken = generateAccessToken(userId, username);
  const refreshToken = generateRefreshToken(userId, jti);
  const expiresAt = getRefreshTokenExpiry();

  await authRepository.saveRefreshToken({ jti, userId, expiresAt });

  return { accessToken, refreshToken };
};

export const register = async (input: RegisterDTO): Promise<LoginResponseDTO> => {
  const userExists = await userRepository.findUserByEmail(input.email);
  if (userExists) throw new ConflictError('User already exists', 'email');

  const hashedPassword = await bcrypt.hash(input.password, 12);

  try {
    const newUser = await userRepository.createUser({
      name: input.name,
      email: input.email,
      password: hashedPassword,
      businessName: input.businessName,
      businessAddress: input.businessAddress,
      businessPhone: input.businessPhone,
    });

    const { password: _, ...safeUserData } = newUser;
    const { accessToken, refreshToken } = await generateUserSession(newUser.id, newUser.name);

    logger.info(`[AUTH SERVICE] New user registered with email: ${input.email}`);
    return {
      user: safeUserData,
      accessToken,
      refreshToken,
    };
  } catch (error) {
    if (error instanceof DuplicateEntryError) {
      throw new ConflictError('User already exists', 'email');
    }
    throw error;
  }
};

export const login = async (input: LoginDTO): Promise<LoginResponseDTO> => {
  const user = await userRepository.findUserByEmail(input.email);
  if (!user) throw new UnauthorizedError('Invalid Credentials', 'credentials');

  const isMatch = await bcrypt.compare(input.password, user.password);
  if (!isMatch) throw new UnauthorizedError('Invalid Credentials', 'credentials');

  const { accessToken, refreshToken } = await generateUserSession(user.id, user.name);

  const { password: _, ...safeUserData } = user;

  logger.info(`[AUTH SERVICE] User logged in: ${user.id}`);

  return {
    user: safeUserData,
    accessToken,
    refreshToken,
  };
};

export const refreshSession = async (oldRefreshToken: string): Promise<TokenResponseDTO> => {
  let decoded: RefreshTokenPayload;
  try {
    decoded = await verifyToken(oldRefreshToken, env.JWT_REFRESH_SECRET);
  } catch (error) {
    throw new UnauthorizedError('Invalid or expired refresh token please login again', 'token');
  }

  const userId = decoded.sub;
  const jti = decoded.jti;

  const tokenRecord = await authRepository.findRefreshToken(jti);
  if (!tokenRecord) {
    await authRepository.revokeAllSessionsForUser(userId);
    logger.warn(
      `[AUTH SERVICE] Token reuse detected for user ID: ${userId}. All sessions revoked.`
    );
    throw new UnauthorizedError('Security issue detected. Please login again', 'token');
  }

  const user = await userRepository.findUserById(userId);
  if (!user) {
    await authRepository.revokeAllSessionsForUser(userId);
    throw new UnauthorizedError('User no longer exists', 'token');
  }

  const newJti = generateJti();
  const newAccessToken = generateAccessToken(userId, user.name);
  const newRefreshToken = generateRefreshToken(userId, newJti);
  const newExpiresAt = getRefreshTokenExpiry();

  await authRepository.saveRefreshToken({
    jti: newJti,
    userId,
    expiresAt: newExpiresAt,
  });

  return {
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
  };
};

export const logout = async (refreshToken: string): Promise<void> => {
  try {
    const decoded = await verifyToken(refreshToken, env.JWT_REFRESH_SECRET);
    if (decoded && decoded.jti) {
      await authRepository.revokeRefreshToken(decoded.jti);
      logger.info('[AUTH SERVICE] Refresh token revoked successfully during logout.');
    }
  } catch (_error) {
    logger.warn('[AUTH SERVICE] Logout warning: Token not found or already missing');
  }
};

export const getMe = async (userId: string) => {
  const user = await userRepository.findUserById(userId);
  if (!user) {
    throw new NotFoundError('User', 'USER_NOT_FOUND');
  }
  const { password: _, ...safeUser } = user;
  return safeUser;
};

export const updateMe = async (userId: string, data: { name?: string; avatarUrl?: string | null }) => {
  const user = await userRepository.updateUser(userId, data);
  const { password: _, ...safeUser } = user;
  return safeUser;
};

