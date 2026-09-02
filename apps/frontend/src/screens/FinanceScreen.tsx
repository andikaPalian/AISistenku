import React, { useState, useEffect, useRef } from 'react';
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

export const FinanceScreen: React.FC<FinanceScreenProps> = ({ transactions, loading, onCreate, onRefresh }) => {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    animateScreenEntrance(containerRef.current);
  }, []);

  const [filterType, setFilterType] = useState<'all' | 'sale' | 'expense'>('all');
  const [currentPage, setCurrentPage] = useState<number>(1);
  const pageSize = 6;

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

  const totalIncome = transactions
    .filter((t) => t.type === 'sale' || t.type === 'income')
    .reduce((s, t) => s + t.amount, 0);
  const totalExpense = transactions
    .filter((t) => t.type === 'expense')
    .reduce((s, t) => s + t.amount, 0);
  const netProfit = totalIncome - totalExpense;

  const filtered = transactions.filter((t) => {
    if (filterType === 'all') return true;
    if (filterType === 'sale') return t.type === 'sale' || t.type === 'income';
    return t.type === 'expense';
  });

  const totalPages = Math.ceil(filtered.length / pageSize) || 1;
  const paginatedTransactions = filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);

  const handleFilterChange = (type: 'all' | 'sale' | 'expense') => {
    setFilterType(type);
    setCurrentPage(1);
  };

  const handleOpenAddModal = () => {
    setError(null);
    setTxType('expense');
    setCategory('Kulakan Bahan Baku');
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

  return (
    <div ref={containerRef} className="page-screen finance-screen-container">
      {/* ── Screen Header ── */}
      <div className="screen-header gsap-reveal">
        <div className="header-text-block">
          <h1 className="screen-title">Laporan &amp; Catatan Keuangan</h1>
          <p className="screen-sub">Ringkasan arus kas, laba bersih harian, dan mutasi pengeluaran operasional kafe.</p>
        </div>
        <button
          type="button"
          onClick={handleOpenAddModal}
          className="btn-primary"
          title="Catat Pemasukan atau Pengeluaran Baru"
        >
          <Plus size={16} />
          <span>Catat Transaksi Manual</span>
        </button>
      </div>

      {/* ── Key Financial Overview Cards ── */}
      <div className="grid-responsive-3 finance-overview-grid gsap-reveal">
        <div className="card-base overview-card">
          <div className="overview-header">
            <span className="overview-label">TOTAL PEMASUKAN</span>
            <div className="overview-icon teal">
              <TrendingUp size={20} />
            </div>
          </div>
          <h2 className="overview-value teal-text">Rp {totalIncome.toLocaleString('id-ID')}</h2>
          <span className="overview-sub">Akumulasi dari Kasir POS &amp; Pemasukan Manual</span>
        </div>

        <div className="card-base overview-card">
          <div className="overview-header">
            <span className="overview-label">TOTAL PENGELUARAN</span>
            <div className="overview-icon red">
              <TrendingDown size={20} />
            </div>
          </div>
          <h2 className="overview-value red-text">Rp {totalExpense.toLocaleString('id-ID')}</h2>
          <span className="overview-sub">Kulakan stok, listrik, WiFi, dan operasional</span>
        </div>

        <div className="card-base overview-card highlight">
          <div className="overview-header">
            <span className="overview-label">LABA BERSIH (NET PROFIT)</span>
            <div className="overview-icon gold">
              <Wallet size={20} />
            </div>
          </div>
          <h2 className="overview-value dark-text">Rp {netProfit.toLocaleString('id-ID')}</h2>
          <span className="overview-sub">Total pemasukan dikurangi pengeluaran toko</span>
        </div>
      </div>

      {/* ── Clean & Polished Sales & Cashflow Chart ── */}
      <div className="gsap-reveal" style={{ marginBottom: '24px' }}>
        <SalesAnalyticsChart
          title="Grafik Penjualan &amp; Arus Kas"
          subtitle="Analisis perbandingan omzet penjualan vs pengeluaran operasional toko"
        />
      </div>

      {/* ── Cash Flow & Transaction History Table ── */}
      <div className="card-base tx-history-card gsap-reveal">
        <div className="tx-history-header">
          <div>
            <h3>Riwayat Arus Kas &amp; Transaksi</h3>
            <p className="tx-history-sub">Daftar seluruh transaksi kasir dan mutasi operasional</p>
          </div>
          <div className="filter-tab-group">
            <button
              type="button"
              onClick={() => handleFilterChange('all')}
              className={`filter-btn ${filterType === 'all' ? 'active' : ''}`}
            >
              Semua ({transactions.length})
            </button>
            <button
              type="button"
              onClick={() => handleFilterChange('sale')}
              className={`filter-btn ${filterType === 'sale' ? 'active' : ''}`}
            >
              Pemasukan
            </button>
            <button
              type="button"
              onClick={() => handleFilterChange('expense')}
              className={`filter-btn ${filterType === 'expense' ? 'active' : ''}`}
            >
              Pengeluaran
            </button>
          </div>
        </div>

        <div className="table-responsive">
          <table className="stock-table">
            <thead>
              <tr>
                <th>No. Referensi</th>
                <th>Tanggal &amp; Waktu</th>
                <th>Kategori</th>
                <th>Metode Bayar</th>
                <th>Catatan</th>
                <th style={{ textAlign: 'right' }}>Jumlah (Rp)</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} className="empty-state-small">
                    Memuat data transaksi dari server...
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="empty-state-small">
                    Belum ada transaksi pada filter ini.
                  </td>
                </tr>
              ) : (
                paginatedTransactions.map((tx) => {
                  const isExpense = tx.type === 'expense';
                  return (
                    <tr key={tx.id}>
                      <td className="sku-cell">{tx.invoiceNo}</td>
                      <td>
                        {tx.date} • <span className="time-sub">{tx.time}</span>
                      </td>
                      <td>
                        <span className={`cat-chip-tag ${isExpense ? 'expense-tag' : 'income-tag'}`}>
                          {tx.category}
                        </span>
                      </td>
                      <td>
                        <span className="method-tag">{(tx.paymentMethod || 'TUNAI').toUpperCase()}</span>
                      </td>
                      <td className="notes-cell">{tx.notes || '-'}</td>
                      <td
                        style={{ textAlign: 'right' }}
                        className={`amount-cell ${isExpense ? 'expense-text' : 'income-text'}`}
                      >
                        {isExpense ? '- ' : '+ '}Rp {tx.amount.toLocaleString('id-ID')}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        <Pagination
          currentPage={currentPage}
          totalPages={totalPages}
          totalItems={filtered.length}
          pageSize={pageSize}
          onPageChange={setCurrentPage}
        />
      </div>

      {/* ── MODAL: CATAT TRANSAKSI KEUANGAN (PORTAL TO BODY FOR DEAD-CENTERING) ── */}
      {isAddModalOpen && createPortal(
        <div className="modal-overlay">
          <div className="modal-card finance-modal-card animate-fade-in">
            <div className="modal-header">
              <div className="modal-title-wrap">
                <Wallet size={20} className="text-teal" />
                <h3>Catat Transaksi Keuangan</h3>
              </div>
              <button onClick={() => setIsAddModalOpen(false)} className="btn-close">
                <X size={18} />
              </button>
            </div>

            <div className="modal-body">
              {/* Type Switcher */}
              <label className="section-label">Jenis Transaksi:</label>
              <div className="tx-type-grid">
                <button
                  type="button"
                  onClick={() => {
                    setTxType('expense');
                    setCategory(expenseCategories[0]);
                  }}
                  className={`tx-type-card expense ${txType === 'expense' ? 'active' : ''}`}
                >
                  <TrendingDown size={22} className="tx-type-icon red" />
                  <div>
                    <span className="tx-type-title">Pengeluaran (Biaya)</span>
                    <span className="tx-type-desc">Kulakan stok, gaji, listrik, dll.</span>
                  </div>
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setTxType('sale');
                    setCategory(incomeCategories[0]);
                  }}
                  className={`tx-type-card income ${txType === 'sale' ? 'active' : ''}`}
                >
                  <TrendingUp size={22} className="tx-type-icon green" />
                  <div>
                    <span className="tx-type-title">Pemasukan (Income)</span>
                    <span className="tx-type-desc">Penjualan event, katering, dll.</span>
                  </div>
                </button>
              </div>

              {/* Dynamic Category Selector */}
              <div className="form-group-item margin-top-md">
                <div className="label-with-action">
                  <label>Kategori Transaksi:</label>
                  {!isAddingCategory && (
                    <button
                      type="button"
                      onClick={() => {
                        setIsAddingCategory(true);
                        setNewCategoryInput('');
                      }}
                      className="btn-text-action"
                    >
                      <Plus size={12} /> Kategori Baru
                    </button>
                  )}
                </div>

                {isAddingCategory ? (
                  <div className="inline-add-group">
                    <input
                      type="text"
                      placeholder="Nama kategori transaksi baru..."
                      value={newCategoryInput}
                      onChange={(e) => setNewCategoryInput(e.target.value)}
                      className="modal-form-input inline-input"
                      autoFocus
                    />
                    <button
                      type="button"
                      onClick={() => {
                        if (newCategoryInput.trim()) {
                          const trimmed = newCategoryInput.trim();
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
                      className="btn-inline-save"
                      title="Simpan Kategori"
                    >
                      <Check size={14} />
                    </button>
                    <button
                      type="button"
                      onClick={() => setIsAddingCategory(false)}
                      className="btn-inline-cancel"
                      title="Batal"
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
                    className="modal-form-select"
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

              {/* Amount Input & Quick Chips */}
              <div className="form-group-item margin-top-md">
                <label>Jumlah Nominal (Rp) *</label>
                <input
                  type="number"
                  placeholder="Contoh: 150000"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="modal-form-input amount-big-input"
                />

                {/* Quick nominal chips */}
                <div className="quick-amount-pills">
                  {quickAmounts.map((q) => (
                    <button
                      key={q}
                      type="button"
                      onClick={() => setAmount(String(q))}
                      className={`quick-amount-btn ${amount === String(q) ? 'active' : ''}`}
                    >
                      Rp {q >= 1000000 ? `${q / 1000000}Jt` : `${q / 1000}rb`}
                    </button>
                  ))}
                </div>
              </div>

              {/* Payment Method Selector */}
              <div className="form-group-item margin-top-md">
                <label>Metode Pembayaran:</label>
                <div className="payment-method-chips">
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('cash')}
                    className={`pay-chip ${paymentMethod === 'cash' ? 'active' : ''}`}
                  >
                    <Banknote size={15} />
                    <span>Tunai (Cash)</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('transfer')}
                    className={`pay-chip ${paymentMethod === 'transfer' ? 'active' : ''}`}
                  >
                    <CreditCard size={15} />
                    <span>Transfer Bank</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('qris')}
                    className={`pay-chip ${paymentMethod === 'qris' ? 'active' : ''}`}
                  >
                    <QrCode size={15} />
                    <span>QRIS / Digital</span>
                  </button>
                </div>
              </div>

              {/* Notes */}
              <div className="form-group-item margin-top-md">
                <label>Keterangan / Catatan (Opsional):</label>
                <input
                  type="text"
                  placeholder="Keterangan transaksi, nota, atau supplier..."
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="modal-form-input"
                />
              </div>

              {error && <div className="pos-error-box">{error}</div>}
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
                    <span>Menyimpan...</span>
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

