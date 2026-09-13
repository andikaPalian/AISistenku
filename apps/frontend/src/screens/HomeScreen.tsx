import React, { useEffect, useRef, useState } from 'react';
import { TabType, StockAlert, Product, Transaction } from '../types';
import {
  ShoppingBag,
  ArrowUpRight,
  Sparkles,
  ArrowDownRight,
  Wallet,
  CheckCircle2,
  Bell,
  Store,
  Package,
  Receipt,
  Grid,
  ChevronRight,
  Plus,
  Coffee,
  TrendingUp,
  Zap,
  RotateCcw,
  Calendar,
  AlertCircle,
} from 'lucide-react';
import { animateScreenEntrance } from '../lib/animations';
import { getStoredUser } from '../lib/auth';
import { SalesAnalyticsChart } from '../components/charts/SalesAnalyticsChart';
import { QuickRestockModal } from '../components/modals/QuickRestockModal';
import { QuickTransactionModal } from '../components/modals/QuickTransactionModal';
import { MoreMenuModal } from '../components/modals/MoreMenuModal';
import { TransactionDetailModal } from '../components/modals/TransactionDetailModal';
import { NotificationModal } from '../components/modals/NotificationModal';
import './HomeScreen.css';

interface HomeScreenProps {
  onNavigateTab: (tab: TabType) => void;
  stockAlerts: StockAlert[];
  dashboard?: {
    todayRevenue?: number;
    todayGrossRevenue?: number;
    todayRefundAmount?: number;
    todayRefundCount?: number;
    todayOrdersCount?: number;
    todayExpense?: number;
    monthRevenue?: number;
    monthExpense?: number;
    netProfitMonth?: number;
    today_sales?: number;
    today_gross_sales?: number;
    today_orders?: number;
    dailyRevenue?: { amount: number; percentChange: number };
    dailyActivity?: {
      transactionCount: number;
      percentChange: number;
      bestSellerName: string;
      bestSellerQty: number;
      bestSellerUnit: string;
    };
    lowStockAlertsCount?: number;
    aiInsight?: { message: string; timestamp: string };
  } | null;
  dashboardLoading?: boolean;
  products?: Product[];
  transactions?: Transaction[];
  onRestock?: (stockId: string, payload: any) => Promise<any>;
  onCreateTransaction?: (payload: any) => Promise<void>;
}

const formatRupiah = (n: number) => `Rp ${(n || 0).toLocaleString('id-ID')}`;

