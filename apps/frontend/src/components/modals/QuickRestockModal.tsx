import React, { useState } from 'react';
import { X, Package, Check, Loader2 } from 'lucide-react';
import { Product } from '../../types';

interface QuickRestockModalProps {
  isOpen: boolean;
  onClose: () => void;
  products: Product[];
  onRestock: (stockId: string, payload: { quantity: number; cost_per_unit?: number; supplier?: string; note?: string }) => Promise<any>;
}

export const QuickRestockModal: React.FC<QuickRestockModalProps> = ({
  isOpen,
  onClose,
  products,
  onRestock,
}) => {
  if (!isOpen) return null;

  const [selectedProductId, setSelectedProductId] = useState<string>(
    products.length > 0 ? products[0].id : ''
  );
  const [quantity, setQuantity] = useState<number>(10);
  const [costPerUnit, setCostPerUnit] = useState<number>(25000);
  const [supplier, setSupplier] = useState<string>('Grosir Bahan Utama');
  const [note, setNote] = useState<string>('Restock rutin jam sibuk');
  const [loading, setLoading] = useState<boolean>(false);
  const [success, setSuccess] = useState<boolean>(false);

  const selectedProduct = products.find((p) => p.id === selectedProductId);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedProductId || quantity <= 0) return;

    setLoading(true);
    try {
      await onRestock(selectedProductId, {
        quantity: Number(quantity),
        cost_per_unit: Number(costPerUnit),
        supplier,
        note,
      });
      setSuccess(true);
      setTimeout(() => {
        setSuccess(false);
        onClose();
      }, 1000);
    } catch (err) {
      console.error('Restock error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 460 }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: 10,
                backgroundColor: '#DCFCE7',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#16A34A',
              }}
            >
              <Package size={20} />
            </div>
            <div>
              <h3>Restock Bahan Cepat</h3>
              <p style={{ fontSize: 12, color: '#64748B', marginTop: 1 }}>Catat penambahan stok bahan masuk ke inventaris</p>
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
            <h4 style={{ fontSize: 18, fontWeight: 800, color: '#111111' }}>Stok Berhasil Ditambahkan!</h4>
            <p style={{ fontSize: 13, color: '#64748B', marginTop: 4 }}>
              Jumlah stok bahan telah diperbarui secara langsung ke sistem inventaris.
            </p>
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 6 }}>
                  Pilih Bahan / Produk
                </label>
                <select
                  value={selectedProductId}
                  onChange={(e) => setSelectedProductId(e.target.value)}
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
                  required
                >
                  {products.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name} (Tersisa: {p.stock} {p.unit})
                    </option>
                  ))}
                </select>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div>
                  <label style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 6 }}>
                    Jumlah Masuk ({selectedProduct?.unit || 'unit'})
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={quantity}
                    onChange={(e) => setQuantity(Number(e.target.value))}
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      borderRadius: 10,
                      border: '1px solid #CBD5E1',
                      fontSize: 14,
                      fontWeight: 700,
                      fontFamily: 'inherit',
                      outline: 'none',
                    }}
                    required
                  />
                </div>

                <div>
                  <label style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 6 }}>
                    Harga Beli / Satuan (Rp)
                  </label>
                  <input
                    type="number"
                    min={0}
                    step={500}
                    value={costPerUnit}
                    onChange={(e) => setCostPerUnit(Number(e.target.value))}
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      borderRadius: 10,
                      border: '1px solid #CBD5E1',
                      fontSize: 14,
                      fontWeight: 700,
                      fontFamily: 'inherit',
                      outline: 'none',
                    }}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 6 }}>
                  Supplier / Tempat Kulakan
                </label>
                <input
                  type="text"
                  value={supplier}
                  onChange={(e) => setSupplier(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    borderRadius: 10,
                    border: '1px solid #CBD5E1',
                    fontSize: 13,
                    fontFamily: 'inherit',
                    outline: 'none',
                  }}
                  placeholder="Nama toko / pasar / distributor"
                />
              </div>

              <div>
                <label style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 6 }}>
                  Catatan Tambahan
                </label>
                <input
                  type="text"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    borderRadius: 10,
                    border: '1px solid #CBD5E1',
                    fontSize: 13,
                    fontFamily: 'inherit',
                    outline: 'none',
                  }}
                  placeholder="Keterangan kulakan..."
                />
              </div>

              <div
                style={{
                  backgroundColor: '#F8FAFC',
                  border: '1px solid #E2E8F0',
                  borderRadius: 10,
                  padding: 12,
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                }}
              >
                <span style={{ fontSize: 12, color: '#64748B', fontWeight: 600 }}>Total Estimasi Biaya</span>
                <span style={{ fontSize: 15, fontWeight: 800, color: '#111111' }}>
                  Rp {(quantity * costPerUnit).toLocaleString('id-ID')}
                </span>
              </div>
            </div>

            <div className="modal-footer">
              <button type="button" onClick={onClose} className="btn-secondary">
                Batal
              </button>
              <button type="submit" disabled={loading} className="btn-primary">
                {loading ? <Loader2 size={16} className="animate-spin" /> : <Check size={16} />}
                <span>Simpan Stok Masuk</span>
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};
