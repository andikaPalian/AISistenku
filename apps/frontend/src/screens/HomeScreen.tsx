import React, { useEffect, useRef } from 'react';
import { TabType, StockAlert } from '../types';
import { ShoppingBag, ArrowUpRight, Sparkles, AlertTriangle, ArrowRight, ArrowDownRight, Wallet, CheckCircle2 } from 'lucide-react';
import { animateScreenEntrance } from '../lib/animations';
import { SalesAnalyticsChart } from '../components/charts/SalesAnalyticsChart';
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
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    animateScreenEntrance(containerRef.current);
  }, []);

  const revenue = dashboard?.dailyRevenue?.amount ?? 1250000;
  const txCount = dashboard?.dailyActivity?.transactionCount ?? 32;
  const percentChange = dashboard?.dailyRevenue?.percentChange ?? 12.0;
  const best = dashboard?.dailyActivity || {
    bestSellerName: 'Iced Latte',
    bestSellerQty: 42,
    bestSellerUnit: 'cup'
  };
  const insight = dashboard?.aiInsight?.message || 'Penjualan hari ini berjalan lancar. Iced Latte saat ini menjadi produk terlaris (42 cup), namun stok Gula Aren dan Susu UHT mulai menipis.';
  const avgNota = txCount > 0 ? Math.round(revenue / txCount) : 39063;

  const estimatedExpense = 420000;
  const estimatedProfit = revenue - estimatedExpense;
  const grossMargin = ((estimatedProfit / revenue) * 100).toFixed(1);

  return (
    <div ref={containerRef} className="page-screen">
      {/* ── 1. Top Greeting Bar ── */}
      <div className="home-welcome gsap-reveal">
        <div className="welcome-identity">
          <div className="welcome-avatar-box">
            <span>TA</span>
          </div>
          <div>
            <div className="welcome-title-row">
              <h1 className="welcome-title">Toko Tiga Angkatan</h1>
              <span className="shift-badge-active">
                <span className="shift-dot"></span>
                Shift Pagi Aktif
              </span>
            </div>
            <p className="welcome-sub">Selamat datang, Kasir Utama • Ringkasan operasional toko hari ini</p>
          </div>
        </div>

        <div className="quick-action-group">
          <button onClick={() => onNavigateTab('pos')} className="btn-primary">
            <ShoppingBag size={16} />
            <span>+ Buka Kasir POS</span>
          </button>
        </div>
      </div>

      {/* ── 2. Main Dashboard Grid ── */}
      <div className="home-grid">
        {/* Left Column (65%) */}
        <div className="home-left-col">
          {/* Revenue & Key Metrics Card */}
          <div className="card-base revenue-card gsap-reveal">
            <div className="revenue-header">
              <div>
                <span className="card-subtitle">PENDAPATAN HARI INI</span>
                <h2 className="revenue-amount">{formatRupiah(revenue)}</h2>
              </div>
              <div className="trend-badge positive">
                <ArrowUpRight size={15} />
                <span>+{percentChange.toFixed(1)}% vs kemarin</span>
              </div>
            </div>

            <div className="revenue-stats">
              <div className="stat-box">
                <span className="stat-label">Total Transaksi</span>
                <span className="stat-value">{txCount} Nota</span>
              </div>
              <div className="stat-divider"></div>
              <div className="stat-box">
                <span className="stat-label">Rata-rata Keranjang</span>
                <span className="stat-value">{formatRupiah(avgNota)}</span>
              </div>
              <div className="stat-divider"></div>
              <div className="stat-box">
                <span className="stat-label">Produk Terlaris</span>
                <span className="stat-value text-teal-accent">
                  {best ? `${best.bestSellerName} (${best.bestSellerQty} ${best.bestSellerUnit})` : '-'}
                </span>
              </div>
            </div>
          </div>

          {/* Mobile-style Sales Analytics Chart on Home */}
          <div className="gsap-reveal">
            <SalesAnalyticsChart
              title="Tren Penjualan Mingguan"
              subtitle="Grafik omzet penjualan & arus kas 7 hari terakhir"
              growthPercentage="+18.4%"
            />
          </div>

          {/* AI Insight Executive Briefing Card */}
          <div className="card-base ai-insight-card gsap-reveal">
            <div className="ai-card-header">
              <div className="ai-title-badge">
                <div className="home-ai-badge-container">
                  <img src="/iconAisistenku.png" alt="AIsistenku" className="home-ai-badge-img" />
                </div>
                <span>AI Insight Toko</span>
              </div>
              <span className="badge-ai-status">Live Realtime</span>
            </div>

            <h3 className="ai-insight-heading">{insight}</h3>
            <p className="ai-insight-body">
              AIsistenku mendeteksi 3 bahan baku menipis menjelang jam sibuk sore. Ambil tindakan cepat untuk mencegah kehabisan pesanan kopi.
            </p>

            <div className="ai-action-bar">
              <button onClick={() => onNavigateTab('stock')} className="btn-ai-primary">
                <span>Periksa Stok Bahan</span>
                <ArrowRight size={15} />
              </button>
              <button onClick={() => onNavigateTab('ai')} className="btn-ai-secondary">
                <div className="home-ai-btn-container">
                  <img src="/iconAisistenku.png" alt="AIsistenku" className="home-ai-btn-img" />
                </div>
                <span>Tanya AIsisten</span>
              </button>
            </div>
          </div>
        </div>

        {/* Right Column (35%) */}
        <div className="home-right-col">
          {/* Stock Alerts Card */}
          <div className="card-base stock-alerts-card gsap-reveal">
            <div className="card-header-flex">
              <div className="alert-title-wrap">
                <AlertTriangle size={18} className="warning-icon" />
                <h3 className="section-title">Perlu Diperhatikan</h3>
              </div>
              <span className="badge badge-warning">{stockAlerts.length} Peringatan</span>
            </div>

            <div className="alert-list">
              {stockAlerts.length === 0 ? (
                <div className="empty-stock-state">
                  <CheckCircle2 size={24} className="text-emerald-600 mb-1" />
                  <p className="empty-state-small">Seluruh stok bahan baku dalam batas aman.</p>
                </div>
              ) : stockAlerts.map((alert) => (
                <div key={alert.id} className="alert-item">
                  <div className="alert-info">
                    <span className="alert-product">{alert.productName}</span>
                    <span className="alert-meta">
                      Tersisa: <strong className="alert-qty">{alert.currentStock} {alert.unit}</strong> (Min: {alert.minStock} {alert.unit})
                    </span>
                  </div>
                  <button onClick={() => onNavigateTab('stock')} className="btn-alert-action">
                    + Restock
                  </button>
                </div>
              ))}
            </div>

            <button onClick={() => onNavigateTab('stock')} className="btn-full-secondary">
              <span>Kelola Seluruh Stok Bahan</span>
              <ArrowRight size={14} />
            </button>
          </div>

          {/* Real Financial Summary Module */}
          <div className="card-base financial-summary-card gsap-reveal">
            <div className="card-header-flex">
              <div className="flex-header-title">
                <Wallet size={18} className="text-teal-primary" />
                <h3 className="section-title">Arus Kas Hari Ini</h3>
              </div>
              <span className="badge badge-success">Margin {grossMargin}%</span>
            </div>

            <div className="finance-breakdown-list">
              <div className="finance-breakdown-row">
                <div className="finance-label-group">
                  <div className="finance-icon-pill green">
                    <ArrowDownRight size={14} />
                  </div>
                  <span>Pemasukan Kasir</span>
                </div>
                <strong className="finance-val positive">+{formatRupiah(revenue)}</strong>
              </div>

              <div className="finance-breakdown-row">
                <div className="finance-label-group">
                  <div className="finance-icon-pill red">
                    <ArrowUpRight size={14} />
                  </div>
                  <span>Pengeluaran Kulakan</span>
                </div>
                <strong className="finance-val negative">-{formatRupiah(estimatedExpense)}</strong>
              </div>

              <div className="finance-breakdown-divider"></div>

              <div className="finance-breakdown-row total">
                <span className="finance-total-label">Estimasi Laba Bersih</span>
                <strong className="finance-total-val">{formatRupiah(estimatedProfit)}</strong>
              </div>
            </div>

            <button onClick={() => onNavigateTab('finance')} className="btn-link-finance">
              <span>Lihat Detail Laporan Keuangan</span>
              <ArrowRight size={14} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HomeScreen;
