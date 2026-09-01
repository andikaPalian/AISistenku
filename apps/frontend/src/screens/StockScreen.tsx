import React, { useState } from 'react';
import { Product } from '../types';
import { Package, AlertTriangle, Search, Plus, Edit2, ArrowDownRight, ArrowUpRight, X, Save, Loader2 } from 'lucide-react';
import './StockScreen.css';

interface StockScreenProps {
  products: Product[];
  loading: boolean;
  onRestock: (stockId: string, body: { quantity: number; cost_per_unit?: number; supplier?: string; note?: string }) => Promise<any>;
  onAdjust: (stockId: string, body: { actual_quantity: number; reason?: string; note?: string }) => Promise<any>;
  refresh: () => Promise<void>;
}

export const StockScreen: React.FC<StockScreenProps> = ({ products, loading, onRestock, onAdjust, refresh }) => {
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [filterLowStockOnly, setFilterLowStockOnly] = useState<boolean>(false);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [adjustQty, setAdjustQty] = useState<number>(10);
  const [adjustReason, setAdjustReason] = useState<'restock' | 'damaged' | 'correction'>('restock');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const totalProducts = products.length;
  const lowStockProducts = products.filter((p) => p.stock > 0 && p.stock <= p.minStock);
  const outOfStockProducts = products.filter((p) => p.stock === 0);

  const filteredProducts = products.filter((p) => {
    const matchesSearch = p.name.toLowerCase().includes(searchQuery.toLowerCase()) || (p.code && p.code.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesLowStock = filterLowStockOnly ? p.stock <= p.minStock : true;
    return matchesSearch && matchesLowStock;
  });

  const handleSave = async () => {
    if (!selectedProduct || adjustQty === 0) return;
    setError(null);
    setSaving(true);
    try {
      if (adjustReason === 'restock') {
        await onRestock(selectedProduct.id, { quantity: adjustQty, note: 'Restock manual via UI' });
      } else if (adjustReason === 'damaged') {
        const newQty = Math.max(0, selectedProduct.stock - Math.abs(adjustQty));
        await onAdjust(selectedProduct.id, { actual_quantity: newQty, reason: 'damaged', note: 'Barang rusak/expired' });
      } else {
        const newQty = Math.max(0, selectedProduct.stock + adjustQty);
        await onAdjust(selectedProduct.id, { actual_quantity: newQty, reason: 'correction', note: 'Koreksi opname' });
      }
      await refresh();
      setSelectedProduct(null);
      setAdjustQty(10);
    } catch (e: any) {
      setError(e?.error || 'Gagal menyimpan perubahan');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="page-screen stock-screen-container animate-fade-in">
      <div className="screen-header">
        <div>
          <h1 className="screen-title">Manajemen Stok & Inventaris</h1>
          <p className="screen-sub">Data langsung dari database Supabase. Stok berkurang otomatis saat POS checkout.</p>
        </div>
        <button onClick={() => alert('Gunakan endpoint POST /api/stocks untuk menambah item baru')} className="btn-primary">
          <Plus size={16} /> Tambah Bahan Baku
        </button>
      </div>

      <div className="grid-responsive-3 stock-metrics-grid">
        <div className="card-base metric-card">
          <div className="metric-icon-box teal"><Package size={22} /></div>
          <div className="metric-info">
            <span className="metric-label">Total Jenis Bahan</span>
            <span className="metric-value">{totalProducts} SKU</span>
          </div>
        </div>
        <div className="card-base metric-card">
          <div className="metric-icon-box orange"><AlertTriangle size={22} /></div>
          <div className="metric-info">
            <span className="metric-label">Stok Menipis</span>
            <span className="metric-value warning-text">{lowStockProducts.length} Produk</span>
          </div>
        </div>
        <div className="card-base metric-card">
          <div className="metric-icon-box red"><X size={22} /></div>
          <div className="metric-info">
            <span className="metric-label">Stok Habis (0)</span>
            <span className="metric-value danger-text">{outOfStockProducts.length} Produk</span>
          </div>
        </div>
      </div>

      <div className="stock-toolbar card-base">
        <div className="search-bar-wrap">
          <Search size={18} className="search-icon" />
          <input type="text" placeholder="Cari nama barang atau kode SKU..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="pos-search-input" />
        </div>
        <div className="toolbar-controls">
          <label className="toggle-low-stock">
            <input type="checkbox" checked={filterLowStockOnly} onChange={(e) => setFilterLowStockOnly(e.target.checked)} />
            <span>Tampilkan Hanya Stok Menipis ({lowStockProducts.length})</span>
          </label>
        </div>
      </div>

      <div className="card-base stock-table-card">
        <div className="table-responsive">
          <table className="stock-table">
            <thead>
              <tr>
                <th>SKU</th>
                <th>Nama Bahan</th>
                <th>Kategori</th>
                <th>Jumlah Stok</th>
                <th>Batas Min</th>
                <th>Harga Modal</th>
                <th>Status</th>
                <th>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={8} className="empty-state-small">Memuat data dari server...</td></tr>
              ) : filteredProducts.length === 0 ? (
                <tr><td colSpan={8} className="empty-state-small">Tidak ada data.</td></tr>
              ) : filteredProducts.map((product) => {
                const isOutOfStock = product.stock === 0;
                const isLowStock = product.stock > 0 && product.stock <= product.minStock;
                return (
                  <tr key={product.id} className={isLowStock ? 'row-warning' : isOutOfStock ? 'row-danger' : ''}>
                    <td className="sku-cell">{product.code}</td>
                    <td className="name-cell"><span className="p-name">{product.name}</span></td>
                    <td className="category-cell">{product.category}</td>
                    <td className="stock-cell">
                      <div className="stock-level-group">
                        <span className="stock-val">{product.stock} {product.unit}</span>
                        <div className="stock-bar-track">
                          <div className={`stock-bar-fill ${isOutOfStock ? 'red' : isLowStock ? 'orange' : 'teal'}`} style={{ width: `${Math.min(100, (product.stock / (product.minStock * 2)) * 100)}%` }}></div>
                        </div>
                      </div>
                    </td>
                    <td>{product.minStock} {product.unit}</td>
                    <td className="price-cell">Rp {product.price.toLocaleString('id-ID')}</td>
                    <td>
                      {isOutOfStock ? <span className="badge badge-danger">Habis</span> :
                        isLowStock ? <span className="badge badge-warning">Menipis</span> :
                          <span className="badge badge-success">Aman</span>}
                    </td>
                    <td>
                      <button onClick={() => { setSelectedProduct(product); setAdjustQty(10); setAdjustReason('restock'); }} className="btn-secondary btn-sm">
                        <Edit2 size={12} /> Update Stok
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {selectedProduct && (
        <div className="modal-overlay">
          <div className="modal-card animate-fade-in">
            <div className="modal-header">
              <h3>Update Stok</h3>
              <button onClick={() => setSelectedProduct(null)} className="btn-close"><X size={18} /></button>
            </div>

            <div className="modal-body">
              <div className="product-summary-box">
                <span className="sku-badge">{selectedProduct.code}</span>
                <h4>{selectedProduct.name}</h4>
                <p className="current-stock-info">Stok Saat Ini: <strong>{selectedProduct.stock} {selectedProduct.unit}</strong> (Batas Min: {selectedProduct.minStock})</p>
              </div>

              <div className="adjust-form">
                <label className="section-label">Jenis Penyesuaian:</label>
                <div className="adjust-type-chips">
                  <button onClick={() => setAdjustReason('restock')} className={`chip-btn ${adjustReason === 'restock' ? 'active' : ''}`}><ArrowUpRight size={14} /> Restock / Kulakan (+)</button>
                  <button onClick={() => setAdjustReason('damaged')} className={`chip-btn ${adjustReason === 'damaged' ? 'active' : ''}`}><ArrowDownRight size={14} /> Barang Rusak/Expired (-)</button>
                  <button onClick={() => setAdjustReason('correction')} className={`chip-btn ${adjustReason === 'correction' ? 'active' : ''}`}>Koreksi Opname</button>
                </div>

                <label className="section-label margin-top">Jumlah Penyesuaian ({selectedProduct.unit}):</label>
                <input type="number" value={adjustQty} onChange={(e) => setAdjustQty(parseInt(e.target.value) || 0)} className="cash-input" />

                {error && <div className="login-error" style={{ marginTop: '0.75rem' }}>{error}</div>}
              </div>
            </div>

            <div className="modal-footer">
              <button onClick={() => setSelectedProduct(null)} className="btn-secondary" disabled={saving}>Batal</button>
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

export default StockScreen;