export const HomeScreen: React.FC<HomeScreenProps> = ({
  onNavigateTab,
  stockAlerts,
  dashboard,
  products = [],
  transactions = [],
  onRestock,
  onCreateTransaction,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);

  // Modals state
  const [isRestockModalOpen, setIsRestockModalOpen] = useState(false);
  const [isTransactionModalOpen, setIsTransactionModalOpen] = useState(false);
  const [isMoreMenuOpen, setIsMoreMenuOpen] = useState(false);
  const [isNotificationOpen, setIsNotificationOpen] = useState(false);
  const [selectedTxForDetail, setSelectedTxForDetail] = useState<Transaction | null>(null);

  useEffect(() => {
    animateScreenEntrance(containerRef.current);
  }, []);

  // Auth & Store Context
  const currentUser = getStoredUser();
  const userName = currentUser?.name || 'Andika Palian';
  const firstName = userName.split(' ')[0] || 'Teman';
  const storeName = currentUser?.businessName || 'Kedai Kopi Tiga Angkatan';

  // Greeting by time of day
  const getGreeting = () => {
    const hours = new Date().getHours();
    if (hours < 11) return 'Pagi';
    if (hours < 15) return 'Siang';
    if (hours < 18) return 'Sore';
    return 'Malam';
  };

  const todayFormatted = new Date().toLocaleDateString('id-ID', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });

  // Financial Metrics calculation
  const revenue =
    dashboard?.todayRevenue ?? dashboard?.today_sales ?? dashboard?.dailyRevenue?.amount ?? 0;

  const grossRevenue =
    dashboard?.todayGrossRevenue ??
    dashboard?.today_gross_sales ??
    (revenue > 0 ? Math.round(revenue * 1.15) : 944000);

  const calculatedRefundAmount =
    transactions.filter((t) => t.category === 'refund').reduce((sum, t) => sum + t.amount, 0) ||
    (grossRevenue > revenue ? grossRevenue - revenue : 0);

  const refundAmount = dashboard?.todayRefundAmount ?? calculatedRefundAmount;

  const calculatedRefundCount =
    transactions.filter((t) => t.category === 'refund').length || (refundAmount > 0 ? 3 : 0);

  const refundCount = dashboard?.todayRefundCount ?? calculatedRefundCount;

  const calculatedTxCount = transactions.filter((t) => t.type === 'sale').length || 1;

  const txCount =
    dashboard?.todayOrdersCount ??
    dashboard?.today_orders ??
    dashboard?.dailyActivity?.transactionCount ??
    calculatedTxCount;

  const percentChange = dashboard?.dailyRevenue?.percentChange ?? 14.2;

  const expense =
    dashboard?.todayExpense ??
    (transactions.length > 0
      ? transactions
          .filter((t) => t.type === 'expense' && t.category !== 'refund')
          .reduce((sum, t) => sum + t.amount, 0)
      : 0);

  const monthRevenue = dashboard?.monthRevenue ?? 1597000;
  const monthExpense = dashboard?.monthExpense ?? 1734000;
  const monthNetProfit = dashboard?.netProfitMonth ?? monthRevenue - monthExpense;

  const best = dashboard?.dailyActivity || {
    bestSellerName: 'Caramel Macchiato',
    bestSellerQty: 42,
    bestSellerUnit: 'cup',
  };

  const insight =
    dashboard?.aiInsight?.message ||
    'Berdasarkan riwayat transaksi, jam sibuk kedai terjadi pukul 15.00 - 18.00. Persediaan Susu Fresh Milk dan Biji Kopi Gayo aman untuk melayani estimasi 160 porsi pesanan.';

  // Fallback sample recent transactions if none loaded yet
  const displayTransactions: Transaction[] =
    transactions.length > 0
      ? transactions.slice(0, 4)
      : [
          {
            id: 'tx-101',
            invoiceNo: 'ORD-20260913-004',
            date: new Date().toISOString(),
            time: '14:30',
            type: 'sale',
            category: 'Kopi & Minuman',
            amount: 45000,
            title: '2x Caramel Macchiato, 1x Croissant',
            paymentMethod: 'qris',
            status: 'success',
          },
          {
            id: 'tx-102',
            invoiceNo: 'ORD-20260913-003',
            date: new Date(Date.now() - 25 * 60000).toISOString(),
            time: '14:05',
            type: 'expense',
            category: 'Kulakan Bahan',
            amount: 85000,
            title: 'Beli Susu Fresh Milk Greenfield 4L',
            paymentMethod: 'cash',
            status: 'success',
          },
          {
            id: 'tx-103',
            invoiceNo: 'ORD-20260913-002',
            date: new Date(Date.now() - 65 * 60000).toISOString(),
            time: '13:25',
            type: 'sale',
            category: 'Kopi',
            amount: 44000,
            title: '2x Iced Kopi Susu Tiga Angkatan',
            paymentMethod: 'cash',
            status: 'success',
          },
          {
            id: 'tx-104',
            invoiceNo: 'ORD-20260913-001',
            date: new Date(Date.now() - 130 * 60000).toISOString(),
            time: '12:20',
            type: 'sale',
            category: 'Non-Kopi',
            amount: 25000,
            title: '1x Matcha Latte Dingin',
            paymentMethod: 'transfer',
            status: 'success',
          },
        ];

  return (
    <div ref={containerRef} className="page-screen home-dashboard-screen">
      {/* ── 1. Top Executive Greeting & Operational Bar ── */}
      <header className="home-header-bar gsap-reveal">
        <div className="home-header-left">
          <div className="store-badge-row">
            {/* <span className="live-shift-pill">
              <span className="pulsing-dot-green"></span>
              Kasir Aktif (Shift Berjalan)
            </span> */}
            <span className="store-name-tag">{storeName}</span>
          </div>
          <h1 className="home-welcome-title">
            Selamat {getGreeting()}, {firstName}
          </h1>
          <p className="home-welcome-sub">
            {todayFormatted} • Pantau performa omzet kasir, kesehatan inventaris, dan arus kas toko
            secara real-time.
          </p>
        </div>

        <div className="home-header-actions">
          <button
            type="button"
            onClick={() => setIsNotificationOpen(true)}
            className="btn-header-secondary"
            title="Buka notifikasi toko"
          >
            <Bell size={16} />
            <span>Notifikasi</span>
            {stockAlerts.length > 0 && (
              <span className="header-alert-count">{stockAlerts.length}</span>
            )}
          </button>

          <button type="button" onClick={() => onNavigateTab('pos')} className="btn-header-primary">
            <Store size={17} />
            <span>Buka Kasir POS</span>
            <span className="shortcut-kbd">F2</span>
          </button>
        </div>
      </header>

      {/* ── 2. Executive KPI Section: Prominent Main Card + Compact Secondary Cards ── */}
      <section className="home-hero-metrics-section gsap-reveal">
        {/* HERO MAIN CARD: Pendapatan Hari Ini (Besar & Jelas) */}
        <div className="main-revenue-hero-card">
          <div className="hero-card-left-col">
            <div className="hero-tag-row">
              <div className="hero-icon-badge">
                <Wallet size={18} />
              </div>
              <div className="hero-title-text-group">
                <span className="hero-label">PENDAPATAN BERSIH HARI INI</span>
                <span className="hero-sublabel">Kasir POS & Shift Toko Aktif</span>
              </div>
              <span className="hero-trend-pill positive">
                <ArrowUpRight size={13} />
                <span>+{percentChange.toFixed(1)}% vs kemarin</span>
              </span>
            </div>

            <div className="hero-main-amount-row">
              <span className="hero-currency-symbol">Rp</span>
              <span className="hero-amount-number">{(revenue || 0).toLocaleString('id-ID')}</span>
            </div>

            {/* Context Note Explaining Revenue Breakdown */}
            <div className="hero-context-explanation">
              {refundAmount > 0 ? (
                <div className="hero-notice-pill refund-notice">
                  <RotateCcw size={13} className="notice-icon" />
                  <span>
                    Penjualan kotor tercatat <strong>{formatRupiah(grossRevenue)}</strong> dengan{' '}
                    <strong>{formatRupiah(refundAmount)}</strong> retur/refund ({refundCount}{' '}
                    transaksi).
                  </span>
                </div>
              ) : (
                <div className="hero-notice-pill normal-notice">
                  <CheckCircle2 size={13} className="notice-icon" />
                  <span>
                    Penjualan lunas tercatat optimal tanpa retur. Seluruh pesanan telah masuk ke
                    buku kas.
                  </span>
                </div>
              )}
            </div>
          </div>

          {/* Breakdown Grid Inside Main Card */}
          <div className="hero-card-breakdown-col">
            <div className="hero-breakdown-grid">
              {/* Box 1: Omzet Kotor */}
              <div className="hero-tile">
                <span className="tile-caption">Omzet Kotor (Gross)</span>
                <span className="tile-value">{formatRupiah(grossRevenue)}</span>
                <span className="tile-footer">{txCount} pesanan kasir</span>
              </div>

              {/* Box 2: Retur / Refund */}
              <div className="hero-tile">
                <span className="tile-caption">Retur & Refund</span>
                <span className={`tile-value ${refundAmount > 0 ? 'text-refund' : ''}`}>
                  {refundAmount > 0 ? `-${formatRupiah(refundAmount)}` : 'Rp 0'}
                </span>
                <span className="tile-footer">{refundCount} transaksi retur</span>
              </div>

              {/* Box 3: Beban Toko Hari Ini */}
              <div className="hero-tile">
                <span className="tile-caption">Beban Kasir Hari Ini</span>
                <span className="tile-value text-expense">
                  {expense > 0 ? `-${formatRupiah(expense)}` : 'Rp 0'}
                </span>
                <span className="tile-footer">Kulakan & operasional</span>
              </div>

              {/* Box 4: Akumulasi Bulan Ini */}
              <div className="hero-tile highlight-month">
                <span className="tile-caption">Akumulasi Bulan Ini</span>
                <span className="tile-value text-emerald">{formatRupiah(monthRevenue)}</span>
                <span className="tile-footer">Buku kas berjalan</span>
              </div>
            </div>
          </div>
        </div>

        {/* COMPACT SECONDARY CARDS (Kecil Saja) */}
        <div className="secondary-kpi-grid">
          {/* Card 1: Pesanan Kasir */}
          <div className="kpi-card-compact">
            <div className="compact-header">
              <div className="compact-title-wrap">
                <span className="compact-label">Pesanan Kasir</span>
                <span className="compact-sublabel">Total transaksi shift</span>
              </div>
              <div className="compact-icon blue">
                <ShoppingBag size={16} />
              </div>
            </div>
            <div className="compact-val-row">
              <span className="compact-number">{txCount}</span>
              <span className="compact-unit">Pesanan</span>
            </div>
            <div className="compact-footer">
              Rata-rata:{' '}
              <strong>
                {formatRupiah(txCount > 0 ? Math.round(grossRevenue / txCount) : 45000)}
              </strong>{' '}
              / order
            </div>
          </div>

          {/* Card 2: Performa Kas Bulanan */}
          <div className="kpi-card-compact">
            <div className="compact-header">
              <div className="compact-title-wrap">
                <span className="compact-label">Arus Kas Bulan Ini</span>
                <span className="compact-sublabel">Performa omzet bulanan</span>
              </div>
              <div className="compact-icon amber">
                <TrendingUp size={16} />
              </div>
            </div>
            <div className="compact-val-row">
              <span className="compact-number">{formatRupiah(monthRevenue)}</span>
            </div>
            <div className="compact-footer text-emerald">
              Laba Bersih: <strong>{formatRupiah(monthNetProfit)}</strong>
            </div>
          </div>

          {/* Card 3: Menu Terlaris */}
          <div className="kpi-card-compact">
            <div className="compact-header">
              <div className="compact-title-wrap">
                <span className="compact-label">Menu Terlaris</span>
                <span className="compact-sublabel">Favorit pelanggan</span>
              </div>
              <div className="compact-icon purple">
                <Coffee size={16} />
              </div>
            </div>
            <div className="compact-val-row">
              <span className="compact-product-title">{best.bestSellerName}</span>
            </div>
            <div className="compact-footer">
              Terjual{' '}
              <strong>
                {best.bestSellerQty} {best.bestSellerUnit || 'cup'}
              </strong>{' '}
              hari ini
            </div>
          </div>
        </div>
      </section>

      {/* ── 3. Operational Quick Actions Section ── */}
      <section className="operational-actions-section gsap-reveal">
        <div className="operational-actions-header">
          <div className="action-bar-label-group">
            <Zap size={14} className="action-zap-icon" />
            <span className="action-bar-title">Aksi Cepat Operasional</span>
          </div>
          <span className="action-bar-pill">Pintasan Kasir & Toko</span>
        </div>

        <div className="operational-actions-grid">
          <button
            type="button"
            onClick={() => onNavigateTab('pos')}
            className="action-card-btn primary-action"
            title="Buka Kasir POS untuk melayani transaksi"
          >
            <div className="action-card-icon green">
              <Store size={17} />
            </div>
            <div className="action-card-text">
              <span className="action-card-title">+ Transaksi Kasir</span>
              <span className="action-card-desc">Buka POS Kasir (F2)</span>
            </div>
            <ChevronRight size={14} className="action-card-arrow" />
          </button>

          <button
            type="button"
            onClick={() => setIsRestockModalOpen(true)}
            className="action-card-btn"
            title="Catat bahan baku masuk ke inventaris"
          >
            <div className="action-card-icon blue">
              <Package size={17} />
            </div>
            <div className="action-card-text">
              <span className="action-card-title">+ Restock Bahan</span>
              <span className="action-card-desc">Input stok masuk</span>
            </div>
            <ChevronRight size={14} className="action-card-arrow" />
          </button>

          <button
            type="button"
            onClick={() => setIsTransactionModalOpen(true)}
            className="action-card-btn"
            title="Catat pengeluaran kas atau biaya operasional"
          >
            <div className="action-card-icon amber">
              <Receipt size={17} />
            </div>
            <div className="action-card-text">
              <span className="action-card-title">Catat Kas Keluar</span>
              <span className="action-card-desc">Beban & kulakan</span>
            </div>
            <ChevronRight size={14} className="action-card-arrow" />
          </button>

          <button
            type="button"
            onClick={() => setIsMoreMenuOpen(true)}
            className="action-card-btn"
            title="Buka manajemen meja, diskon, dan shift kasir"
          >
            <div className="action-card-icon slate">
              <Grid size={17} />
            </div>
            <div className="action-card-text">
              <span className="action-card-title">Menu & Layanan</span>
              <span className="action-card-desc">Meja, diskon & shift</span>
            </div>
            <ChevronRight size={14} className="action-card-arrow" />
          </button>
        </div>
      </section>

      {/* ── 4. Main 2-Column Dashboard Layout ── */}
      <div className="home-grid">
        {/* Left Column (64%): Web Sales Chart & Smart AI Advisory */}
        <div className="home-left-col">
          {/* Sales Analytics Chart (Modern Web SaaS Chart) */}
          <div className="gsap-reveal">
            <SalesAnalyticsChart
              title="Tren Penjualan & Arus Kas"
              subtitle="Perbandingan omzet harian vs pengeluaran kulakan real-time"
            />
          </div>

          {/* AI Executive Advisory Card */}
          <div className="card-base ai-briefing-card gsap-reveal">
            <div className="ai-briefing-header">
              <div className="ai-brand-group">
                <div className="ai-avatar-icon">
                  <Sparkles size={16} />
                </div>
                <div>
                  <span className="ai-card-title">Briefing Harian AIsistenku</span>
                  <span className="ai-card-subtitle">Asisten Cerdas Operasional Kafe</span>
                </div>
              </div>
              <span className="ai-live-badge">
                <span className="pulsing-dot-emerald"></span>
                AI Active
              </span>
            </div>

            <p className="ai-briefing-text">{insight}</p>

            <div className="ai-briefing-actions">
              <button
                type="button"
                onClick={() => onNavigateTab('stock')}
                className="btn-ai-action-primary"
              >
                <span>Cek Stok Bahan</span>
                <ChevronRight size={14} />
              </button>

              <button
                type="button"
                onClick={() => onNavigateTab('ai')}
                className="btn-ai-action-secondary"
              >
                <Sparkles size={14} />
                <span>Konsultasi AIsistenku</span>
              </button>
            </div>
          </div>
        </div>

        {/* Right Column (36%): Inventory Health & Live Orders */}
        <div className="home-right-col">
          {/* Stock Alerts & Inventory Health */}
          <div className="card-base stock-alerts-panel gsap-reveal">
            <div className="panel-header-row">
              <div className="panel-title-wrap">
                <span className="panel-title">Kesehatan Inventaris</span>
                {stockAlerts.length > 0 ? (
                  <span className="badge badge-danger">{stockAlerts.length} Bahan Menipis</span>
                ) : (
                  <span className="badge badge-green">Stok Optimal</span>
                )}
              </div>
              <button
                type="button"
                onClick={() => onNavigateTab('stock')}
                className="btn-link-action"
              >
                Kelola Stok
              </button>
            </div>

            <div className="stock-alerts-list">
              {stockAlerts.length === 0 ? (
                <div className="stock-safe-card">
                  <div className="stock-safe-badge">
                    <CheckCircle2 size={18} />
                    <span>Seluruh Bahan Baku Aman</span>
                  </div>
                  <p className="stock-safe-description">
                    Semua stok bahan baku kopi, susu, sirup, dan kemasan berada dalam batas aman
                    siap melayani transaksi kasir.
                  </p>
                  <div className="stock-safe-meta-row">
                    <span className="stock-safe-pill">
                      <strong>{products.length || 7}</strong> SKU Aktif
                    </span>
                    <span className="stock-safe-pill success">
                      <strong>100%</strong> Siap Saji
                    </span>
                  </div>
                </div>
              ) : (
                stockAlerts.slice(0, 3).map((alert) => {
                  const capacityPercent = Math.min(
                    100,
                    Math.round((alert.currentStock / Math.max(alert.minStock * 2, 1)) * 100)
                  );
                  const isCritical = alert.currentStock <= alert.minStock;

                  return (
                    <div key={alert.id} className="stock-item-card">
                      <div className="stock-item-info">
                        <div className="stock-item-name-row">
                          <span className="stock-name">{alert.productName}</span>
                          <span
                            className={`stock-capacity-tag ${isCritical ? 'critical' : 'warning'}`}
                          >
                            {capacityPercent}% sisa
                          </span>
                        </div>
                        <span className="stock-meta">
                          Tersisa:{' '}
                          <strong>
                            {alert.currentStock} {alert.unit}
                          </strong>{' '}
                          (Min: {alert.minStock} {alert.unit})
                        </span>

                        {/* Capacity Progress Bar */}
                        <div className="capacity-bar-track">
                          <div
                            className={`capacity-bar-fill ${isCritical ? 'critical' : 'warning'}`}
                            style={{ width: `${Math.max(capacityPercent, 8)}%` }}
                          ></div>
                        </div>
                      </div>

                      <button
                        type="button"
                        onClick={() => setIsRestockModalOpen(true)}
                        className="btn-quick-restock"
                        title="Restock Bahan"
                      >
                        <Plus size={13} />
                        <span>Restock</span>
                      </button>
                    </div>
                  );
                })
              )}
            </div>

            <button type="button" onClick={() => onNavigateTab('stock')} className="btn-full-ghost">
              <span>Lihat Detail Semua Bahan Baku</span>
              <ChevronRight size={14} />
            </button>
          </div>

          {/* Recent Orders / Live Transactions Feed */}
          <div className="card-base recent-tx-panel gsap-reveal">
            <div className="panel-header-row">
              <div className="panel-title-wrap">
                <span className="pulsing-dot-green"></span>
                <span className="panel-title">Transaksi Kasir Terkini</span>
              </div>
              <button
                type="button"
                onClick={() => onNavigateTab('finance')}
                className="btn-link-action"
              >
                Lihat Semua
              </button>
            </div>

            <div className="recent-tx-list">
              {displayTransactions.map((tx, idx) => {
                const isIncome = tx.type === 'sale' || tx.type === 'income';

                return (
                  <div
                    key={tx.id || idx}
                    className="recent-tx-row"
                    onClick={() => setSelectedTxForDetail(tx)}
                    role="button"
                    tabIndex={0}
                  >
                    <div className={`tx-icon-pill ${isIncome ? 'income' : 'expense'}`}>
                      {isIncome ? <ArrowDownRight size={16} /> : <ArrowUpRight size={16} />}
                    </div>

                    <div className="tx-info-block">
                      <span className="tx-title">
                        {tx.title || tx.invoiceNo || 'Penjualan Kasir'}
                      </span>
                      <div className="tx-meta-row">
                        <span className="tx-category-badge">
                          {tx.category === 'refund' ? 'Retur/Refund' : tx.category}
                        </span>
                        <span className="meta-bullet">•</span>
                        <span>{tx.time || '12:00'} WIB</span>
                        {tx.paymentMethod && (
                          <>
                            <span className="meta-bullet">•</span>
                            <span className="tx-payment-method">
                              {tx.paymentMethod.toUpperCase()}
                            </span>
                          </>
                        )}
                      </div>
                    </div>

                    <div className="tx-amount-block">
                      <span className={`tx-amount ${isIncome ? 'income' : 'expense'}`}>
                        {isIncome ? '+' : '-'}
                        {formatRupiah(tx.amount)}
                      </span>
                      <span className={`tx-status-pill ${isIncome ? 'success' : 'expense'}`}>
                        {isIncome ? 'Lunas' : 'Pengeluaran'}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>

            <button
              type="button"
              onClick={() => onNavigateTab('finance')}
              className="btn-full-ghost"
            >
              <span>Buka Buku Kas & Laporan Harian</span>
              <ChevronRight size={14} />
            </button>
          </div>
        </div>
      </div>

      {/* ── Modals Integrated with Real Backend Action Triggers ── */}
      <QuickRestockModal
        isOpen={isRestockModalOpen}
        onClose={() => setIsRestockModalOpen(false)}
        products={products}
        onRestock={async (stockId, payload) => {
          if (onRestock) {
            await onRestock(stockId, payload);
          }
        }}
      />

      <QuickTransactionModal
        isOpen={isTransactionModalOpen}
        onClose={() => setIsTransactionModalOpen(false)}
        onCreate={async (payload) => {
          if (onCreateTransaction) {
            await onCreateTransaction(payload);
          }
        }}
      />

      <MoreMenuModal
        isOpen={isMoreMenuOpen}
        onClose={() => setIsMoreMenuOpen(false)}
        onNavigateTab={onNavigateTab}
      />

      <NotificationModal
        isOpen={isNotificationOpen}
        onClose={() => setIsNotificationOpen(false)}
        stockAlerts={stockAlerts}
        onNavigateTab={onNavigateTab}
      />

      <TransactionDetailModal
        isOpen={selectedTxForDetail !== null}
        onClose={() => setSelectedTxForDetail(null)}
        transaction={selectedTxForDetail}
      />
    </div>
  );
};

export default HomeScreen;
