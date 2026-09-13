import React from 'react';
import { X, Receipt, CheckCircle2, Printer, ArrowUpRight, ArrowDownRight } from 'lucide-react';
import { Transaction } from '../../types';

interface TransactionDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  transaction: Transaction | null;
}

const formatRupiah = (n: number) => `Rp ${(n || 0).toLocaleString('id-ID')}`;

export const TransactionDetailModal: React.FC<TransactionDetailModalProps> = ({
  isOpen,
  onClose,
  transaction,
}) => {
  if (!isOpen || !transaction) return null;

  const isIncome = transaction.type === 'sale' || transaction.type === 'income';

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 440 }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: 10,
                backgroundColor: isIncome ? '#DCFCE7' : '#FEE2E2',
                color: isIncome ? '#16A34A' : '#DC2626',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              {isIncome ? <ArrowDownRight size={20} /> : <ArrowUpRight size={20} />}
            </div>
            <div>
              <h3>Rincian Transaksi</h3>
              <p style={{ fontSize: 11.5, color: '#64748B', marginTop: 1 }}>
                ID: {transaction.id.slice(0, 10).toUpperCase()}
              </p>
            </div>
          </div>
          <button type="button" onClick={onClose} className="btn-close">
            <X size={18} />
          </button>
        </div>

        <div className="modal-body" style={{ padding: '20px 24px' }}>
          {/* Thermal receipt lookalike box */}
          <div
            style={{
              backgroundColor: '#FAFAFA',
              border: '1px dashed #CBD5E1',
              borderRadius: 12,
              padding: '16px',
              fontFamily: 'monospace',
              fontSize: 12,
              color: '#334155',
            }}
          >
            <div style={{ textAlign: 'center', borderBottom: '1px dashed #CBD5E1', paddingBottom: 10, marginBottom: 10 }}>
              <strong style={{ fontSize: 14, color: '#111111', display: 'block' }}>TOKO TIGA ANGKATAN</strong>
              <span style={{ fontSize: 11, color: '#64748B' }}>Aisistenku Retail POS System</span>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
              <span style={{ color: '#64748B' }}>Waktu:</span>
              <span>{new Date(transaction.date).toLocaleString('id-ID', { dateStyle: 'medium', timeStyle: 'short' })}</span>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
              <span style={{ color: '#64748B' }}>Kategori:</span>
              <strong style={{ color: '#111111' }}>{transaction.category}</strong>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
              <span style={{ color: '#64748B' }}>Metode Bayar:</span>
              <span style={{ textTransform: 'uppercase' }}>{transaction.paymentMethod || 'TUNAI / CASH'}</span>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
              <span style={{ color: '#64748B' }}>Status:</span>
              <span style={{ color: '#16A34A', fontWeight: 700 }}>SELESAI (LUNAS)</span>
            </div>

            <div style={{ borderTop: '1px dashed #CBD5E1', margin: '10px 0', paddingTop: 8 }}>
              <span style={{ color: '#64748B', display: 'block', marginBottom: 2 }}>Deskripsi:</span>
              <p style={{ margin: 0, fontWeight: 700, color: '#111111', fontFamily: 'var(--font-family)' }}>
                {transaction.title || transaction.notes || transaction.category || 'Transaksi Penjualan'}
              </p>
            </div>

            <div
              style={{
                borderTop: '1px solid #111111',
                marginTop: 10,
                paddingTop: 8,
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <strong style={{ fontSize: 13, color: '#111111' }}>TOTAL</strong>
              <strong
                style={{
                  fontSize: 18,
                  color: isIncome ? '#16A34A' : '#111111',
                  fontFamily: 'var(--font-family)',
                }}
              >
                {isIncome ? '+' : '-'}{formatRupiah(transaction.amount)}
              </strong>
            </div>
          </div>
        </div>

        <div className="modal-footer" style={{ display: 'flex', gap: 10 }}>
          <button
            type="button"
            onClick={() => {
              window.print();
            }}
            className="btn-secondary"
            style={{ flex: 1, justifyContent: 'center' }}
          >
            <Printer size={15} />
            <span>Cetak Salinan</span>
          </button>
          <button
            type="button"
            onClick={onClose}
            className="btn-primary"
            style={{ flex: 1, justifyContent: 'center' }}
          >
            Tutup
          </button>
        </div>
      </div>
    </div>
  );
};
