import { env } from '@/config/env.config.js';
import jwt, { JwtPayload, Secret, SignOptions } from 'jsonwebtoken';

export type BaseTokenPayload = JwtPayload;

export interface AccessTokenPayload extends BaseTokenPayload {
  sub: string;
  name: string;
}

export interface RefreshTokenPayload extends BaseTokenPayload {
  sub: string;
  jti: string;
}

interface AccessTokenResponse {
  userId: string;
  name: string;
}

const JWT_SECRET: Secret = env.JWT_SECRET;
const JWT_SECRET_REFRESH: Secret = env.JWT_REFRESH_SECRET;

export const generateAccessToken = (userId: string, name: string): string => {
  const options: SignOptions = {
    expiresIn: env.JWT_ACCESS_EXPIRES,
    subject: userId,
  };
  return jwt.sign({ name }, JWT_SECRET, options);
};

export const generateRefreshToken = (userId: string, jti: string): string => {
  const options: SignOptions = {
    expiresIn: env.JWT_REFRESH_EXPIRES,
    subject: userId,
    jwtid: jti,
  };
  return jwt.sign({}, JWT_SECRET_REFRESH, options);
};

export const verifyAccessToken = (
  token: string,
  secret: Secret = JWT_SECRET
): AccessTokenResponse => {
  const decoded = jwt.verify(token, secret) as AccessTokenPayload;
  return {
    userId: decoded.sub,
    name: decoded.name,
  };
};

export const verifyToken = <T extends BaseTokenPayload = AccessTokenPayload>(
  token: string,
  secret: Secret = JWT_SECRET
): Promise<T> => {
  return new Promise((resolve, reject) => {
    jwt.verify(token, secret, (err, decoded) => {
      if (err) return reject(err);
      if (!decoded) return reject(new Error('Unauthorized: Token payload is empty'));
      resolve(decoded as T);
    });
  });
};

export const verifyTokenIgnoreExpiration = (token: string, secret: Secret = JWT_SECRET_REFRESH) => {
  return new Promise((resolve, reject) => {
    jwt.verify(token, secret, { ignoreExpiration: true }, (err, decoded) => {
      if (err) return reject(err);
      if (!decoded) return reject(new Error('Unauthorized: Token payload is empty'));
      resolve(decoded as RefreshTokenPayload);
    });
  });
};

export const getRefreshTokenExpiry = (): Date => {
  const expiry = env.JWT_REFRESH_EXPIRES as string;
  const match = expiry.match(/^(\d+)(s|m|h|d)$/);
  if (!match) throw new Error(`Invalid JWT_REFRESH_EXPIRES format: ${expiry}`);

  const value = parseInt(match[1]);
  const unit = match[2];
  const multipliers = { s: 1000, m: 60_000, h: 3_600_000, d: 86_400_000 };
  return new Date(Date.now() + value * multipliers[unit as keyof typeof multipliers]);
};

export { JWT_SECRET, JWT_SECRET_REFRESH };
