import { apiPost, apiGet, setToken, getToken, setBusinessId, setRefreshToken } from './api';

export interface Membership {
  id: string;
  role: string;
  business?: {
    id: string;
    name: string;
    address?: string;
    phone?: string;
  };
}

export interface AuthUser {
  id: string;
  email: string;
  name: string;
  role: string;
  avatarUrl?: string;
  businessName?: string;
  memberships?: Membership[];
}

const USER_KEY = 'ta_user';

function extractUserFromResponse(res: any, fallbackEmail?: string, fallbackName?: string): AuthUser {
  const rawUser = res?.data?.user || res?.user || {};
  const memberships: Membership[] = rawUser?.memberships || [];
  const primaryMembership = memberships[0];
  const role = primaryMembership?.role || rawUser?.role || 'OWNER';
  const businessName = primaryMembership?.business?.name || 'Kedai Kopi Tiga Angkatan';

  // Save active business ID for headers
  const bizId = primaryMembership?.business?.id;
  if (bizId) {
    setBusinessId(bizId);
  }

  return {
    id: rawUser.id || '',
    email: rawUser.email || fallbackEmail || '',
    name: rawUser.name || fallbackName || 'Pengguna',
    role,
    avatarUrl: rawUser.avatarUrl,
    businessName,
    memberships,
  };
}

export async function login(email: string, password: string): Promise<AuthUser> {
  const res = await apiPost<any>('/auth/login', { email, password });

  const token =
    res?.access_token ||
    res?.accessToken ||
    res?.data?.accessToken ||
    res?.data?.access_token;

  const refreshToken =
    res?.refresh_token ||
    res?.refreshToken ||
    res?.data?.refreshToken ||
    res?.data?.refresh_token;

  if (!token) {
    throw {
      error: res?.message || 'Login gagal: token tidak diterima dari backend',
      status: 401,
    };
  }

  setToken(token);
  if (refreshToken) {
    setRefreshToken(refreshToken);
  }

  const user = extractUserFromResponse(res, email);
  localStorage.setItem(USER_KEY, JSON.stringify(user));

  try {
    window.dispatchEvent(new Event('ta:auth-change'));
  } catch {}
  return user;
}

export async function register(
  email: string,
  password: string,
  name: string
): Promise<AuthUser | null> {
  const res = await apiPost<any>('/auth/register', { email, password, name });

  const token =
    res?.access_token ||
    res?.accessToken ||
    res?.data?.accessToken ||
    res?.data?.access_token;

  const refreshToken =
    res?.refresh_token ||
    res?.refreshToken ||
    res?.data?.refreshToken ||
    res?.data?.refresh_token;

  if (token) {
    setToken(token);
    if (refreshToken) {
      setRefreshToken(refreshToken);
    }
    const user = extractUserFromResponse(res, email, name);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    try {
      window.dispatchEvent(new Event('ta:auth-change'));
    } catch {}
    return user;
  }

  throw {
    error: res?.message || 'Registrasi berhasil. Cek email untuk konfirmasi, lalu login.',
    status: 200,
  };
}

export function logout(): void {
  setToken(null);
  setRefreshToken(null);
  setBusinessId(null);
  try { localStorage.removeItem(USER_KEY); } catch {}
  try { sessionStorage.removeItem('ta_session_entered'); } catch {}
  try { window.dispatchEvent(new Event('ta:auth-change')); } catch {}
}

export function getStoredUser(): AuthUser | null {
  try {
    const raw = localStorage.getItem(USER_KEY);
    return raw ? (JSON.parse(raw) as AuthUser) : null;
  } catch {
    return null;
  }
}

export function isAuthenticated(): boolean {
  return !!getToken();
}

export async function fetchMe(): Promise<AuthUser | null> {
  try {
    const res = await apiGet<any>('/auth/me');
    const rawUser = res?.data?.user || res?.user;
    if (!rawUser) return null;

    const user = extractUserFromResponse(res);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    return user;
  } catch {
    return null;
  }
}
