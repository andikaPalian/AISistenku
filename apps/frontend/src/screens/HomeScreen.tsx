import React from 'react';
import { TabType, StockAlert } from '../types';
import { TrendingUp, ShoppingBag, ArrowUpRight, Sparkles, AlertTriangle, ArrowRight } from 'lucide-react';
import './HomeScreen.css';

interface HomeScreenProps {
  onNavigateTab: (tab: TabType) => void;
  stockAlerts: StockAlert[];
  dashboard?: {
    dailyRevenue?: { amount: number; percentChange: number };
    dailyActivity?: { transactionCount: number; percentChange: number; bestSellerName: string; bestSellerQty: number; bestSellerUnit: string };
    lowStockAlertsCount?: number;
    aiInsight?: { message: string; timestamp: string };
  } | null;
  dashboardLoading?: boolean;
}

const formatRupiah = (n: number) => `Rp ${(n || 0).toLocaleString('id-ID')}`;

export const HomeScreen: React.FC<HomeScreenProps> = ({ onNavigateTab, stockAlerts, dashboard }) => {
  const revenue = dashboard?.dailyRevenue?.amount ?? 0;
  const txCount = dashboard?.dailyActivity?.transactionCount ?? 0;
  const best = dashboard?.dailyActivity;
  const insight = dashboard?.aiInsight?.message || 'AI siap membantu analisis bisnis Anda.';
  const avgNota = txCount > 0 ? Math.round(revenue / txCount) : 0;

  return (
    <div className="page-screen animate-fade-in">
      <div className="home-welcome">
        <div>
          <h1 className="welcome-title">Halo, Owner 👋</h1>
          <p className="welcome-sub">Ringkasan aktivitas & performa toko hari ini.</p>
        </div>
        <div className="quick-action-group">
          <button onClick={() => onNavigateTab('pos')} className="btn-primary">
            <ShoppingBag size={16} />
            Kasir Baru
          </button>
        </div>
      </div>

      <div className="home-grid">
        <div className="home-left-col">
          <div className="card-base revenue-card">
            <div className="revenue-header">
              <div>
                <span className="card-subtitle">PENDAPATAN HARI INI</span>
                <h2 className="revenue-amount">{formatRupiah(revenue)}</h2>
              </div>
              <div className="trend-badge positive">
                <ArrowUpRight size={14} />
                <span>+{(dashboard?.dailyRevenue?.percentChange ?? 0).toFixed(1)}% vs kemarin</span>
              </div>
            </div>

            <div className="revenue-stats">
              <div className="stat-box">
                <span className="stat-label">Total Transaksi</span>
                <span className="stat-value">{txCount} Nota</span>
              </div>
              <div className="stat-divider"></div>
              <div className="stat-box">
                <span className="stat-label">Rata-rata Nota</span>
                <span className="stat-value">{formatRupiah(avgNota)}</span>
              </div>
              <div className="stat-divider"></div>
              <div className="stat-box">
                <span className="stat-label">Best Seller</span>
                <span className="stat-value">
                  {best ? `${best.bestSellerName} (${best.bestSellerQty} ${best.bestSellerUnit})` : '-'}
                </span>
              </div>
            </div>
          </div>

          <div className="card-base ai-insight-card">
            <div className="ai-card-header">
              <div className="ai-title-badge">
                <Sparkles size={16} className="ai-sparkle-icon" />
                <span>AI Insight Recommender</span>
              </div>
              <span className="badge badge-teal">Update realtime</span>
            </div>

            <h3 className="ai-insight-heading">{insight}</h3>
            <p className="ai-insight-body">
              Data diambil langsung dari database backend. Cek rekomendasi di bawah untuk bertindak.
            </p>

            <div className="ai-action-bar">
              <button onClick={() => onNavigateTab('stock')} className="btn-secondary">
                Cek Stok Sekarang
                <ArrowRight size={14} />
              </button>
              <button onClick={() => onNavigateTab('ai')} className="btn-text-teal">
                Tanya AI
              </button>
            </div>
          </div>
        </div>

        <div className="home-right-col">
          <div className="card-base stock-alerts-card">
            <div className="card-header-flex">
              <div className="alert-title-wrap">
                <AlertTriangle size={18} className="warning-icon" />
                <h3 className="section-title">Perlu Diperhatikan</h3>
              </div>
              <span className="badge badge-warning">{stockAlerts.length} Peringatan</span>
            </div>

            <div className="alert-list">
              {stockAlerts.length === 0 ? (
                <p className="empty-state-small">Tidak ada stok yang perlu diperhatikan. 🎉</p>
              ) : stockAlerts.map((alert) => (
                <div key={alert.id} className="alert-item">
                  <div className="alert-info">
                    <span className="alert-product">{alert.productName}</span>
                    <span className="alert-meta">
                      Sisa stok: <strong>{alert.currentStock} {alert.unit}</strong> (Min: {alert.minStock})
                    </span>
                  </div>
                  <button onClick={() => onNavigateTab('stock')} className="btn-alert-action">
                    Tambah
                  </button>
                </div>
              ))}
            </div>

            <button onClick={() => onNavigateTab('stock')} className="btn-full-secondary">
              Kelola Seluruh Stok
            </button>
          </div>

          <div className="card-base shortcuts-card">
            <h3 className="section-title">Aksi Cepat Kasir</h3>
            <div className="shortcuts-grid">
              <button onClick={() => onNavigateTab('pos')} className="shortcut-btn">
                <div className="shortcut-icon teal"><ShoppingBag size={20} /></div>
                <span>Kasir POS</span>
              </button>
              <button onClick={() => onNavigateTab('stock')} className="shortcut-btn">
                <div className="shortcut-icon orange"><AlertTriangle size={20} /></div>
                <span>Cek Stok</span>
              </button>
              <button onClick={() => onNavigateTab('finance')} className="shortcut-btn">
                <div className="shortcut-icon blue"><TrendingUp size={20} /></div>
                <span>Catat Biaya</span>
              </button>
              <button onClick={() => onNavigateTab('ai')} className="shortcut-btn">
                <div className="shortcut-icon purple"><Sparkles size={20} /></div>
                <span>Tanya AI</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HomeScreen;
