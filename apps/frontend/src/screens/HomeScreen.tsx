import React from 'react';
import { TabType, StockAlert } from '../types';
import { TrendingUp, ShoppingBag, ArrowUpRight, Sparkles, AlertTriangle, ArrowRight, CheckCircle2, ChevronRight } from 'lucide-react';
import './HomeScreen.css';

interface HomeScreenProps {
  onNavigateTab: (tab: TabType) => void;
  stockAlerts: StockAlert[];
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ onNavigateTab, stockAlerts }) => {
  return (
    <div className="page-screen animate-fade-in">
      {/* Welcome & Quick Action Header */}
      <div className="home-welcome">
        <div>
          <h1 className="welcome-title">Halo, Budi Santoso 👋</h1>
          <p className="welcome-sub">Ringkasan aktivitas & performa toko hari ini.</p>
        </div>
        <div className="quick-action-group">
          <button onClick={() => onNavigateTab('pos')} className="btn-primary">
            <ShoppingBag size={16} />
            Kasir Baru
          </button>
        </div>
      </div>

      {/* Main Grid: Responsive layout for Mobile (1 col), Tablet (2 col), Desktop (Multi-col) */}
      <div className="home-grid">
        {/* Left Column Section */}
        <div className="home-left-col">
          {/* Bisnis Hari Ini Card */}
          <div className="card-base revenue-card">
            <div className="revenue-header">
              <div>
                <span className="card-subtitle">PENDAPATAN HARI INI</span>
                <h2 className="revenue-amount">Rp 1.450.000</h2>
              </div>
              <div className="trend-badge positive">
                <ArrowUpRight size={14} />
                <span>+12.5% vs kemarin</span>
              </div>
            </div>

            <div className="revenue-stats">
              <div className="stat-box">
                <span className="stat-label">Total Transaksi</span>
                <span className="stat-value">18 Nota</span>
              </div>
              <div className="stat-divider"></div>
              <div className="stat-box">
                <span className="stat-label">Rata-rata Nota</span>
                <span className="stat-value">Rp 80.500</span>
              </div>
              <div className="stat-divider"></div>
              <div className="stat-box">
                <span className="stat-label">Stok Terjual</span>
                <span className="stat-value">42 Item</span>
              </div>
            </div>
          </div>

          {/* AI Insight Card */}
          <div className="card-base ai-insight-card">
            <div className="ai-card-header">
              <div className="ai-title-badge">
                <Sparkles size={16} className="ai-sparkle-icon" />
                <span>AI Insight Recommender</span>
              </div>
              <span className="badge badge-teal">Update 10m lalu</span>
            </div>

            <h3 className="ai-insight-heading">
              Permintaan Minyak Goreng & Gula Pasir Diprediksi Naik 25% Minggu Ini
            </h3>
            <p className="ai-insight-body">
              Berdasarkan tren tanggal gajian & riwayat bulan lalu, stok Minyak Goreng (sisa 5 pouch) dan Gula (sisa 3kg) berpotensi habis dalam 24 jam.
            </p>

            <div className="ai-action-bar">
              <button onClick={() => onNavigateTab('stock')} className="btn-secondary">
                Restock Produk Sekarang
                <ArrowRight size={14} />
              </button>
              <button onClick={() => onNavigateTab('ai')} className="btn-text-teal">
                Konsultasikan AI
              </button>
            </div>
          </div>

          {/* Activity & Best Sellers */}
          <div className="card-base activity-card">
            <div className="card-header-flex">
              <h3 className="section-title">Produk Terlaris Hari Ini</h3>
              <button onClick={() => onNavigateTab('stock')} className="btn-link">Lihat Semua</button>
            </div>

            <div className="best-sellers-list">
              <div className="seller-item">
                <div className="seller-rank">1</div>
                <div className="seller-info">
                  <span className="seller-name">Beras Pandan Wangi 5kg</span>
                  <span className="seller-sub">Terjual 12 karung • Sisa Stok: 24</span>
                </div>
                <span className="seller-price">Rp 936.000</span>
              </div>

              <div className="seller-item">
                <div className="seller-rank">2</div>
                <div className="seller-info">
                  <span className="seller-name">Minyak Goreng SunCo 2L</span>
                  <span className="seller-sub">Terjual 8 pouch • Sisa Stok: 5</span>
                </div>
                <span className="seller-price">Rp 308.000</span>
              </div>

              <div className="seller-item">
                <div className="seller-rank">3</div>
                <div className="seller-info">
                  <span className="seller-name">Telur Ayam Negeri 1kg</span>
                  <span className="seller-sub">Terjual 6 kg • Sisa Stok: 45</span>
                </div>
                <span className="seller-price">Rp 174.000</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column Section (Stock Alerts & Quick Links) */}
        <div className="home-right-col">
          {/* Perlu Diperhatikan / Stock Alerts Section */}
          <div className="card-base stock-alerts-card">
            <div className="card-header-flex">
              <div className="alert-title-wrap">
                <AlertTriangle size={18} className="warning-icon" />
                <h3 className="section-title">Perlu Diperhatikan</h3>
              </div>
              <span className="badge badge-warning">{stockAlerts.length} Peringatan</span>
            </div>

            <div className="alert-list">
              {stockAlerts.map((alert) => (
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

          {/* Quick Shortcuts */}
          <div className="card-base shortcuts-card">
            <h3 className="section-title">Aksi Cepat Kasir</h3>
            <div className="shortcuts-grid">
              <button onClick={() => onNavigateTab('pos')} className="shortcut-btn">
                <div className="shortcut-icon teal">
                  <ShoppingBag size={20} />
                </div>
                <span>Kasir POS</span>
              </button>

              <button onClick={() => onNavigateTab('stock')} className="shortcut-btn">
                <div className="shortcut-icon orange">
                  <AlertTriangle size={20} />
                </div>
                <span>Cek Stok</span>
              </button>

              <button onClick={() => onNavigateTab('finance')} className="shortcut-btn">
                <div className="shortcut-icon blue">
                  <TrendingUp size={20} />
                </div>
                <span>Catat Biaya</span>
              </button>

              <button onClick={() => onNavigateTab('ai')} className="shortcut-btn">
                <div className="shortcut-icon purple">
                  <Sparkles size={20} />
                </div>
                <span>Tanya AI</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
