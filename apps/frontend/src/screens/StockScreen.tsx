import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { Product } from '../types';
import {
  Package,
  AlertTriangle,
  Search,
  Plus,
  Edit2,
  ArrowDownRight,
  ArrowUpRight,
  X,
  Save,
  Loader2,
  Trash2,
  UploadCloud,
  Check,
} from 'lucide-react';
import { animateScreenEntrance } from '../lib/animations';
import { Pagination } from '../components/common/Pagination';
import './StockScreen.css';

interface StockScreenProps {
  products: Product[];
  loading: boolean;
  onRestock: (stockId: string, body: { quantity: number; cost_per_unit?: number; supplier?: string; note?: string }) => Promise<any>;
  onAdjust: (stockId: string, body: { actual_quantity: number; reason?: string; note?: string }) => Promise<any>;
  onCreateItem?: (body: {
    name: string;
    category: string;
    price: number;
    sellingPrice?: number;
    stock: number;
    minStock: number;
    unit: string;
    code?: string;
    isPosProduct?: boolean;
    image?: string;
  }) => Promise<any>;
  onUpdateItem?: (id: string, body: Partial<Product> & { sellingPrice?: number }) => Promise<any>;
  onDeleteItem?: (id: string) => Promise<any>;
  refresh: () => Promise<void>;
}

