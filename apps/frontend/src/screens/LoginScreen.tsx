import React, { useState } from 'react';
import { login, register } from '../lib/auth';
import { LogIn, UserPlus, AlertCircle, ArrowRight, CheckCircle2, Store, Phone, Mail, Lock, User } from 'lucide-react';
import './LoginScreen.css';

export const LoginScreen: React.FC = () => {
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [businessName, setBusinessName] = useState('');
  const [phone, setPhone] = useState('');
  const [rememberMe, setRememberMe] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      if (mode === 'login') {
        await login(email, password);
        sessionStorage.setItem('ta_session_entered', 'true');
        window.location.reload();
      } else {
        const result = await register(email, password, name);
        if (result) {
          sessionStorage.setItem('ta_session_entered', 'true');
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

  const handleDemoLogin = async () => {
    setError(null);
    setLoading(true);
    try {
      await login('owner@tigaangkatan.id', 'password123');
      sessionStorage.setItem('ta_session_entered', 'true');
      window.location.reload();
    } catch (err: any) {
      const msg = err?.error || err?.message || 'Gagal masuk akun demo.';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-screen-wrapper">
      <div className="login-card-container">
        {/* ── 1. Curved Obsidian Header (1:1 Mobile Parity) ── */}
        <div className="login-curved-header">
          <div className="header-logo-row">
            <img
              src="/logoAisitenku.png"
              alt="Logo Aisistenku"
              className="header-brand-logo"
              onError={(e) => {
                (e.target as HTMLImageElement).src = '/iconAisistenku.png';
              }}
            />
          </div>

          <div className="header-titles">
            <h1 className="header-headline">
              {mode === 'register' ? 'Daftar Akun Baru' : 'Selamat Datang'}
            </h1>
            <p className="header-subtitle">
              {mode === 'register'
                ? 'Langkah awal menuju manajemen toko yang lebih cerdas dan otomatis.'
                : 'AISISTENKU — Sistem Manajemen Toko & POS'}
            </p>
          </div>
        </div>

        {/* ── 2. Form Body ── */}
        <div className="login-card-body">
          {/* Segmented Control (Masuk / Daftar Baru) */}
          <div className="login-pill-tabs">
            <button
              type="button"
              onClick={() => { setMode('login'); setError(null); }}
              className={`pill-tab ${mode === 'login' ? 'active' : ''}`}
            >
              <LogIn size={15} />
              <span>Masuk</span>
            </button>
            <button
              type="button"
              onClick={() => { setMode('register'); setError(null); }}
              className={`pill-tab ${mode === 'register' ? 'active' : ''}`}
            >
              <UserPlus size={15} />
              <span>Daftar Baru</span>
            </button>
          </div>

          {error && (
            <div className="login-error-pill">
              <AlertCircle size={16} />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="auth-form">
            {mode === 'register' && (
              <>
                <div className="form-field-group">
                  <label>Nama Pemilik Toko</label>
                  <div className="input-icon-wrap">
                    <User size={16} className="field-icon" />
                    <input
                      type="text"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="Contoh: Budi Santoso"
                      required
                    />
                  </div>
                </div>

                <div className="form-field-group">
                  <label>Nama Gerai / Bisnis</label>
                  <div className="input-icon-wrap">
                    <Store size={16} className="field-icon" />
                    <input
                      type="text"
                      value={businessName}
                      onChange={(e) => setBusinessName(e.target.value)}
                      placeholder="Contoh: Toko Tiga Angkatan"
                    />
                  </div>
                </div>

                <div className="form-field-group">
                  <label>No. Handphone (WhatsApp)</label>
                  <div className="input-icon-wrap">
                    <Phone size={16} className="field-icon" />
                    <input
                      type="tel"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="0812xxxxxxxx"
                    />
                  </div>
                </div>
              </>
            )}

            <div className="form-field-group">
              <label>Email Pengguna</label>
              <div className="input-icon-wrap">
                <Mail size={16} className="field-icon" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="owner@tigaangkatan.id"
                  required
                />
              </div>
            </div>

            <div className="form-field-group">
              <label>Kata Sandi</label>
              <div className="input-icon-wrap">
                <Lock size={16} className="field-icon" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                />
              </div>
            </div>

            {mode === 'login' && (
              <div className="login-options-row">
                <label className="remember-checkbox-label">
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                  />
                  <span>Ingat Saya</span>
                </label>
                <span className="forgot-password-link">Lupa Kata Sandi?</span>
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="btn-auth-submit"
            >
              <span>{loading ? 'Memproses...' : mode === 'login' ? 'Masuk ke Akun' : 'Daftar Sekarang'}</span>
              <ArrowRight size={16} />
            </button>
          </form>

          {/* Quick Demo Login Option */}
          <div className="demo-access-divider">
            <span>AKSES CEPAT PERCONTOHAN</span>
          </div>

          <button
            type="button"
            onClick={handleDemoLogin}
            disabled={loading}
            className="btn-demo-quick-login"
          >
            <div className="demo-icon-chip">
              <CheckCircle2 size={16} />
            </div>
            <div className="demo-text-box">
              <strong>Masuk Akun Demo (Owner)</strong>
              <span>owner@tigaangkatan.id • Langsung Jelajahi Semua Fitur</span>
            </div>
          </button>
        </div>
      </div>
    </div>
  );
};

export default LoginScreen;
