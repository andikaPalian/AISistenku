const BASE_URL =
  (import.meta.env.VITE_API_BASE_URL as string) ||
  (import.meta.env.VITE_API_URL as string) ||
  '/api';

export interface ApiError {
  error: string;
  status: number;
}

const TOKEN_KEY = 'ta_token';
const REFRESH_KEY = 'ta_refresh_token';
const BIZ_KEY = 'ta_business_id';

export function getToken(): string | null {
  try { return localStorage.getItem(TOKEN_KEY); } catch { return null; }
}

export function setToken(token: string | null): void {
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {}
}

export function getRefreshToken(): string | null {
  try { return localStorage.getItem(REFRESH_KEY); } catch { return null; }
}

export function setRefreshToken(token: string | null): void {
  try {
    if (token) localStorage.setItem(REFRESH_KEY, token);
    else localStorage.removeItem(REFRESH_KEY);
  } catch {}
}

export function getBusinessId(): string | null {
  try { return localStorage.getItem(BIZ_KEY); } catch { return null; }
}

export function setBusinessId(id: string | null): void {
  try {
    if (id) localStorage.setItem(BIZ_KEY, id);
    else localStorage.removeItem(BIZ_KEY);
  } catch {}
}

// Single-flight refresh token mutex
let refreshPromise: Promise<string | null> | null = null;

async function refreshAccessToken(): Promise<string | null> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return null;

  if (!refreshPromise) {
    refreshPromise = (async () => {
      try {
        const refreshTargetUrl = BASE_URL.endsWith('/')
          ? `${BASE_URL.slice(0, -1)}/auth/refresh`
          : `${BASE_URL}/auth/refresh`;

        const res = await fetch(refreshTargetUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ refreshToken }),
        });

        if (res.ok) {
          const data = await res.json();
          const newAccess =
            data?.accessToken ||
            data?.data?.accessToken ||
            data?.access_token;
          const newRefresh =
            data?.refreshToken ||
            data?.data?.refreshToken ||
            data?.refresh_token;

          if (newAccess) {
            setToken(newAccess);
            if (newRefresh) setRefreshToken(newRefresh);
            return newAccess;
          }
        }
        return null;
      } catch {
        return null;
      } finally {
        refreshPromise = null;
      }
    })();
  }

  return refreshPromise;
}

async function request<T>(method: string, path: string, body?: unknown, isRetry = false): Promise<T> {
  let token = getToken();
  const businessId = getBusinessId();
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (businessId) headers['x-business-id'] = businessId;

  // Normalize path
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  const targetUrl = BASE_URL.endsWith('/')
    ? `${BASE_URL.slice(0, -1)}${normalizedPath}`
    : `${BASE_URL}${normalizedPath}`;

  let res: Response;
  try {
    res = await fetch(targetUrl, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch (netErr: any) {
    // If relative /api failed, try direct localhost:3000 fallback
    if (BASE_URL === '/api') {
      try {
        res = await fetch(`http://localhost:3000/api${normalizedPath}`, {
          method,
          headers,
          body: body ? JSON.stringify(body) : undefined,
        });
      } catch {
        throw {
          error: `Koneksi backend gagal. Pastikan backend server aktif di http://localhost:3000 (Jalankan: npm run dev di folder apps/backend)`,
          status: 0,
        } as ApiError;
      }
    } else {
      throw {
        error: `Koneksi backend gagal. Pastikan backend server aktif di ${BASE_URL} (Jalankan: npm run dev di folder apps/backend)`,
        status: 0,
      } as ApiError;
    }
  }

  // Handle 401 Unauthorized with automatic silent token refresh
  if (res.status === 401 && !path.includes('/auth/login') && !path.includes('/auth/refresh') && !isRetry) {
    const freshToken = await refreshAccessToken();
    if (freshToken) {
      // Re-run original request with fresh access token
      return request<T>(method, path, body, true);
    }

    // Refresh failed or token was completely revoked: clear session cleanly
    setToken(null);
    setRefreshToken(null);
    try { localStorage.removeItem('ta_user'); } catch {}
    try { sessionStorage.removeItem('ta_session_entered'); } catch {}
    try { window.dispatchEvent(new Event('ta:auth-change')); } catch {}
    throw { error: 'Sesi Anda telah kedaluwarsa. Silakan masuk kembali.', status: 401 } as ApiError;
  }

  if (!res.ok) {
    let errMsg = `Permintaan gagal (${res.status})`;
    try {
      const data = await res.json();
      errMsg =
        data.message ||
        data.error?.message ||
        (typeof data.error === 'string' ? data.error : null) ||
        errMsg;
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
