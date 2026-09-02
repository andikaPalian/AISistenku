import { apiPost, apiGet, setToken, getToken } from './api';

export interface AuthUser {
  id: string;
  email: string;
  name: string;
  role: string;
}

export interface LoginResponse {
  access_token?: string | null;
  refresh_token?: string | null;
  user: AuthUser;
  message?: string;
}

const USER_KEY = 'ta_user';

export async function login(email: string, password: string): Promise<AuthUser> {
  const data = await apiPost<LoginResponse>('/auth/login', { email, password });
  if (!data.access_token) {
    throw { error: 'Login gagal: token tidak diterima', status: 401 };
  }
  setToken(data.access_token);
  localStorage.setItem(USER_KEY, JSON.stringify(data.user));
  try { window.dispatchEvent(new Event('ta:auth-change')); } catch {}
  return data.user;
}

export async function register(email: string, password: string, name: string): Promise<AuthUser | null> {
  const data = await apiPost<LoginResponse>('/auth/register', { email, password, name });
  if (data.access_token) {
    setToken(data.access_token);
    localStorage.setItem(USER_KEY, JSON.stringify(data.user));
    try { window.dispatchEvent(new Event('ta:auth-change')); } catch {}
    return data.user;
  }
  // Email confirmation required — surface the server message
  throw { error: data.message || 'Registrasi berhasil. Cek email untuk konfirmasi, lalu login.', status: 200 };
}

export function logout(): void {
  setToken(null);
  try { localStorage.removeItem(USER_KEY); } catch {}
  try { window.dispatchEvent(new Event('ta:auth-change')); } catch {}
}

export function getStoredUser(): AuthUser | null {
  try {
    const raw = localStorage.getItem(USER_KEY);
    return raw ? (JSON.parse(raw) as AuthUser) : null;
  } catch { return null; }
}

export function isAuthenticated(): boolean {
  return !!getToken();
}

export async function fetchMe(): Promise<AuthUser | null> {
  try {
    const data = await apiGet<{ user: AuthUser }>('/auth/me');
    localStorage.setItem(USER_KEY, JSON.stringify(data.user));
    return data.user;
  } catch {
    return null;
  }
}
