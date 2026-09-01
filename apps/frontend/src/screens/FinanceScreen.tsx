import React, { useState } from 'react';
import { Transaction } from '../types';
import { Wallet, TrendingUp, TrendingDown, Plus, X, Save, Loader2 } from 'lucide-react';
import './FinanceScreen.css';

interface FinanceScreenProps {
  transactions: Transaction[];
  loading: boolean;
  onCreate: (body: { title: string; type: 'INCOME' | 'EXPENSE'; category: string; amount: number; notes?: string }) => Promise<void>;
  onRefresh: () => Promise<void>;
}

export const FinanceScreen: React.FC<FinanceScreenProps> = ({ transactions, loading, onCreate, onRefresh }) => {
  const [filterType, setFilterType] = useState<'all' | 'sale' | 'expense'>('all');
  const [isAddModalOpen, setIsAddModalOpen] = useState<boolean>(false);
  const [txType, setTxType] = useState<'sale' | 'expense'>('expense');
  const [category, setCategory] = useState<string>('Kulakan Stok');
  const [amount, setAmount] = useState<string>('');
  const [notes, setNotes] = useState<string>('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const totalIncome = transactions.filter((t) => t.type === 'sale' || t.type === 'income').reduce((s, t) => s + t.amount, 0);
  const totalExpense = transactions.filter((t) => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
  const netProfit = totalIncome - totalExpense;

  const filtered = transactions.filter((t) => {
    if (filterType === 'all') return true;
    if (filterType === 'sale') return t.type === 'sale' || t.type === 'income';
    return t.type === 'expense';
  });

  const handleSave = async () => {
    const num = parseFloat(amount);
    if (!num || num <= 0) { setError('Nominal harus > 0'); return; }
    setError(null); setSaving(true);
    try {
      await onCreate({
        title: txType === 'expense' ? `Pengeluaran ${category}` : `Pemasukan ${category}`,
        type: txType === 'expense' ? 'EXPENSE' : 'INCOME',
        category: txType === 'expense' ? 'operational' : 'sales',
        amount: num,
        notes: notes || undefined,
      });
      setIsAddModalOpen(false);
      setAmount(''); setNotes('');
      await onRefresh();
    } catch (e: any) {
      setError(e?.error || 'Gagal menyimpan transaksi');
    } finally { setSaving(false); }
  };

  return (
    <div className="page-screen finance-screen-container animate-fade-in">
      <div className="screen-header">
        <div>
          <h1 className="screen-title">Laporan & Catatan Keuangan</h1>
          <p className="screen-sub">Data transaksi langsung dari database Supabase.</p>
        </div>
        <button onClick={() => setIsAddModalOpen(true)} className="btn-primary"><Plus size={16} /> Catat Transaksi Manual</button>
      </div>

      <div className="grid-responsive-3 finance-overview-grid">
        <div className="card-base overview-card">
          <div className="overview-header">
            <span className="overview-label">TOTAL PEMASUKAN</span>
            <div className="overview-icon teal"><TrendingUp size={20} /></div>
          </div>
          <h2 className="overview-value teal-text">Rp {totalIncome.toLocaleString('id-ID')}</h2>
          <span className="overview-sub">Otomatis dari POS & pemasukan manual</span>
        </div>
        <div className="card-base overview-card">
          <div className="overview-header">
            <span className="overview-label">TOTAL PENGELUARAN</span>
            <div className="overview-icon red"><TrendingDown size={20} /></div>
          </div>
          <h2 className="overview-value red-text">Rp {totalExpense.toLocaleString('id-ID')}</h2>
          <span className="overview-sub">Kulakan stok, listrik, operasional</span>
        </div>
        <div className="card-base overview-card highlight">
          <div className="overview-header">
            <span className="overview-label">LABA BERSIH</span>
            <div className="overview-icon gold"><Wallet size={20} /></div>
          </div>
          <h2 className="overview-value dark-text">Rp {netProfit.toLocaleString('id-ID')}</h2>
          <span className="overview-sub">Pemasukan dikurangi pengeluaran</span>
        </div>
      </div>

      <div className="card-base tx-history-card">
        <div className="tx-history-header">
          <h3>Riwayat Arus Kas & Transaksi</h3>
          <div className="filter-tab-group">
            <button onClick={() => setFilterType('all')} className={`filter-btn ${filterType === 'all' ? 'active' : ''}`}>Semua ({transactions.length})</button>
            <button onClick={() => setFilterType('sale')} className={`filter-btn ${filterType === 'sale' ? 'active' : ''}`}>Pemasukan</button>
            <button onClick={() => setFilterType('expense')} className={`filter-btn ${filterType === 'expense' ? 'active' : ''}`}>Pengeluaran</button>
          </div>
        </div>

        <div className="table-responsive">
          <table className="stock-table">
            <thead>
              <tr><th>No. Referensi</th><th>Tanggal & Waktu</th><th>Kategori</th><th>Metode</th><th>Catatan</th><th>Jumlah (Rp)</th></tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={6} className="empty-state-small">Memuat dari server...</td></tr>
              ) : filtered.length === 0 ? (
                <tr><td colSpan={6} className="empty-state-small">Belum ada transaksi.</td></tr>
              ) : filtered.map((tx) => {
                const isExpense = tx.type === 'expense';
                return (
                  <tr key={tx.id}>
                    <td className="sku-cell">{tx.invoiceNo}</td>
                    <td>{tx.date} • {tx.time}</td>
                    <td><span className="badge badge-teal">{tx.category}</span></td>
                    <td><span className="method-tag">{tx.paymentMethod.toUpperCase()}</span></td>
                    <td className="notes-cell">{tx.notes || '-'}</td>
                    <td className={`amount-cell ${isExpense ? 'expense-text' : 'income-text'}`}>
                      {isExpense ? '-' : '+'} Rp {tx.amount.toLocaleString('id-ID')}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {isAddModalOpen && (
        <div className="modal-overlay">
          <div className="modal-card animate-fade-in">
            <div className="modal-header">
              <h3>Catat Transaksi Keuangan</h3>
              <button onClick={() => setIsAddModalOpen(false)} className="btn-close"><X size={18} /></button>
            </div>
            <div className="modal-body">
              <label className="section-label">Jenis Transaksi:</label>
              <div className="method-grid">
                <button onClick={() => { setTxType('expense'); setCategory('Kulakan Stok'); }} className={`method-card ${txType === 'expense' ? 'active' : ''}`}>
                  <TrendingDown size={20} color="#EF4444" /><span>Pengeluaran</span>
                </button>
                <button onClick={() => { setTxType('sale'); setCategory('Pendapatan Kasir'); }} className={`method-card ${txType === 'sale' ? 'active' : ''}`}>
                  <TrendingUp size={20} color="#10B981" /><span>Pemasukan</span>
                </button>
              </div>

              <div className="cash-input-group margin-top">
                <label>Kategori:</label>
                <select value={category} onChange={(e) => setCategory(e.target.value)} className="cash-input">
                  {txType === 'expense' ? (
                    <><option>Kulakan Stok</option><option>Listrik & WiFi</option><option>Gaji Karyawan</option><option>Sewa Tempat</option><option>Lain-lain</option></>
                  ) : (
                    <><option>Pendapatan Kasir</option><option>Pendapatan Lainnya</option></>
                  )}
                </select>
              </div>

              <div className="cash-input-group margin-top">
                <label>Jumlah Nominal (Rp):</label>
                <input type="number" placeholder="Contoh: 150000" value={amount} onChange={(e) => setAmount(e.target.value)} className="cash-input" />
              </div>

              <div className="cash-input-group margin-top">
                <label>Catatan:</label>
                <input type="text" placeholder="Keterangan singkat..." value={notes} onChange={(e) => setNotes(e.target.value)} className="cash-input" />
              </div>

              {error && <div className="login-error" style={{ marginTop: '0.75rem' }}>{error}</div>}
            </div>
            <div className="modal-footer">
              <button onClick={() => setIsAddModalOpen(false)} className="btn-secondary" disabled={saving}>Batal</button>
              <button onClick={handleSave} className="btn-primary" disabled={saving}>
                {saving ? <><Loader2 size={14} className="spin" /> Menyimpan...</> : <><Save size={14} /> Simpan</>}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default FinanceScreen;
