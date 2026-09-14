import React, { useState, useEffect, useRef, useMemo } from 'react';
import { createPortal } from 'react-dom';
import { Transaction } from '../types';
import {
  Wallet,
  TrendingUp,
  TrendingDown,
  Plus,
  X,
  Save,
  Loader2,
  Check,
  CreditCard,
  Banknote,
  QrCode,
  Tag,
  DollarSign,
  Search,
  ArrowUpDown,
  Copy,
  Sparkles,
  ShoppingBag,
  Receipt,
  FileText,
  Building2,
  Layers,
  ArrowDownRight,
  ArrowUpRight,
  ChevronDown,
} from 'lucide-react';
import { animateScreenEntrance } from '../lib/animations';
import { SalesAnalyticsChart } from '../components/charts/SalesAnalyticsChart';
import { Pagination } from '../components/common/Pagination';
import './FinanceScreen.css';

interface FinanceScreenProps {
  transactions: Transaction[];
  loading: boolean;
  onCreate: (body: {
    title: string;
    type: 'INCOME' | 'EXPENSE';
    category: string;
    amount: number;
    notes?: string;
    paymentMethod?: string;
  }) => Promise<void>;
  onRefresh: () => Promise<void>;
}

export const FinanceScreen: React.FC<FinanceScreenProps> = ({
  transactions,
  loading,
  onCreate,
  onRefresh,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    animateScreenEntrance(containerRef.current);
  }, []);

  // Filter & Search states
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [filterType, setFilterType] = useState<'all' | 'sale' | 'expense'>('all');
  const [selectedCategory, setSelectedCategory] = useState<string>('Semua');
  const [sortBy, setSortBy] = useState<'date-desc' | 'date-asc' | 'amount-desc' | 'amount-asc'>('date-desc');
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [copiedInvoice, setCopiedInvoice] = useState<string | null>(null);
  const pageSize = 7;

  // Add Transaction Modal state
  const [isAddModalOpen, setIsAddModalOpen] = useState<boolean>(false);
  const [txType, setTxType] = useState<'sale' | 'expense'>('expense');

  // Dynamic categories for Finance
  const defaultExpenseCategories = [
    'Kulakan Bahan Baku',
    'Listrik, Air & WiFi',
    'Gaji Karyawan',
    'Sewa Tempat',
    'Perawatan Alat',
    'Promosi & Marketing',
    'Peralatan & Kemasan',
    'Lain-lain',
  ];
  const defaultIncomeCategories = [
    'Pendapatan Kasir POS',
    'Penjualan Catering / Event',
    'Pendapatan Konsinyasi',
    'Pendapatan Lainnya',
  ];

  const [expenseCategories, setExpenseCategories] = useState<string[]>(defaultExpenseCategories);
  const [incomeCategories, setIncomeCategories] = useState<string[]>(defaultIncomeCategories);

  const [isAddingCategory, setIsAddingCategory] = useState<boolean>(false);
  const [newCategoryInput, setNewCategoryInput] = useState<string>('');

  const [category, setCategory] = useState<string>('Kulakan Bahan Baku');
  const [amount, setAmount] = useState<string>('');
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'transfer' | 'qris'>('cash');
  const [notes, setNotes] = useState<string>('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const quickAmounts = [50000, 100000, 250000, 500000, 1000000, 2000000];

  // Financial totals calculation
  const totalIncome = useMemo(() => {
    return transactions
      .filter((t) => t.type === 'sale' || t.type === 'income')
      .reduce((s, t) => s + t.amount, 0);
  }, [transactions]);

  const totalExpense = useMemo(() => {
    return transactions
      .filter((t) => t.type === 'expense')
      .reduce((s, t) => s + t.amount, 0);
  }, [transactions]);

  const netProfit = totalIncome - totalExpense;
  const profitMarginPercent = totalIncome > 0 ? ((netProfit / totalIncome) * 100).toFixed(1) : '0';
  const expenseRatioPercent = totalIncome > 0 ? ((totalExpense / totalIncome) * 100).toFixed(1) : '0';

  // Available unique categories from active transactions
  const presentCategories = useMemo(() => {
    const cats = Array.from(new Set(transactions.map((t) => t.category).filter(Boolean)));
    return ['Semua', ...cats];
  }, [transactions]);

  // Filtered and sorted transactions
  const filtered = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();

    return transactions
      .filter((t) => {
        // Type filter
        if (filterType === 'sale' && t.type !== 'sale' && t.type !== 'income') return false;
        if (filterType === 'expense' && t.type !== 'expense') return false;

        // Category filter
        if (selectedCategory !== 'Semua' && t.category !== selectedCategory) return false;

        // Search query
        if (q) {
          const matchInv = t.invoiceNo?.toLowerCase().includes(q);
          const matchCat = t.category?.toLowerCase().includes(q);
          const matchNotes = t.notes?.toLowerCase().includes(q);
          const matchTitle = t.title?.toLowerCase().includes(q);
          const matchMethod = t.paymentMethod?.toLowerCase().includes(q);
          if (!matchInv && !matchCat && !matchNotes && !matchTitle && !matchMethod) return false;
        }

        return true;
      })
      .sort((a, b) => {
        if (sortBy === 'amount-desc') return b.amount - a.amount;
        if (sortBy === 'amount-asc') return a.amount - b.amount;
        // Date sorting fallback
        const timeA = new Date(a.date).getTime() || 0;
        const timeB = new Date(b.date).getTime() || 0;
        if (sortBy === 'date-asc') return timeA - timeB;
        return timeB - timeA; // date-desc default
      });
  }, [transactions, filterType, selectedCategory, searchQuery, sortBy]);

  const totalPages = Math.ceil(filtered.length / pageSize) || 1;
  const paginatedTransactions = useMemo(() => {
    return filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);
  }, [filtered, currentPage, pageSize]);

  // Handlers
  const handleFilterChange = (type: 'all' | 'sale' | 'expense') => {
    setFilterType(type);
    setCurrentPage(1);
  };

  const handleCopyInvoice = (code?: string) => {
    if (!code) return;
    navigator.clipboard?.writeText(code);
    setCopiedInvoice(code);
    setTimeout(() => setCopiedInvoice(null), 1800);
  };

  const handleOpenAddModal = () => {
    setError(null);
    setTxType('expense');
    setCategory(expenseCategories[0]);
    setAmount('');
    setPaymentMethod('cash');
    setNotes('');
    setIsAddingCategory(false);
    setIsAddModalOpen(true);
  };

  const handleSave = async () => {
    const num = parseFloat(amount.replace(/[^0-9]/g, ''));
    if (!num || num <= 0) {
      setError('Nominal harus lebih dari Rp 0');
      return;
    }
    setError(null);
    setSaving(true);
    try {
      await onCreate({
        title: txType === 'expense' ? `Pengeluaran ${category}` : `Pemasukan ${category}`,
        type: txType === 'expense' ? 'EXPENSE' : 'INCOME',
        category: category,
        amount: num,
        notes: notes || undefined,
        paymentMethod: paymentMethod,
      });
      setIsAddModalOpen(false);
      setAmount('');
      setNotes('');
      await onRefresh();
    } catch (e: any) {
      setError(e?.error || 'Gagal menyimpan transaksi');
    } finally {
      setSaving(false);
    }
  };

  // Helper date formatter
  const formatTxDate = (dateStr?: string, timeStr?: string) => {
    if (!dateStr) return timeStr || '-';
    try {
      const d = new Date(dateStr);
      if (!isNaN(d.getTime())) {
        const formatted = d.toLocaleDateString('id-ID', {
          day: 'numeric',
          month: 'short',
          year: 'numeric',
        });
        return `${formatted} • ${timeStr || d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}`;
      }
    } catch {}
    return `${dateStr}${timeStr ? ` • ${timeStr}` : ''}`;
  };

  return (
    <div ref={containerRef} className="page-screen finance-screen-revamp">
      {/* ── 1. Top Executive Screen Header ── */}
      <header className="finance-header-wrap gsap-reveal">
        <div className="finance-header-info">
          <div className="finance-context-badge">
            <span className="live-pulse-dot"></span>
            <span className="context-text">Kedai Kopi Tiga Angkatan • Buku Kas &amp; Arus Kas</span>
          </div>
          <h1 className="finance-main-heading">Laporan &amp; Catatan Keuangan</h1>
          <p className="finance-main-desc">
            Pantau arus kas masuk dan keluar, analisis margin laba bersih toko, dan catat mutasi operasional secara akurat.
          </p>
        </div>

        <div className="finance-header-actions">
          <button
            type="button"
            onClick={handleOpenAddModal}
            className="btn-primary btn-finance-add"
            title="Catat Pemasukan atau Pengeluaran Baru"
          >
            <Plus size={16} />
            <span>Catat Transaksi Manual</span>
          </button>
        </div>
      </header>

      {/* ── 2. Executive Financial Command Board (Replaces 3 identical AI slop cards) ── */}
      <section className="finance-command-board gsap-reveal">
        {/* Left Card: Net Profit & Cash Flow Hero */}
        <div className="net-profit-hero-card">
          <div className="profit-hero-header">
            <div className="profit-hero-titles">
              <span className="profit-hero-eyebrow">LABA BERSIH OPERASIONAL (NET PROFIT)</span>
              <div className="profit-hero-amount-row">
                <span className="currency-prefix">Rp</span>
                <span className={`profit-hero-number ${netProfit >= 0 ? 'text-emerald' : 'text-danger'}`}>
                  {netProfit.toLocaleString('id-ID')}
                </span>
                <span className={`profit-margin-pill ${netProfit >= 0 ? 'positive' : 'negative'}`}>
                  {netProfit >= 0 ? <ArrowUpRight size={13} /> : <ArrowDownRight size={13} />}
                  <span>{profitMarginPercent}% Margin</span>
                </span>
              </div>
            </div>
            <div className="profit-hero-icon-badge">
              <Wallet size={22} />
            </div>
          </div>

          <div className="profit-hero-breakdown">
            <div className="breakdown-stat-item">
              <span className="stat-label">Total Pemasukan (Omzet)</span>
              <span className="stat-value text-emerald">+ Rp {totalIncome.toLocaleString('id-ID')}</span>
              <span className="stat-sub">POS Kasir &amp; Pemasukan Lain</span>
            </div>

            <div className="breakdown-stat-divider"></div>

            <div className="breakdown-stat-item">
              <span className="stat-label">Total Beban &amp; Kulakan</span>
              <span className="stat-value text-coral">- Rp {totalExpense.toLocaleString('id-ID')}</span>
              <span className="stat-sub">Bahan baku, listrik &amp; gaji</span>
            </div>

            <div className="breakdown-stat-divider"></div>

            <div className="breakdown-stat-item">
              <span className="stat-label">Rasio Beban Toko</span>
              <span className="stat-value">{expenseRatioPercent}%</span>
              <span className="stat-sub">Dari total omzet masuk</span>
            </div>
          </div>
        </div>

        {/* Right Card: AIsistenku Financial Intelligence & Filter Controller */}
        <div className="ai-finance-widget-card">
          <div className="ai-widget-header">
            <div className="ai-widget-brand">
              <div className="ai-bot-avatar-wrap">
                <img src="/iconAisistenku.png" alt="AIsistenku" className="ai-avatar-mini" />
              </div>
              <div className="ai-widget-titles">
                <span className="ai-widget-name">AIsistenku Copilot</span>
                <span className="ai-widget-sub">Audit Margin &amp; Efisiensi Toko</span>
              </div>
            </div>
            <span className="ai-live-tag">
              <Sparkles size={12} />
              <span>Real-time</span>
            </span>
          </div>

          <div className="ai-widget-message-box">
            {parseFloat(expenseRatioPercent) > 85 ? (
              <p className="ai-widget-text danger">
                <strong>⚠️ Beban Operasional Tinggi:</strong> Beban toko menyerap {expenseRatioPercent}% dari total omzet. Disarankan audit kulakan bahan baku dan kurangi pos biaya non-esensial.
              </p>
            ) : netProfit > 0 ? (
              <p className="ai-widget-text success">
                <strong>✨ Kinerja Keuangan Sehat:</strong> Margin laba bersih berada di {profitMarginPercent}%. Surplus arus kas aman untuk cadangan kulakan bahan minggu depan.
              </p>
            ) : (
              <p className="ai-widget-text warning">
                <strong>ℹ️ Pantauan Arus Kas:</strong> Total pengeluaran saat ini mendekati pemasukan. Pastikan seluruh transaksi kasir shift tercatat lunas di sistem.
              </p>
            )}
          </div>

          {/* Interactive Filter Controller Pills */}
          <div className="ai-status-filter-pills">
            <button
              type="button"
              onClick={() => handleFilterChange('all')}
              className={`status-pill-btn ${filterType === 'all' ? 'active' : ''}`}
            >
              Semua Mutasi ({transactions.length})
            </button>
            <button
              type="button"
              onClick={() => handleFilterChange('sale')}
              className={`status-pill-btn pill-income ${filterType === 'sale' ? 'active' : ''}`}
            >
              <span className="pill-dot green"></span>
              Pemasukan ({transactions.filter((t) => t.type === 'sale' || t.type === 'income').length})
            </button>
            <button
              type="button"
              onClick={() => handleFilterChange('expense')}
              className={`status-pill-btn pill-expense ${filterType === 'expense' ? 'active' : ''}`}
            >
              <span className="pill-dot red"></span>
              Pengeluaran ({transactions.filter((t) => t.type === 'expense').length})
            </button>
          </div>
        </div>
      </section>

      {/* ── 3. High-Resolution Sales Analytics Chart ── */}
      <section className="finance-chart-section gsap-reveal">
        <SalesAnalyticsChart
          title="Grafik Penjualan &amp; Arus Kas"
          subtitle="Analisis perbandingan omzet penjualan vs pengeluaran operasional toko"
        />
      </section>

      {/* ── 4. Transactions Control Panel & Toolbar ── */}
      <section className="finance-control-panel card-base gsap-reveal">
        <div className="panel-primary-row">
          {/* Search Input */}
          <div className="search-field-wrapper">
            <Search size={16} className="search-field-icon" />
            <input
              ref={searchInputRef}
              type="text"
              placeholder="Cari no referensi, kategori, catatan, metode bayar (Ctrl+K)..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setCurrentPage(1);
              }}
              className="finance-clean-search-input"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => {
                  setSearchQuery('');
                  setCurrentPage(1);
                }}
                className="btn-clear-search-clean"
                title="Hapus pencarian"
              >
                <X size={14} />
              </button>
            )}
          </div>

          {/* Aux Controls: Category & Sort */}
          <div className="panel-aux-controls">
            {/* Category Dropdown */}
            <div className="filter-select-box">
              <Tag size={13} className="filter-select-icon" />
              <select
                value={selectedCategory}
                onChange={(e) => {
                  setSelectedCategory(e.target.value);
                  setCurrentPage(1);
                }}
                className="finance-filter-dropdown"
              >
                {presentCategories.map((c) => (
                  <option key={c} value={c}>
                    {c === 'Semua' ? 'Semua Kategori' : c}
                  </option>
                ))}
              </select>
            </div>

            {/* Sort Selector */}
            <div className="filter-select-box">
              <ArrowUpDown size={13} className="filter-select-icon" />
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as any)}
                className="finance-filter-dropdown"
              >
                <option value="date-desc">Terbaru Lebih Dulu</option>
                <option value="date-asc">Terlama Lebih Dulu</option>
                <option value="amount-desc">Nominal Terbesar</option>
                <option value="amount-asc">Nominal Terkecil</option>
              </select>
            </div>
          </div>
        </div>
      </section>

      {/* ── 5. High-Craft Transaction History Table ── */}
      <section className="finance-table-wrapper card-base gsap-reveal">
        <div className="table-responsive">
          <table className="finance-table-grid">
            <thead>
              <tr>
                <th style={{ width: '28%' }}>No. Referensi &amp; Waktu</th>
                <th style={{ width: '20%' }}>Tipe &amp; Kategori</th>
                <th style={{ width: '15%' }}>Metode Bayar</th>
                <th style={{ width: '22%' }}>Keterangan / Catatan</th>
                <th style={{ width: '15%', textAlign: 'right' }}>Nominal (Rp)</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={5}>
                    <div className="table-state-box">
                      <Loader2 size={24} className="spin text-emerald" />
                      <span>Memuat catatan arus kas dari server...</span>
                    </div>
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={5}>
                    <div className="table-state-box empty">
                      <div className="empty-icon-circle">
                        <Receipt size={28} />
                      </div>
                      <h4 className="empty-title">Tidak ada transaksi yang cocok</h4>
                      <p className="empty-desc">
                        Sesuaikan kata kunci pencarian atau reset filter tipe dan kategori.
                      </p>
                      <button
                        type="button"
                        onClick={() => {
                          setSearchQuery('');
                          setFilterType('all');
                          setSelectedCategory('Semua');
                        }}
                        className="btn-secondary btn-sm"
                      >
                        Reset Semua Filter
                      </button>
                    </div>
                  </td>
                </tr>
              ) : (
                paginatedTransactions.map((tx) => {
                  const isExpense = tx.type === 'expense';
                  const isQris = (tx.paymentMethod || '').toLowerCase().includes('qris');
                  const isTransfer = (tx.paymentMethod || '').toLowerCase().includes('transfer');

                  return (
                    <tr key={tx.id} className="finance-row">
                      {/* 1. Reference & Date */}
                      <td>
                        <div className="tx-ref-cell">
                          <div className={`tx-icon-square ${isExpense ? 'expense' : 'income'}`}>
                            {isExpense ? <TrendingDown size={17} /> : <TrendingUp size={17} />}
                          </div>

                          <div className="tx-ref-details">
                            <div className="tx-invoice-row">
                              <span className="tx-invoice-mono">{tx.invoiceNo || 'INV-MANUAL'}</span>
                              <button
                                type="button"
                                onClick={() => handleCopyInvoice(tx.invoiceNo)}
                                className="btn-copy-invoice"
                                title="Salin Nomor Invoice"
                              >
                                {copiedInvoice === tx.invoiceNo ? (
                                  <Check size={11} className="text-emerald" />
                                ) : (
                                  <Copy size={11} />
                                )}
                              </button>
                            </div>
                            <span className="tx-timestamp">{formatTxDate(tx.date, tx.time)}</span>
                          </div>
                        </div>
                      </td>

                      {/* 2. Type & Category */}
                      <td>
                        <div className="tx-category-group">
                          <span className={`tx-type-tag ${isExpense ? 'expense' : 'income'}`}>
                            {isExpense ? 'Pengeluaran' : 'Pemasukan'}
                          </span>
                          <span className="tx-category-pill">{tx.category || 'Operasional'}</span>
                        </div>
                      </td>

                      {/* 3. Payment Method */}
                      <td>
                        <span className="tx-payment-method-chip">
                          {isQris ? (
                            <QrCode size={13} className="text-emerald" />
                          ) : isTransfer ? (
                            <CreditCard size={13} className="text-blue" />
                          ) : (
                            <Banknote size={13} className="text-amber" />
                          )}
                          <span>{(tx.paymentMethod || 'TUNAI').toUpperCase()}</span>
                        </span>
                      </td>

                      {/* 4. Notes / Description */}
                      <td>
                        <div className="tx-notes-cell" title={tx.notes || tx.title || ''}>
                          {tx.notes || tx.title || <span className="text-placeholder">-</span>}
                        </div>
                      </td>

                      {/* 5. Amount */}
                      <td style={{ textAlign: 'right' }}>
                        <span className={`tx-amount-bold ${isExpense ? 'expense' : 'income'}`}>
                          {isExpense ? '- ' : '+ '}Rp {tx.amount.toLocaleString('id-ID')}
                        </span>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Table Footer with Summary Info and Pagination */}
        <div className="table-footer-bar">
          <div className="table-footer-info">
            <span>
              Menampilkan{' '}
              <strong>
                {filtered.length === 0 ? 0 : (currentPage - 1) * pageSize + 1}-
                {Math.min(currentPage * pageSize, filtered.length)}
              </strong>{' '}
              dari <strong>{filtered.length}</strong> transaksi tercatat
            </span>
          </div>

          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            totalItems={filtered.length}
            pageSize={pageSize}
            onPageChange={setCurrentPage}
          />
        </div>
      </section>

      {/* ── MODAL: CATAT TRANSAKSI KEUANGAN MANUAL ── */}
      {isAddModalOpen &&
        createPortal(
          <div className="modal-overlay" onClick={() => setIsAddModalOpen(false)}>
            <div
              className="modal-card finance-revamp-modal animate-fade-in"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="modal-header">
                <div className="modal-title-wrap">
                  <div className={`modal-header-icon-box ${txType === 'expense' ? 'red' : 'green'}`}>
                    {txType === 'expense' ? <TrendingDown size={18} /> : <TrendingUp size={18} />}
                  </div>
                  <div>
                    <h3>Catat Transaksi Manual</h3>
                    <p className="modal-sub">Catat mutasi arus kas toko yang tidak melalui kasir POS</p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="btn-close"
                  title="Tutup Modal"
                >
                  <X size={18} />
                </button>
              </div>

              <div className="modal-body">
                {/* 1. Transaction Type Segmented Switcher */}
                <div className="tx-type-segmented-card">
                  <button
                    type="button"
                    onClick={() => {
                      setTxType('expense');
                      setCategory(expenseCategories[0]);
                    }}
                    className={`segmented-type-btn expense ${txType === 'expense' ? 'active' : ''}`}
                  >
                    <TrendingDown size={16} />
                    <span>Pengeluaran (Biaya)</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => {
                      setTxType('sale');
                      setCategory(incomeCategories[0]);
                    }}
                    className={`segmented-type-btn income ${txType === 'sale' ? 'active' : ''}`}
                  >
                    <TrendingUp size={16} />
                    <span>Pemasukan (Income)</span>
                  </button>
                </div>

                {/* 2. Amount Input & Quick Chips */}
                <div className="form-field-group" style={{ marginTop: 16 }}>
                  <label className="field-label">Nominal Transaksi (Rp) *</label>
                  <div className="amount-input-box">
                    <span className="amount-currency-label">Rp</span>
                    <input
                      type="number"
                      placeholder="0"
                      value={amount}
                      onChange={(e) => setAmount(e.target.value)}
                      className="field-input amount-large-input"
                      autoFocus
                      min="0"
                    />
                  </div>

                  {/* Quick Preset Nominal Chips */}
                  <div className="quick-amount-chips-row">
                    {quickAmounts.map((q) => (
                      <button
                        key={q}
                        type="button"
                        onClick={() => setAmount(String(q))}
                        className={`chip-quick-amount ${amount === String(q) ? 'active' : ''}`}
                      >
                        Rp {q >= 1000000 ? `${q / 1000000}Jt` : `${q / 1000}rb`}
                      </button>
                    ))}
                  </div>
                </div>

                {/* 3. Category Selector with Inline Add */}
                <div className="form-field-group" style={{ marginTop: 14 }}>
                  <div className="field-label-with-action">
                    <label className="field-label">Kategori Transaksi</label>
                    {!isAddingCategory && (
                      <button
                        type="button"
                        onClick={() => {
                          setIsAddingCategory(true);
                          setNewCategoryInput('');
                        }}
                        className="btn-inline-link"
                      >
                        + Kategori Baru
                      </button>
                    )}
                  </div>

                  {isAddingCategory ? (
                    <div className="inline-add-wrapper">
                      <input
                        type="text"
                        placeholder="Nama kategori transaksi baru..."
                        value={newCategoryInput}
                        onChange={(e) => setNewCategoryInput(e.target.value)}
                        className="field-input inline-field"
                        autoFocus
                      />
                      <button
                        type="button"
                        onClick={() => {
                          const trimmed = newCategoryInput.trim();
                          if (trimmed) {
                            if (txType === 'expense') {
                              if (!expenseCategories.includes(trimmed)) {
                                setExpenseCategories([...expenseCategories, trimmed]);
                              }
                            } else {
                              if (!incomeCategories.includes(trimmed)) {
                                setIncomeCategories([...incomeCategories, trimmed]);
                              }
                            }
                            setCategory(trimmed);
                            setIsAddingCategory(false);
                          }
                        }}
                        className="btn-inline-confirm"
                        title="Simpan Kategori"
                      >
                        <Check size={14} />
                      </button>
                      <button
                        type="button"
                        onClick={() => setIsAddingCategory(false)}
                        className="btn-inline-dismiss"
                      >
                        <X size={14} />
                      </button>
                    </div>
                  ) : (
                    <select
                      value={category}
                      onChange={(e) => {
                        if (e.target.value === '__add_new__') {
                          setIsAddingCategory(true);
                          setNewCategoryInput('');
                        } else {
                          setCategory(e.target.value);
                        }
                      }}
                      className="field-select"
                    >
                      {(txType === 'expense' ? expenseCategories : incomeCategories).map((cat) => (
                        <option key={cat} value={cat}>
                          {cat}
                        </option>
                      ))}
                      <option value="__add_new__">+ Tambah Kategori Baru...</option>
                    </select>
                  )}
                </div>

                {/* 4. Payment Method Selector */}
                <div className="form-field-group" style={{ marginTop: 14 }}>
                  <label className="field-label">Metode Pembayaran</label>
                  <div className="payment-method-selector-grid">
                    <button
                      type="button"
                      onClick={() => setPaymentMethod('cash')}
                      className={`payment-method-tile ${paymentMethod === 'cash' ? 'active' : ''}`}
                    >
                      <Banknote size={16} />
                      <span>Tunai (Cash)</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setPaymentMethod('transfer')}
                      className={`payment-method-tile ${paymentMethod === 'transfer' ? 'active' : ''}`}
                    >
                      <CreditCard size={16} />
                      <span>Transfer Bank</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setPaymentMethod('qris')}
                      className={`payment-method-tile ${paymentMethod === 'qris' ? 'active' : ''}`}
                    >
                      <QrCode size={16} />
                      <span>QRIS / Digital</span>
                    </button>
                  </div>
                </div>

                {/* 5. Notes / Description */}
                <div className="form-field-group" style={{ marginTop: 14 }}>
                  <label className="field-label">Keterangan / Catatan Tambahan (Opsional)</label>
                  <input
                    type="text"
                    placeholder="e.g. Pembelian susu fresh milk tambahan 5 botol"
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    className="field-input"
                  />
                </div>

                {error && <div className="modal-error-alert">{error}</div>}
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="btn-secondary"
                  disabled={saving}
                >
                  Batal
                </button>
                <button
                  type="button"
                  onClick={handleSave}
                  className="btn-primary"
                  disabled={saving}
                >
                  {saving ? (
                    <>
                      <Loader2 size={16} className="spin" />
                      <span>Menyimpan Transaksi…</span>
                    </>
                  ) : (
                    <>
                      <Save size={16} />
                      <span>Simpan Transaksi</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>,
          document.body
        )}
    </div>
  );
};

export default FinanceScreen;