export const StockScreen: React.FC<StockScreenProps> = ({
  products, loading, onRestock, onAdjust, onCreateItem, onUpdateItem, onDeleteItem, refresh,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    animateScreenEntrance(containerRef.current);
  }, []);

  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategoryTab, setSelectedCategoryTab] = useState<string>('Semua');
  const [filterLowStockOnly, setFilterLowStockOnly] = useState<boolean>(false);
  const [currentPage, setCurrentPage] = useState<number>(1);
  const pageSize = 6;

  // Custom Category & Unit states
  const defaultCategories = ['Bahan Baku', 'Kemasan', 'Kopi', 'Non-Kopi', 'Makanan', 'Snack', 'Topping', 'Sirup & Saus', 'Merchandise'];
  const defaultUnits = ['kg', 'liter', 'pcs', 'cup', 'porsi', 'botol', 'pack', 'gram', 'ml', 'dus', 'kaleng'];

  const [customCategories, setCustomCategories] = useState<string[]>(defaultCategories);
  const [customUnits, setCustomUnits] = useState<string[]>(defaultUnits);

  const [isAddingCategory, setIsAddingCategory] = useState<boolean>(false);
  const [newCategoryInput, setNewCategoryInput] = useState<string>('');

  const [isAddingUnit, setIsAddingUnit] = useState<boolean>(false);
  const [newUnitInput, setNewUnitInput] = useState<string>('');

  // Modals state
  const [isCreateModalOpen, setIsCreateModalOpen] = useState<boolean>(false);
  const [editProduct, setEditProduct] = useState<Product | null>(null);
  const [stockProduct, setStockProduct] = useState<Product | null>(null);

  // Restock form state
  const [adjustQty, setAdjustQty] = useState<number>(10);
  const [adjustReason, setAdjustReason] = useState<'restock' | 'damaged' | 'correction'>('restock');

  // Create/Edit form state
  const [formName, setFormName] = useState<string>('');
  const [formCategory, setFormCategory] = useState<string>('Bahan Baku');
  const [formUnit, setFormUnit] = useState<string>('kg');
  const [formCostPrice, setFormCostPrice] = useState<number>(20000);
  const [formSellingPrice, setFormSellingPrice] = useState<number>(30000);
  const [formStock, setFormStock] = useState<number>(10);
  const [formMinStock, setFormMinStock] = useState<number>(5);
  const [formIsPos, setFormIsPos] = useState<boolean>(false);
  const [formImageUrl, setFormImageUrl] = useState<string>('');
  const [isDraggingFile, setIsDraggingFile] = useState<boolean>(false);

  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Combine default categories with any existing product categories
  const allCategories = Array.from(
    new Set([...customCategories, ...products.map((p) => p.category).filter(Boolean)])
  );
  const allUnits = Array.from(
    new Set([...customUnits, ...products.map((p) => p.unit).filter(Boolean)])
  );

  const categoryTabs = ['Semua', ...allCategories];

  const totalProducts = products.length;
  const lowStockProducts = products.filter((p) => p.stock > 0 && p.stock <= p.minStock);
  const outOfStockProducts = products.filter((p) => p.stock === 0);

  const filteredProducts = products.filter((p) => {
    const matchesSearch =
      p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (p.code && p.code.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesCategory =
      selectedCategoryTab === 'Semua' || p.category === selectedCategoryTab;
    const matchesLowStock = filterLowStockOnly ? p.stock <= p.minStock : true;
    return matchesSearch && matchesCategory && matchesLowStock;
  });

  const totalPages = Math.ceil(filteredProducts.length / pageSize) || 1;
  const paginatedProducts = filteredProducts.slice((currentPage - 1) * pageSize, currentPage * pageSize);

  const handleSearchChange = (val: string) => {
    setSearchQuery(val);
    setCurrentPage(1);
  };

  const handleCategoryTabChange = (tab: string) => {
    setSelectedCategoryTab(tab);
    setCurrentPage(1);
  };

  const handleOpenCreateModal = () => {
    setError(null);
    setFormName('');
    setFormCategory('Bahan Baku');
    setFormUnit('kg');
    setFormCostPrice(20000);
    setFormSellingPrice(30000);
    setFormStock(10);
    setFormMinStock(5);
    setFormIsPos(false);
    setFormImageUrl('');
    setIsCreateModalOpen(true);
  };

  const handleOpenEditModal = (p: Product) => {
    setError(null);
    setEditProduct(p);
    setFormName(p.name);
    setFormCategory(p.category);
    setFormUnit(p.unit || 'pcs');
    setFormCostPrice(p.price || 0);
    setFormSellingPrice(p.price ? Math.round(p.price * 1.3) : 25000);
    setFormStock(p.stock);
    setFormMinStock(p.minStock);
    setFormIsPos(['Kopi', 'Non-Kopi', 'Snack', 'Makanan'].includes(p.category));
    setFormImageUrl((p as any).image || '');
  };

  const handleFileUpload = (file: File) => {
    if (!file.type.startsWith('image/')) {
      setError('Hanya file foto/gambar (JPG, PNG, WebP) yang didukung.');
      return;
    }
    const reader = new FileReader();
    reader.onload = (e) => {
      setFormImageUrl(e.target?.result as string);
    };
    reader.readAsDataURL(file);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDraggingFile(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFileUpload(e.dataTransfer.files[0]);
    }
  };

  const handleSaveRestock = async () => {
    if (!stockProduct || adjustQty === 0) return;
    setError(null);
    setSaving(true);
    try {
      if (adjustReason === 'restock') {
        await onRestock(stockProduct.id, { quantity: adjustQty, note: 'Restock manual via UI' });
      } else if (adjustReason === 'damaged') {
        const newQty = Math.max(0, stockProduct.stock - Math.abs(adjustQty));
        await onAdjust(stockProduct.id, { actual_quantity: newQty, reason: 'damaged', note: 'Barang rusak/expired' });
      } else {
        const newQty = Math.max(0, stockProduct.stock + adjustQty);
        await onAdjust(stockProduct.id, { actual_quantity: newQty, reason: 'correction', note: 'Koreksi opname' });
      }
      await refresh();
      setStockProduct(null);
      setAdjustQty(10);
    } catch (e: any) {
      setError(e?.error || 'Gagal menyimpan perubahan');
    } finally {
      setSaving(false);
    }
  };

  const handleSaveCreate = async () => {
    if (!formName.trim()) {
      setError('Nama barang / bahan baku wajib diisi');
      return;
    }
    setError(null);
    setSaving(true);
    try {
      if (onCreateItem) {
        await onCreateItem({
          name: formName,
          category: formCategory,
          price: Number(formCostPrice) || 0,
          sellingPrice: Number(formSellingPrice) || Number(formCostPrice),
          stock: Number(formStock) || 0,
          minStock: Number(formMinStock) || 0,
          unit: formUnit,
          isPosProduct: formIsPos,
          image: formImageUrl || undefined,
        });
      }
      await refresh();
      setIsCreateModalOpen(false);
    } catch (e: any) {
      setError(e?.error || 'Gagal menambahkan barang');
    } finally {
      setSaving(false);
    }
  };

  const handleSaveEdit = async () => {
    if (!editProduct || !formName.trim()) {
      setError('Nama barang tidak boleh kosong');
      return;
    }
    setError(null);
    setSaving(true);
    try {
      if (onUpdateItem) {
        await onUpdateItem(editProduct.id, {
          name: formName,
          category: formCategory,
          price: Number(formCostPrice) || 0,
          sellingPrice: Number(formSellingPrice) || Number(formCostPrice),
          stock: Number(formStock) || 0,
          minStock: Number(formMinStock) || 0,
          unit: formUnit,
          image: formImageUrl || undefined,
        });
      }
      await refresh();
      setEditProduct(null);
    } catch (e: any) {
      setError(e?.error || 'Gagal mengupdate barang');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string, name: string) => {
    if (window.confirm(`Apakah Anda yakin ingin menghapus "${name}" dari inventaris?`)) {
      if (onDeleteItem) {
        await onDeleteItem(id);
        await refresh();
      }
    }
  };

  return (
    <div ref={containerRef} className="page-screen stock-screen-container">
      {/* ── Screen Header ── */}
      <div className="screen-header gsap-reveal">
        <div>
          <h1 className="screen-title">Manajemen Stok &amp; Inventaris</h1>
          <p className="screen-sub">
            Pantau sisa bahan baku, atur harga modal &amp; jual, dan tambahkan produk baru langsung ke POS kasir.
          </p>
        </div>
        <button
          type="button"
          onClick={handleOpenCreateModal}
          className="btn-primary"
          title="Tambah Barang / Bahan Baku Baru"
        >
          <Plus size={16} />
          <span>Tambah Barang / Bahan</span>
        </button>
      </div>

      {/* ── Key Metrics ── */}
      <div className="grid-responsive-3 stock-metrics-grid gsap-reveal">
        <div className="card-base metric-card">
          <div className="metric-icon-box teal">
            <Package size={22} />
          </div>
          <div className="metric-info">
            <span className="metric-label">Total Jenis Item</span>
            <span className="metric-value">{totalProducts} SKU</span>
          </div>
        </div>
        <div className="card-base metric-card">
          <div className="metric-icon-box orange">
            <AlertTriangle size={22} />
          </div>
          <div className="metric-info">
            <span className="metric-label">Stok Menipis</span>
            <span className="metric-value warning-text">{lowStockProducts.length} Item</span>
          </div>
        </div>
        <div className="card-base metric-card">
          <div className="metric-icon-box red">
            <X size={22} />
          </div>
          <div className="metric-info">
            <span className="metric-label">Stok Habis (0)</span>
            <span className="metric-value danger-text">{outOfStockProducts.length} Item</span>
          </div>
        </div>
      </div>

      {/* ── Category Filter Bar & Search ── */}
      <div className="stock-toolbar card-base gsap-reveal">
        <div className="search-bar-wrap">
          <Search size={18} className="search-icon" />
          <input
            type="text"
            placeholder="Cari nama barang, bahan baku, atau kode SKU..."
            value={searchQuery}
            onChange={(e) => handleSearchChange(e.target.value)}
            className="pos-search-input"
          />
          {searchQuery && (
            <button onClick={() => handleSearchChange('')} className="btn-clear-search">
              <X size={14} />
            </button>
          )}
        </div>

        <div className="toolbar-controls">
          <div className="stock-category-pills">
            {categoryTabs.map((cat) => (
              <button
                key={cat}
                type="button"
                onClick={() => handleCategoryTabChange(cat)}
                className={`stock-cat-pill ${selectedCategoryTab === cat ? 'active' : ''}`}
              >
                {cat}
              </button>
            ))}
          </div>

          <label className="toggle-low-stock">
            <input
              type="checkbox"
              checked={filterLowStockOnly}
              onChange={(e) => {
                setFilterLowStockOnly(e.target.checked);
                setCurrentPage(1);
              }}
            />
            <span>Stok Menipis Saja ({lowStockProducts.length})</span>
          </label>
        </div>
      </div>

      {/* ── Products & Inventory Table ── */}
      <div className="card-base stock-table-card gsap-reveal">
        <div className="table-responsive">
          <table className="stock-table">
            <thead>
              <tr>
                <th>SKU</th>
                <th>Nama Barang / Bahan</th>
                <th>Kategori</th>
                <th>Jumlah Stok</th>
                <th>Batas Min</th>
                <th>Harga Modal / Beli</th>
                <th>Status</th>
                <th style={{ textAlign: 'right' }}>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={8} className="empty-state-small">
                    Memuat data inventaris...
                  </td>
                </tr>
              ) : filteredProducts.length === 0 ? (
                <tr>
                  <td colSpan={8} className="empty-state-small">
                    Tidak ada barang ditemukan sesuai filter.
                  </td>
                </tr>
              ) : (
                paginatedProducts.map((product) => {
                  const isOutOfStock = product.stock === 0;
                  const isLowStock = product.stock > 0 && product.stock <= product.minStock;

                  return (
                    <tr
                      key={product.id}
                      className={isLowStock ? 'row-warning' : isOutOfStock ? 'row-danger' : ''}
                    >
                      <td className="sku-cell">{product.code}</td>
                      <td className="name-cell">
                        <div className="item-name-group">
                          {(product as any).image && (
                            <img
                              src={(product as any).image}
                              alt={product.name}
                              className="item-mini-thumb"
                              loading="lazy"
                            />
                          )}
                          <div>
                            <span className="p-name">{product.name}</span>
                            {['Kopi', 'Non-Kopi', 'Snack', 'Makanan'].includes(product.category) && (
                              <span className="pos-badge-indicator">Menu Kasir</span>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="category-cell">
                        <span className="cat-chip-tag">{product.category}</span>
                      </td>
                      <td className="stock-cell">
                        <div className="stock-level-group">
                          <span className="stock-val">
                            <strong>{product.stock}</strong> {product.unit}
                          </span>
                          <div className="stock-bar-track">
                            <div
                              className={`stock-bar-fill ${
                                isOutOfStock ? 'red' : isLowStock ? 'orange' : 'teal'
                              }`}
                              style={{
                                width: `${Math.min(
                                  100,
                                  product.minStock > 0
                                    ? (product.stock / (product.minStock * 2)) * 100
                                    : 100
                                )}%`,
                              }}
                            ></div>
                          </div>
                        </div>
                      </td>
                      <td>
                        {product.minStock} {product.unit}
                      </td>
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
                      <td style={{ textAlign: 'right' }}>
                        <div className="row-action-buttons">
                          <button
                            type="button"
                            onClick={() => {
                              setStockProduct(product);
                              setAdjustQty(10);
                              setAdjustReason('restock');
                            }}
                            className="btn-secondary btn-sm btn-update-stock"
                            title="Restock atau Penyesuaian Stok"
                          >
                            <ArrowUpRight size={13} />
                            <span>Stok</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => handleOpenEditModal(product)}
                            className="btn-secondary btn-sm"
                            title="Edit Detail & Harga"
                          >
                            <Edit2 size={13} />
                            <span>Edit</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => handleDelete(product.id, product.name)}
                            className="btn-icon-danger"
                            title="Hapus Barang"
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
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
          totalItems={filteredProducts.length}
          pageSize={pageSize}
          onPageChange={setCurrentPage}
        />
      </div>

      {/* ── MODAL 1: CREATE ITEM / BAHAN BAKU (PORTAL TO BODY) ── */}
      {isCreateModalOpen && createPortal(
        <div className="modal-overlay">
          <div className="modal-card stock-modal-card animate-fade-in">
            <div className="modal-header">
              <div className="modal-title-wrap">
                <Package size={20} className="text-teal" />
                <h3>Tambah Barang &amp; Bahan Baku Baru</h3>
              </div>
              <button onClick={() => setIsCreateModalOpen(false)} className="btn-close">
                <X size={18} />
              </button>
            </div>

            <div className="modal-body">
              <div className="form-grid-2">
                <div className="form-group-item full-width">
                  <label>Nama Barang / Bahan Baku *</label>
                  <input
                    type="text"
                    placeholder="e.g. Sirup Karamel Monin / Croissant Almond"
                    value={formName}
                    onChange={(e) => setFormName(e.target.value)}
                    className="modal-form-input"
                  />
                </div>

                <div className="form-group-item">
                  <div className="label-with-action">
                    <label>Kategori</label>
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
                        placeholder="Nama kategori baru..."
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
                            if (!customCategories.includes(trimmed)) {
                              setCustomCategories([...customCategories, trimmed]);
                            }
                            setFormCategory(trimmed);
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
                      value={formCategory}
                      onChange={(e) => {
                        if (e.target.value === '__add_new__') {
                          setIsAddingCategory(true);
                          setNewCategoryInput('');
                        } else {
                          setFormCategory(e.target.value);
                          if (['Kopi', 'Non-Kopi', 'Snack', 'Makanan'].includes(e.target.value)) {
                            setFormIsPos(true);
                          }
                        }
                      }}
                      className="modal-form-select"
                    >
                      {allCategories.map((cat) => (
                        <option key={cat} value={cat}>
                          {cat}
                        </option>
                      ))}
                      <option value="__add_new__">+ Tambah Kategori Baru...</option>
                    </select>
                  )}
                </div>

                <div className="form-group-item">
                  <div className="label-with-action">
                    <label>Satuan Unit</label>
                    {!isAddingUnit && (
                      <button
                        type="button"
                        onClick={() => {
                          setIsAddingUnit(true);
                          setNewUnitInput('');
                        }}
                        className="btn-text-action"
                      >
                        <Plus size={12} /> Satuan Baru
                      </button>
                    )}
                  </div>

                  {isAddingUnit ? (
                    <div className="inline-add-group">
                      <input
                        type="text"
                        placeholder="e.g. roll, lusin, ml..."
                        value={newUnitInput}
                        onChange={(e) => setNewUnitInput(e.target.value)}
                        className="modal-form-input inline-input"
                        autoFocus
                      />
                      <button
                        type="button"
                        onClick={() => {
                          if (newUnitInput.trim()) {
                            const trimmed = newUnitInput.trim();
                            if (!customUnits.includes(trimmed)) {
                              setCustomUnits([...customUnits, trimmed]);
                            }
                            setFormUnit(trimmed);
                            setIsAddingUnit(false);
                          }
                        }}
                        className="btn-inline-save"
                        title="Simpan Satuan"
                      >
                        <Check size={14} />
                      </button>
                      <button
                        type="button"
                        onClick={() => setIsAddingUnit(false)}
                        className="btn-inline-cancel"
                        title="Batal"
                      >
                        <X size={14} />
                      </button>
                    </div>
                  ) : (
                    <select
                      value={formUnit}
                      onChange={(e) => {
                        if (e.target.value === '__add_new__') {
                          setIsAddingUnit(true);
                          setNewUnitInput('');
                        } else {
                          setFormUnit(e.target.value);
                        }
                      }}
                      className="modal-form-select"
                    >
                      {allUnits.map((u) => (
                        <option key={u} value={u}>
                          {u}
                        </option>
                      ))}
                      <option value="__add_new__">+ Tambah Satuan Lain...</option>
                    </select>
                  )}
                </div>

                <div className="form-group-item">
                  <label>Jumlah Stok Awal</label>
                  <input
                    type="number"
                    value={formStock}
                    onChange={(e) => setFormStock(parseInt(e.target.value) || 0)}
                    className="modal-form-input"
                  />
                </div>

                <div className="form-group-item">
                  <label>Batas Minimum Stok (Peringatan)</label>
                  <input
                    type="number"
                    value={formMinStock}
                    onChange={(e) => setFormMinStock(parseInt(e.target.value) || 0)}
                    className="modal-form-input"
                  />
                </div>

                <div className="form-group-item">
                  <label>Harga Modal / Beli (Rp)</label>
                  <input
                    type="number"
                    value={formCostPrice}
                    onChange={(e) => setFormCostPrice(parseInt(e.target.value) || 0)}
                    className="modal-form-input"
                  />
                </div>

                <div className="form-group-item">
                  <label>Harga Jual di Kasir POS (Rp)</label>
                  <input
                    type="number"
                    value={formSellingPrice}
                    onChange={(e) => setFormSellingPrice(parseInt(e.target.value) || 0)}
                    className="modal-form-input"
                  />
                </div>

                {/* ── Modern Drag & Drop Image Uploader ── */}
                <div className="form-group-item full-width">
                  <label>Foto Produk (Drag &amp; Drop atau Pilih File)</label>
                  <input
                    type="file"
                    ref={fileInputRef}
                    accept="image/*"
                    style={{ display: 'none' }}
                    onChange={(e) => {
                      if (e.target.files && e.target.files[0]) {
                        handleFileUpload(e.target.files[0]);
                      }
                    }}
                  />

                  {formImageUrl ? (
                    <div className="image-preview-box">
                      <img src={formImageUrl} alt="Preview" className="preview-img" />
                      <div className="preview-info">
                        <span className="preview-title">Foto Produk Terpilih</span>
                        <div className="preview-actions">
                          <button
                            type="button"
                            onClick={() => fileInputRef.current?.click()}
                            className="btn-change-photo"
                          >
                            Ganti Foto
                          </button>
                          <button
                            type="button"
                            onClick={() => setFormImageUrl('')}
                            className="btn-delete-photo"
                            title="Hapus Foto"
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
                      </div>
                    </div>
                  ) : (
                    <div
                      onDragOver={(e) => {
                        e.preventDefault();
                        setIsDraggingFile(true);
                      }}
                      onDragLeave={() => setIsDraggingFile(false)}
                      onDrop={handleDrop}
                      onClick={() => fileInputRef.current?.click()}
                      className={`image-dropzone ${isDraggingFile ? 'dragging' : ''}`}
                    >
                      <UploadCloud size={28} className="dropzone-icon" />
                      <span className="dropzone-title">
                        Tarik &amp; Lepas foto di sini, atau <strong>Pilih File</strong>
                      </span>
                      <span className="dropzone-sub">Mendukung format JPG, PNG, WEBP hingga 5MB</span>
                    </div>
                  )}
                </div>

                <div className="form-group-item full-width">
                  <label className="pos-sync-checkbox">
                    <input
                      type="checkbox"
                      checked={formIsPos}
                      onChange={(e) => setFormIsPos(e.target.checked)}
                    />
                    <span>
                      <strong>Tampilkan di Menu Penjualan POS Kasir</strong> (Dapat dipesan &amp; dijual langsung ke pelanggan)
                    </span>
                  </label>
                </div>
              </div>

              {error && <div className="pos-error-box">{error}</div>}
            </div>

            <div className="modal-footer">
              <button
                type="button"
                onClick={() => setIsCreateModalOpen(false)}
                className="btn-secondary"
                disabled={saving}
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleSaveCreate}
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
                    <span>Simpan Barang Baru</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>,
        document.body
      )}

      {/* ── MODAL 2: EDIT DETAIL & HARGA (PORTAL TO BODY) ── */}
      {editProduct && createPortal(
        <div className="modal-overlay">
          <div className="modal-card stock-modal-card animate-fade-in">
            <div className="modal-header">
              <div className="modal-title-wrap">
                <Edit2 size={20} className="text-teal" />
                <h3>Edit Detail &amp; Harga: {editProduct.name}</h3>
              </div>
              <button onClick={() => setEditProduct(null)} className="btn-close">
                <X size={18} />
              </button>
            </div>

            <div className="modal-body">
              <div className="form-grid-2">
                <div className="form-group-item full-width">
                  <label>Nama Barang / Bahan Baku</label>
                  <input
                    type="text"
                    value={formName}
                    onChange={(e) => setFormName(e.target.value)}
                    className="modal-form-input"
                  />
                </div>

                <div className="form-group-item">
                  <div className="label-with-action">
                    <label>Kategori</label>
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
                        placeholder="Nama kategori baru..."
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
                            if (!customCategories.includes(trimmed)) {
                              setCustomCategories([...customCategories, trimmed]);
                            }
                            setFormCategory(trimmed);
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
                      value={formCategory}
                      onChange={(e) => {
                        if (e.target.value === '__add_new__') {
                          setIsAddingCategory(true);
                          setNewCategoryInput('');
                        } else {
                          setFormCategory(e.target.value);
                        }
                      }}
                      className="modal-form-select"
                    >
                      {allCategories.map((cat) => (
                        <option key={cat} value={cat}>
                          {cat}
                        </option>
                      ))}
                      <option value="__add_new__">+ Tambah Kategori Baru...</option>
                    </select>
                  )}
                </div>

                <div className="form-group-item">
                  <div className="label-with-action">
                    <label>Satuan Unit</label>
                    {!isAddingUnit && (
                      <button
                        type="button"
                        onClick={() => {
                          setIsAddingUnit(true);
                          setNewUnitInput('');
                        }}
                        className="btn-text-action"
                      >
                        <Plus size={12} /> Satuan Baru
                      </button>
                    )}
                  </div>

                  {isAddingUnit ? (
                    <div className="inline-add-group">
                      <input
                        type="text"
                        placeholder="e.g. roll, lusin, ml..."
                        value={newUnitInput}
                        onChange={(e) => setNewUnitInput(e.target.value)}
                        className="modal-form-input inline-input"
                        autoFocus
                      />
                      <button
                        type="button"
                        onClick={() => {
                          if (newUnitInput.trim()) {
                            const trimmed = newUnitInput.trim();
                            if (!customUnits.includes(trimmed)) {
                              setCustomUnits([...customUnits, trimmed]);
                            }
                            setFormUnit(trimmed);
                            setIsAddingUnit(false);
                          }
                        }}
                        className="btn-inline-save"
                        title="Simpan Satuan"
                      >
                        <Check size={14} />
                      </button>
                      <button
                        type="button"
                        onClick={() => setIsAddingUnit(false)}
                        className="btn-inline-cancel"
                        title="Batal"
                      >
                        <X size={14} />
                      </button>
                    </div>
                  ) : (
                    <select
                      value={formUnit}
                      onChange={(e) => {
                        if (e.target.value === '__add_new__') {
                          setIsAddingUnit(true);
                          setNewUnitInput('');
                        } else {
                          setFormUnit(e.target.value);
                        }
                      }}
                      className="modal-form-select"
                    >
                      {allUnits.map((u) => (
                        <option key={u} value={u}>
                          {u}
                        </option>
                      ))}
                      <option value="__add_new__">+ Tambah Satuan Lain...</option>
                    </select>
                  )}
                </div>

                <div className="form-group-item">
                  <label>Harga Modal / Beli (Rp)</label>
                  <input
                    type="number"
                    value={formCostPrice}
                    onChange={(e) => setFormCostPrice(parseInt(e.target.value) || 0)}
                    className="modal-form-input"
                  />
                </div>

                <div className="form-group-item">
                  <label>Harga Jual di POS (Rp)</label>
                  <input
                    type="number"
                    value={formSellingPrice}
                    onChange={(e) => setFormSellingPrice(parseInt(e.target.value) || 0)}
                    className="modal-form-input"
                  />
                </div>

                <div className="form-group-item">
                  <label>Jumlah Stok</label>
                  <input
                    type="number"
                    value={formStock}
                    onChange={(e) => setFormStock(parseInt(e.target.value) || 0)}
                    className="modal-form-input"
                  />
                </div>

                <div className="form-group-item">
                  <label>Batas Minimum Stok</label>
                  <input
                    type="number"
                    value={formMinStock}
                    onChange={(e) => setFormMinStock(parseInt(e.target.value) || 0)}
                    className="modal-form-input"
                  />
                </div>

                {/* Drag and drop image upload in edit */}
                <div className="form-group-item full-width">
                  <label>Foto Produk (Drag &amp; Drop atau Pilih File)</label>
                  <input
                    type="file"
                    ref={fileInputRef}
                    accept="image/*"
                    style={{ display: 'none' }}
                    onChange={(e) => {
                      if (e.target.files && e.target.files[0]) {
                        handleFileUpload(e.target.files[0]);
                      }
                    }}
                  />

                  {formImageUrl ? (
                    <div className="image-preview-box">
                      <img src={formImageUrl} alt="Preview" className="preview-img" />
                      <div className="preview-info">
                        <span className="preview-title">Foto Produk Terpilih</span>
                        <div className="preview-actions">
                          <button
                            type="button"
                            onClick={() => fileInputRef.current?.click()}
                            className="btn-change-photo"
                          >
                            Ganti Foto
                          </button>
                          <button
                            type="button"
                            onClick={() => setFormImageUrl('')}
                            className="btn-delete-photo"
                            title="Hapus Foto"
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
                      </div>
                    </div>
                  ) : (
                    <div
                      onDragOver={(e) => {
                        e.preventDefault();
                        setIsDraggingFile(true);
                      }}
                      onDragLeave={() => setIsDraggingFile(false)}
                      onDrop={handleDrop}
                      onClick={() => fileInputRef.current?.click()}
                      className={`image-dropzone ${isDraggingFile ? 'dragging' : ''}`}
                    >
                      <UploadCloud size={28} className="dropzone-icon" />
                      <span className="dropzone-title">
                        Tarik &amp; Lepas foto di sini, atau <strong>Pilih File</strong>
                      </span>
                      <span className="dropzone-sub">Mendukung format JPG, PNG, WEBP</span>
                    </div>
                  )}
                </div>
              </div>

              {error && <div className="pos-error-box">{error}</div>}
            </div>

            <div className="modal-footer">
              <button
                type="button"
                onClick={() => setEditProduct(null)}
                className="btn-secondary"
                disabled={saving}
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleSaveEdit}
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
                    <span>Simpan Perubahan</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>,
        document.body
      )}

      {/* ── MODAL 3: RESTOCK & STOK ADJUSTMENT (PORTAL TO BODY) ── */}
      {stockProduct && createPortal(
        <div className="modal-overlay">
          <div className="modal-card animate-fade-in">
            <div className="modal-header">
              <div className="modal-title-wrap">
                <ArrowUpRight size={20} className="text-teal" />
                <h3>Penyesuaian Stok: {stockProduct.name}</h3>
              </div>
              <button onClick={() => setStockProduct(null)} className="btn-close">
                <X size={18} />
              </button>
            </div>

            <div className="modal-body">
              <div className="product-summary-box">
                <span className="sku-badge">{stockProduct.code}</span>
                <h4>{stockProduct.name}</h4>
                <p className="current-stock-info">
                  Stok Saat Ini: <strong>{stockProduct.stock} {stockProduct.unit}</strong> (Batas Min: {stockProduct.minStock})
                </p>
              </div>

              <div className="adjust-form">
                <label className="section-label">Jenis Penyesuaian:</label>
                <div className="adjust-type-chips">
                  <button
                    type="button"
                    onClick={() => setAdjustReason('restock')}
                    className={`chip-btn ${adjustReason === 'restock' ? 'active' : ''}`}
                  >
                    <ArrowUpRight size={14} />
                    <span>Restock / Kulakan (+)</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setAdjustReason('damaged')}
                    className={`chip-btn ${adjustReason === 'damaged' ? 'active' : ''}`}
                  >
                    <ArrowDownRight size={14} />
                    <span>Barang Rusak / Expired (-)</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setAdjustReason('correction')}
                    className={`chip-btn ${adjustReason === 'correction' ? 'active' : ''}`}
                  >
                    <span>Koreksi Opname</span>
                  </button>
                </div>

                <label className="section-label margin-top">
                  Jumlah Penyesuaian ({stockProduct.unit}):
                </label>
                <input
                  type="number"
                  value={adjustQty}
                  onChange={(e) => setAdjustQty(parseInt(e.target.value) || 0)}
                  className="modal-form-input"
                />

                {error && <div className="pos-error-box">{error}</div>}
              </div>
            </div>

            <div className="modal-footer">
              <button
                type="button"
                onClick={() => setStockProduct(null)}
                className="btn-secondary"
                disabled={saving}
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleSaveRestock}
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
                    <span>Simpan Stok</span>
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

export default StockScreen;
