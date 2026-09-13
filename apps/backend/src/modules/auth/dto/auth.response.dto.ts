import { BusinessRole } from '@prisma/client';

export interface TokenResponseDTO {
  accessToken: string;
  refreshToken: string;
}

interface Membership {
  id: string;
  role: BusinessRole;
  business: {
    id: string;
    name: string | null;
    address: string | null;
    phone: string | null;
  };
}

export interface AuthenticatedUserResponseDTO {
  id: string;
  name: string;
  email: string;
  avatarUrl?: string | null;
  memberships: Membership[];
}

export interface LoginResponseDTO {
  user: AuthenticatedUserResponseDTO;
  accessToken: string;
  refreshToken: string;
}
