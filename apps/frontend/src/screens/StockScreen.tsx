import React, { useState } from 'react';
import { Product } from '../types';
import { Package, AlertTriangle, Search, Plus, Edit2, History, ArrowDownRight, ArrowUpRight, X, Save } from 'lucide-react';
import './StockScreen.css';

interface StockScreenProps {
  products: Product[];
  setProducts: React.Dispatch<React.SetStateAction<Product[]>>;
}

export const StockScreen: React.FC<StockScreenProps> = ({ products, setProducts }) => {
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [filterLowStockOnly, setFilterLowStockOnly] = useState<boolean>(false);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [adjustQty, setAdjustQty] = useState<number>(0);
  const [adjustReason, setAdjustReason] = useState<'restock' | 'damaged' | 'correction'>('restock');

  const totalProducts = products.length;
  const lowStockProducts = products.filter((p) => p.stock > 0 && p.stock <= p.minStock);
  const outOfStockProducts = products.filter((p) => p.stock === 0);

  const filteredProducts = products.filter((p) => {
    const matchesSearch = p.name.toLowerCase().includes(searchQuery.toLowerCase()) || (p.code && p.code.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesLowStock = filterLowStockOnly ? p.stock <= p.minStock : true;
    return matchesSearch && matchesLowStock;
  });

  const handleSaveStockAdjustment = () => {
    if (!selectedProduct || adjustQty === 0) return;

    setProducts((prev) =>
      prev.map((p) => {
        if (p.id === selectedProduct.id) {
          const delta = adjustReason === 'damaged' ? -Math.abs(adjustQty) : adjustQty;
          const newStock = Math.max(0, p.stock + delta);
          return { ...p, stock: newStock };
        }
        return p;
      })
    );

    setSelectedProduct(null);
    setAdjustQty(0);
  };

  return (
    <div className="page-screen stock-screen-container animate-fade-in">
      {/* Header & Title */}
      <div className="screen-header">
        <div>
          <h1 className="screen-title">Manajemen Stok & Inventaris</h1>
          <p className="screen-sub">Pantau jumlah produk, batas stok minimum, dan kulakan barang.</p>
        </div>
        <button onClick={() => alert('Fitur Tambah Produk Baru siap digunakan')} className="btn-primary">
          <Plus size={16} />
          Tambah Produk Baru
        </button>
      </div>

      {/* Stock Summary Metrics Cards */}
      <div className="grid-responsive-3 stock-metrics-grid">
        <div className="card-base metric-card">
          <div className="metric-icon-box teal">
            <Package size={22} />
          </div>
          <div className="metric-info">
            <span className="metric-label">Total Jenis Produk</span>
            <span className="metric-value">{totalProducts} SKU</span>
          </div>
        </div>

        <div className="card-base metric-card">
          <div className="metric-icon-box orange">
            <AlertTriangle size={22} />
          </div>
          <div className="metric-info">
            <span className="metric-label">Stok Menipis</span>
            <span className="metric-value warning-text">{lowStockProducts.length} Produk</span>
          </div>
        </div>

        <div className="card-base metric-card">
          <div className="metric-icon-box red">
            <X size={22} />
          </div>
          <div className="metric-info">
            <span className="metric-label">Stok Habis (0)</span>
            <span className="metric-value danger-text">{outOfStockProducts.length} Produk</span>
          </div>
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="stock-toolbar card-base">
        <div className="search-bar-wrap">
          <Search size={18} className="search-icon" />
          <input
            type="text"
            placeholder="Cari nama barang atau kode SKU..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pos-search-input"
          />
        </div>

        <div className="toolbar-controls">
          <label className="toggle-low-stock">
            <input
              type="checkbox"
              checked={filterLowStockOnly}
              onChange={(e) => setFilterLowStockOnly(e.target.checked)}
            />
            <span>Tampilkan Hanya Stok Menipis ({lowStockProducts.length})</span>
          </label>
        </div>
      </div>

      {/* Stock Table / List View */}
      <div className="card-base stock-table-card">
        <div className="table-responsive">
          <table className="stock-table">
            <thead>
              <tr>
                <th>SKU Code</th>
                <th>Nama Produk</th>
                <th>Kategori</th>
                <th>Jumlah Stok</th>
                <th>Batas Min</th>
                <th>Harga Jual</th>
                <th>Status</th>
                <th>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {filteredProducts.map((product) => {
                const isOutOfStock = product.stock === 0;
                const isLowStock = product.stock > 0 && product.stock <= product.minStock;

                return (
                  <tr key={product.id} className={isLowStock ? 'row-warning' : isOutOfStock ? 'row-danger' : ''}>
                    <td className="sku-cell">{product.code}</td>
                    <td className="name-cell">
                      <span className="p-name">{product.name}</span>
                    </td>
                    <td className="category-cell">{product.category}</td>
                    <td className="stock-cell">
                      <div className="stock-level-group">
                        <span className="stock-val">{product.stock} {product.unit}</span>
                        <div className="stock-bar-track">
                          <div
                            className={`stock-bar-fill ${isOutOfStock ? 'red' : isLowStock ? 'orange' : 'teal'}`}
                            style={{ width: `${Math.min(100, (product.stock / (product.minStock * 2)) * 100)}%` }}
                          ></div>
                        </div>
                      </div>
                    </td>
                    <td>{product.minStock} {product.unit}</td>
                    <td className="price-cell">Rp {product.price.toLocaleString('id-ID')}</td>
                    <td>
                      {isOutOfStock ? (
                        <span className="badge badge-danger">Habis</span>
                      ) : isLowStock ? (
                        <span className="badge badge-warning">Menipis</span>
                      ) : (
                        <span className="badge badge-success">Aman</span>
                      )}
                    </td>
                    <td>
                      <button
                        onClick={() => {
                          setSelectedProduct(product);
                          setAdjustQty(10);
                          setAdjustReason('restock');
                        }}
                        className="btn-secondary btn-sm"
                      >
                        <Edit2 size={12} />
                        Update Stok
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Stock Adjustment Modal */}
      {selectedProduct && (
        <div className="modal-overlay">
          <div className="modal-card animate-fade-in">
            <div className="modal-header">
              <h3>Update Stok & Restock Baris</h3>
              <button onClick={() => setSelectedProduct(null)} className="btn-close">
                <X size={18} />
              </button>
            </div>

            <div className="modal-body">
              <div className="product-summary-box">
                <span className="sku-badge">{selectedProduct.code}</span>
                <h4>{selectedProduct.name}</h4>
                <p className="current-stock-info">
                  Stok Saat Ini: <strong>{selectedProduct.stock} {selectedProduct.unit}</strong> (Batas Min: {selectedProduct.minStock})
                </p>
              </div>

              <div className="adjust-form">
                <label className="section-label">Jenis Penyesuaian:</label>
                <div className="adjust-type-chips">
                  <button
                    onClick={() => setAdjustReason('restock')}
                    className={`chip-btn ${adjustReason === 'restock' ? 'active' : ''}`}
                  >
                    <ArrowUpRight size={14} />
                    Restock / Kulakan (+
                  </button>
                  <button
                    onClick={() => setAdjustReason('damaged')}
                    className={`chip-btn ${adjustReason === 'damaged' ? 'active' : ''}`}
                  >
                    <ArrowDownRight size={14} />
                    Barang Rusak/Expired (-)
                  </button>
                  <button
                    onClick={() => setAdjustReason('correction')}
                    className={`chip-btn ${adjustReason === 'correction' ? 'active' : ''}`}
                  >
                    Koreksi Opname
                  </button>
                </div>

                <label className="section-label margin-top">Jumlah Penyesuaian ({selectedProduct.unit}):</label>
                <input
                  type="number"
                  value={adjustQty}
                  onChange={(e) => setAdjustQty(parseInt(e.target.value) || 0)}
                  className="cash-input"
                />
              </div>
            </div>

            <div className="modal-footer">
              <button onClick={() => setSelectedProduct(null)} className="btn-secondary">
                Batal
              </button>
              <button onClick={handleSaveStockAdjustment} className="btn-primary">
                <Save size={14} />
                Simpan Perubahan
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
