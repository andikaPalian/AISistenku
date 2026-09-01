import React, { useState } from 'react';
import { Transaction } from '../types';
import { Wallet, TrendingUp, TrendingDown, Plus, Search, Filter, Calendar, ArrowUpRight, ArrowDownRight, X, Save } from 'lucide-react';
import './FinanceScreen.css';

interface FinanceScreenProps {
  transactions: Transaction[];
  onAddTransaction: (tx: Transaction) => void;
}

export const FinanceScreen: React.FC<FinanceScreenProps> = ({ transactions, onAddTransaction }) => {
  const [filterType, setFilterType] = useState<'all' | 'sale' | 'expense'>('all');
  const [isAddModalOpen, setIsAddModalOpen] = useState<boolean>(false);

  // Form state
  const [txType, setTxType] = useState<'sale' | 'expense'>('expense');
  const [category, setCategory] = useState<string>('Kulakan Stok');
  const [amount, setAmount] = useState<string>('');
  const [notes, setNotes] = useState<string>('');
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'transfer' | 'qris'>('cash');

  const totalIncome = transactions
    .filter((t) => t.type === 'sale' || t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);

  const totalExpense = transactions
    .filter((t) => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);

  const netProfit = totalIncome - totalExpense;

  const filteredTransactions = transactions.filter((t) => {
    if (filterType === 'all') return true;
    if (filterType === 'sale') return t.type === 'sale' || t.type === 'income';
    return t.type === 'expense';
  });

  const handleSaveTransaction = () => {
    const numAmount = parseFloat(amount);
    if (!numAmount || numAmount <= 0) return;

    const newTx: Transaction = {
      id: `tx-${Date.now()}`,
      invoiceNo: `${txType === 'sale' ? 'INV' : 'EXP'}/${new Date().getFullYear()}${String(new Date().getMonth() + 1).padStart(2, '0')}${String(new Date().getDate()).padStart(2, '0')}/${Math.floor(100 + Math.random() * 900)}`,
      date: new Date().toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }),
      time: new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
      type: txType,
      category,
      amount: numAmount,
      paymentMethod,
      status: 'success',
      notes
    };

    onAddTransaction(newTx);
    setIsAddModalOpen(false);
    setAmount('');
    setNotes('');
  };

  return (
    <div className="page-screen finance-screen-container animate-fade-in">
      {/* Header */}
      <div className="screen-header">
        <div>
          <h1 className="screen-title">Laporan & Catatan Keuangan</h1>
          <p className="screen-sub">Pantau omzet penjualan, pengeluaran operasional, dan laba bersih toko.</p>
        </div>
        <button onClick={() => setIsAddModalOpen(true)} className="btn-primary">
          <Plus size={16} />
          Catat Transaksi Manual
        </button>
      </div>

      {/* Finance Overview Cards */}
      <div className="grid-responsive-3 finance-overview-grid">
        <div className="card-base overview-card">
          <div className="overview-header">
            <span className="overview-label">TOTAL PEMASUKAN</span>
            <div className="overview-icon teal">
              <TrendingUp size={20} />
            </div>
          </div>
          <h2 className="overview-value teal-text">Rp {totalIncome.toLocaleString('id-ID')}</h2>
          <span className="overview-sub">Dari transaksi kasir & pemasukan lainnya</span>
        </div>

        <div className="card-base overview-card">
          <div className="overview-header">
            <span className="overview-label">TOTAL PENGELUARAN</span>
            <div className="overview-icon red">
              <TrendingDown size={20} />
            </div>
          </div>
          <h2 className="overview-value red-text">Rp {totalExpense.toLocaleString('id-ID')}</h2>
          <span className="overview-sub">Kulakan stok, listrik, & operasional</span>
        </div>

        <div className="card-base overview-card highlight">
          <div className="overview-header">
            <span className="overview-label">ESTIMASI LABA BERSIH</span>
            <div className="overview-icon gold">
              <Wallet size={20} />
            </div>
          </div>
          <h2 className="overview-value dark-text">Rp {netProfit.toLocaleString('id-ID')}</h2>
          <span className="overview-sub">Margin keuntungan terkumpul hari ini</span>
        </div>
      </div>

      {/* Visual Chart Graphic Section */}
      <div className="card-base chart-card">
        <div className="chart-header">
          <h3>Visualisasi Arus Kas (Hari Ini)</h3>
          <div className="chart-legend">
            <div className="legend-item"><span className="dot teal"></span> Pemasukan</div>
            <div className="legend-item"><span className="dot red"></span> Pengeluaran</div>
          </div>
        </div>

        <div className="chart-bar-container">
          <div className="chart-bar-group">
            <span className="bar-label">08:00 - 12:00</span>
            <div className="bar-wrapper">
              <div className="bar-fill teal" style={{ height: '65%' }}></div>
              <div className="bar-fill red" style={{ height: '35%' }}></div>
            </div>
          </div>

          <div className="chart-bar-group">
            <span className="bar-label">12:00 - 16:00</span>
            <div className="bar-wrapper">
              <div className="bar-fill teal" style={{ height: '85%' }}></div>
              <div className="bar-fill red" style={{ height: '20%' }}></div>
            </div>
          </div>

          <div className="chart-bar-group">
            <span className="bar-label">16:00 - 20:00</span>
            <div className="bar-wrapper">
              <div className="bar-fill teal" style={{ height: '45%' }}></div>
              <div className="bar-fill red" style={{ height: '10%' }}></div>
            </div>
          </div>
        </div>
      </div>

      {/* Transaction History Section */}
      <div className="card-base tx-history-card">
        <div className="tx-history-header">
          <h3>Riwayat Arus Kas & Transaksi</h3>
          <div className="filter-tab-group">
            <button
              onClick={() => setFilterType('all')}
              className={`filter-btn ${filterType === 'all' ? 'active' : ''}`}
            >
              Semua ({transactions.length})
            </button>
            <button
              onClick={() => setFilterType('sale')}
              className={`filter-btn ${filterType === 'sale' ? 'active' : ''}`}
            >
              Pemasukan
            </button>
            <button
              onClick={() => setFilterType('expense')}
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
                <th>Tanggal & Waktu</th>
                <th>Kategori</th>
                <th>Metode</th>
                <th>Catatan</th>
                <th>Jumlah (Rp)</th>
              </tr>
            </thead>
            <tbody>
              {filteredTransactions.map((tx) => {
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

      {/* Add Transaction Modal */}
      {isAddModalOpen && (
        <div className="modal-overlay">
          <div className="modal-card animate-fade-in">
            <div className="modal-header">
              <h3>Catat Transaksi Keuangan</h3>
              <button onClick={() => setIsAddModalOpen(false)} className="btn-close">
                <X size={18} />
              </button>
            </div>

            <div className="modal-body">
              <label className="section-label">Jenis Transaksi:</label>
              <div className="method-grid">
                <button
                  onClick={() => { setTxType('expense'); setCategory('Kulakan Stok'); }}
                  className={`method-card ${txType === 'expense' ? 'active' : ''}`}
                >
                  <ArrowDownRight size={20} color="#EF4444" />
                  <span>Pengeluaran (Biaya)</span>
                </button>
                <button
                  onClick={() => { setTxType('sale'); setCategory('Pendapatan Lainnya'); }}
                  className={`method-card ${txType === 'sale' ? 'active' : ''}`}
                >
                  <ArrowUpRight size={20} color="#10B981" />
                  <span>Pemasukan</span>
                </button>
              </div>

              <div className="cash-input-group margin-top">
                <label>Kategori Transaksi:</label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="cash-input"
                >
                  {txType === 'expense' ? (
                    <>
                      <option value="Kulakan Stok">Kulakan Stok Barang</option>
                      <option value="Listrik & WiFi">Listrik & Internet</option>
                      <option value="Gaji Karyawan">Gaji Karyawan</option>
                      <option value="Sewa Tempat">Sewa Tempat</option>
                      <option value="Lain-lain">Lain-lain</option>
                    </>
                  ) : (
                    <>
                      <option value="Pendapatan Kasir">Penjualan Kasir</option>
                      <option value="Pendapatan Lainnya">Pemasukan Tambahan</option>
                    </>
                  )}
                </select>
              </div>

              <div className="cash-input-group margin-top">
                <label>Jumlah Nominal (Rp):</label>
                <input
                  type="number"
                  placeholder="Contoh: 150000"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="cash-input"
                />
              </div>

              <div className="cash-input-group margin-top">
                <label>Catatan Keterangan:</label>
                <input
                  type="text"
                  placeholder="Keterangan singkat..."
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="cash-input"
                />
              </div>
            </div>

            <div className="modal-footer">
              <button onClick={() => setIsAddModalOpen(false)} className="btn-secondary">
                Batal
              </button>
              <button onClick={handleSaveTransaction} className="btn-primary">
                <Save size={14} />
                Simpan Transaksi
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
