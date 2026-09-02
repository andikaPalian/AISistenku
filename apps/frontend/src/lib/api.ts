const BASE_URL =
  (import.meta.env.VITE_API_BASE_URL as string) ||
  (import.meta.env.VITE_API_URL as string) ||
  'http://localhost:3000/api';

export interface ApiError {
  error: string;
  status: number;
}

const TOKEN_KEY = 'ta_token';

export function getToken(): string | null {
  try { return localStorage.getItem(TOKEN_KEY); } catch { return null; }
}

export function setToken(token: string | null): void {
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {}
}

async function request<T>(method: string, path: string, body?: unknown): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;

  let res: Response;
  try {
    res = await fetch(`${BASE_URL}${path}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch (netErr: any) {
    throw {
      error: `Koneksi backend gagal. Pastikan backend server aktif di ${BASE_URL} (Jalankan: npm run dev di folder apps/backend)`,
      status: 0,
    } as ApiError;
  }

  if (res.status === 401) {
    setToken(null);
    try { localStorage.removeItem('ta_user'); } catch {}
    if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
      window.location.href = '/login';
    }
    throw { error: 'Unauthorized', status: 401 } as ApiError;
  }

  if (!res.ok) {
    let errMsg = `Request failed (${res.status})`;
    try {
      const data = await res.json();
      errMsg = data.error || errMsg;
    } catch {}
    throw { error: errMsg, status: res.status } as ApiError;
  }

  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export const apiGet = <T>(path: string) => request<T>('GET', path);
export const apiPost = <T>(path: string, body?: unknown) => request<T>('POST', path, body);
export const apiPut = <T>(path: string, body?: unknown) => request<T>('PUT', path, body);
export const apiDelete = <T>(path: string) => request<T>('DELETE', path);

export const API_BASE_URL = BASE_URL;
