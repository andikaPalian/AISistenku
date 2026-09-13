import React, { useState } from 'react';
import { X, Receipt, Check, Loader2, ArrowUpRight, ArrowDownRight } from 'lucide-react';

interface QuickTransactionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onCreate: (body: {
    title: string;
    type: 'INCOME' | 'EXPENSE';
    category: string;
    amount: number;
    notes?: string;
    paymentMethod?: string;
  }) => Promise<void>;
}

export const QuickTransactionModal: React.FC<QuickTransactionModalProps> = ({
  isOpen,
  onClose,
  onCreate,
}) => {
  if (!isOpen) return null;

  const [txType, setTxType] = useState<'EXPENSE' | 'INCOME'>('EXPENSE');
  const [title, setTitle] = useState<string>('Beli Es Batu & Kantong Plastik');
  const [category, setCategory] = useState<string>('Kulakan Bahan Baku');
  const [amount, setAmount] = useState<string>('50000');
  const [paymentMethod, setPaymentMethod] = useState<string>('cash');
  const [notes, setNotes] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [success, setSuccess] = useState<boolean>(false);

  const expenseCategories = [
    'Kulakan Bahan Baku',
    'Listrik, Air & WiFi',
    'Operasional & Kebersihan',
    'Peralatan & Kemasan',
    'Gaji Karyawan',
    'Lain-lain',
  ];

  const incomeCategories = [
    'Pendapatan Kasir POS',
    'Catering & Pesanan Khusus',
    'Pendapatan Konsinyasi',
    'Lain-lain',
  ];

  const quickAmounts = [20000, 50000, 100000, 250000, 500000];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const numAmount = Number(amount);
    if (!title.trim() || numAmount <= 0) return;

    setLoading(true);
    try {
      await onCreate({
        title,
        type: txType,
        category,
        amount: numAmount,
        notes,
        paymentMethod,
      });
      setSuccess(true);
      setTimeout(() => {
        setSuccess(false);
        onClose();
      }, 900);
    } catch (err) {
      console.error('Transaction create error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 480 }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: 10,
                backgroundColor: txType === 'EXPENSE' ? '#FEE2E2' : '#DCFCE7',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: txType === 'EXPENSE' ? '#DC2626' : '#16A34A',
              }}
            >
              <Receipt size={20} />
            </div>
            <div>
              <h3>Catat Kas Operasional</h3>
              <p style={{ fontSize: 12, color: '#64748B', marginTop: 1 }}>Pencatatan arus kas masuk & beban toko</p>
            </div>
          </div>
          <button type="button" onClick={onClose} className="btn-close">
            <X size={18} />
          </button>
        </div>

        {success ? (
          <div style={{ padding: '40px 24px', textAlign: 'center' }}>
            <div
              style={{
                width: 56,
                height: 56,
                borderRadius: '50%',
                backgroundColor: '#DCFCE7',
                color: '#16A34A',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                margin: '0 auto 16px',
              }}
            >
              <Check size={28} />
            </div>
            <h4 style={{ fontSize: 18, fontWeight: 800, color: '#111111' }}>Transaksi Berhasil Dicatat!</h4>
            <p style={{ fontSize: 13, color: '#64748B', marginTop: 4 }}>
              Arus kas toko langsung diperbarui ke ringkasan keuangan dan dashboard.
            </p>
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              {/* Type Switcher */}
              <div
                style={{
                  display: 'flex',
                  backgroundColor: '#F1F5F9',
                  padding: 4,
                  borderRadius: 12,
                  gap: 4,
                }}
              >
                <button
                  type="button"
                  onClick={() => {
                    setTxType('EXPENSE');
                    setCategory(expenseCategories[0]);
                  }}
                  style={{
                    flex: 1,
                    padding: '8px 12px',
                    borderRadius: 8,
                    border: 'none',
                    fontWeight: 700,
                    fontSize: 13,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: 6,
                    backgroundColor: txType === 'EXPENSE' ? '#FFFFFF' : 'transparent',
                    color: txType === 'EXPENSE' ? '#DC2626' : '#64748B',
                    boxShadow: txType === 'EXPENSE' ? '0 2px 4px rgba(0,0,0,0.06)' : 'none',
                    transition: 'all 0.15s ease',
                  }}
                >
                  <ArrowUpRight size={16} />
                  <span>Pengeluaran Toko</span>
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setTxType('INCOME');
                    setCategory(incomeCategories[0]);
                  }}
                  style={{
                    flex: 1,
                    padding: '8px 12px',
                    borderRadius: 8,
                    border: 'none',
                    fontWeight: 700,
                    fontSize: 13,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: 6,
                    backgroundColor: txType === 'INCOME' ? '#FFFFFF' : 'transparent',
                    color: txType === 'INCOME' ? '#16A34A' : '#64748B',
                    boxShadow: txType === 'INCOME' ? '0 2px 4px rgba(0,0,0,0.06)' : 'none',
                    transition: 'all 0.15s ease',
                  }}
                >
                  <ArrowDownRight size={16} />
                  <span>Pemasukan Lain</span>
                </button>
              </div>

              {/* Title Input */}
              <div>
                <label style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 6 }}>
                  Keterangan Transaksi
                </label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    borderRadius: 10,
                    border: '1px solid #CBD5E1',
                    fontSize: 13,
                    fontFamily: 'inherit',
                    outline: 'none',
                  }}
                  placeholder="Contoh: Beli Galon Air, Gas LPG, Cup Kopi"
                  required
                />
              </div>

              {/* Category */}
              <div>
                <label style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 6 }}>
                  Kategori
                </label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    borderRadius: 10,
                    border: '1px solid #CBD5E1',
                    fontSize: 13,
                    fontFamily: 'inherit',
                    outline: 'none',
                    backgroundColor: '#FFFFFF',
                  }}
                >
                  {(txType === 'EXPENSE' ? expenseCategories : incomeCategories).map((c) => (
                    <option key={c} value={c}>
                      {c}
                    </option>
                  ))}
                </select>
              </div>

              {/* Amount & Quick Chips */}
              <div>
                <label style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 6 }}>
                  Nominal (Rp)
                </label>
                <input
                  type="number"
                  min={1000}
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '12px 14px',
                    borderRadius: 10,
                    border: '1px solid #CBD5E1',
                    fontSize: 18,
                    fontWeight: 800,
                    color: txType === 'EXPENSE' ? '#DC2626' : '#16A34A',
                    fontFamily: 'inherit',
                    outline: 'none',
                  }}
                  required
                />

                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 8 }}>
                  {quickAmounts.map((q) => (
                    <button
                      key={q}
                      type="button"
                      onClick={() => setAmount(String(q))}
                      style={{
                        padding: '4px 8px',
                        borderRadius: 6,
                        border: '1px solid #E2E8F0',
                        backgroundColor: '#FFFFFF',
                        color: '#475569',
                        fontSize: 11,
                        fontWeight: 600,
                        cursor: 'pointer',
                      }}
                    >
                      +{q >= 1000 ? `${q / 1000}k` : q}
                    </button>
                  ))}
                </div>
              </div>

              {/* Payment Method */}
              <div>
                <label style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 6 }}>
                  Metode Pembayaran
                </label>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
                  {[
                    { id: 'cash', label: 'Tunai / Kas' },
                    { id: 'transfer', label: 'Transfer Bank' },
                    { id: 'qris', label: 'QRIS / E-Wallet' },
                  ].map((m) => (
                    <button
                      key={m.id}
                      type="button"
                      onClick={() => setPaymentMethod(m.id)}
                      style={{
                        padding: '8px 4px',
                        borderRadius: 8,
                        border: `1px solid ${paymentMethod === m.id ? '#111111' : '#CBD5E1'}`,
                        backgroundColor: paymentMethod === m.id ? '#111111' : '#FFFFFF',
                        color: paymentMethod === m.id ? '#FFFFFF' : '#475569',
                        fontSize: 11.5,
                        fontWeight: 700,
                        cursor: 'pointer',
                        textAlign: 'center',
                      }}
                    >
                      {m.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button type="button" onClick={onClose} className="btn-secondary">
                Batal
              </button>
              <button
                type="submit"
                disabled={loading}
                className="btn-primary"
                style={{ backgroundColor: txType === 'EXPENSE' ? '#111111' : '#16A34A', borderColor: txType === 'EXPENSE' ? '#111111' : '#16A34A' }}
              >
                {loading ? <Loader2 size={16} className="animate-spin" /> : <Check size={16} />}
                <span>Simpan Transaksi</span>
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};
