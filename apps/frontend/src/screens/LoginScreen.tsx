import React, { useState } from 'react';
import { login, register } from '../lib/auth';
import { Coffee, LogIn, UserPlus, AlertCircle } from 'lucide-react';
import './LoginScreen.css';

export const LoginScreen: React.FC = () => {
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      if (mode === 'login') {
        await login(email, password);
        window.location.reload();
      } else {
        const result = await register(email, password, name);
        if (result) {
          // User created with session — go straight in
          window.location.reload();
        }
      }
    } catch (err: any) {
      const msg = err?.error || err?.message || 'Gagal masuk. Periksa email & password Anda.';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-screen">
      <div className="login-card">
        <div className="login-brand">
          <div className="brand-icon"><Coffee size={28} /></div>
          <div>
            <h1 className="brand-title">Tiga Angkatan</h1>
            <p className="brand-sub">Sistem Manajemen Toko</p>
          </div>
        </div>

        <div className="login-tabs">
          <button
            type="button"
            onClick={() => setMode('login')}
            className={`login-tab ${mode === 'login' ? 'active' : ''}`}
          >
            <LogIn size={14} /> Masuk
          </button>
          <button
            type="button"
            onClick={() => setMode('register')}
            className={`login-tab ${mode === 'register' ? 'active' : ''}`}
          >
            <UserPlus size={14} /> Daftar
          </button>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          {mode === 'register' && (
            <div className="form-group">
              <label>Nama</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Nama pemilik toko"
                required
              />
            </div>
          )}

          <div className="form-group">
            <label>Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="email@contoh.com"
              required
            />
          </div>

          <div className="form-group">
            <label>Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              minLength={6}
            />
          </div>

          {error && (
            <div className="login-error">
              <AlertCircle size={14} /> {error}
            </div>
          )}

          <button type="submit" disabled={loading} className="btn-primary login-submit">
            {loading ? 'Memproses...' : mode === 'login' ? 'Masuk Dashboard' : 'Daftar Sekarang'}
          </button>
        </form>

        <p className="login-hint">
          {mode === 'login' ? 'Belum punya akun? ' : 'Sudah punya akun? '}
          <button type="button" onClick={() => setMode(mode === 'login' ? 'register' : 'login')} className="link-btn">
            {mode === 'login' ? 'Daftar di sini' : 'Masuk di sini'}
          </button>
        </p>
      </div>
    </div>
  );
};

export default LoginScreen;
