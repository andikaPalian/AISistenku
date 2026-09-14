import React, { useState, useEffect, useRef, useMemo } from 'react';
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
  Sparkles,
  Coffee,
  Box,
  Layers,
  ShieldCheck,
  ChevronDown,
  AlertCircle,
  Copy,
  SlidersHorizontal,
  ArrowUpDown,
  Zap,
  Store,
  RotateCcw,
} from 'lucide-react';
import { animateScreenEntrance } from '../lib/animations';
import { Pagination } from '../components/common/Pagination';
import { uploadImage, isCloudinaryUrl } from '../lib/cloudinary';
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

// Category aesthetic helpers
const getCategoryTheme = (category: string) => {
  const cat = (category || '').toLowerCase();
  if (cat.includes('kopi') || cat.includes('coffee')) {
    return { icon: Coffee, bg: '#fef3c7', text: '#92400e', border: '#fde68a' };
  }
  if (cat.includes('bubuk') || cat.includes('perisa') || cat.includes('sirup')) {
    return { icon: Sparkles, bg: '#f3e8ff', text: '#7e22ce', border: '#e9d5ff' };
  }
  if (cat.includes('kemasan') || cat.includes('cup') || cat.includes('box')) {
    return { icon: Box, bg: '#e0f2fe', text: '#0369a1', border: '#bae6fd' };
  }
  if (cat.includes('makanan') || cat.includes('pastry') || cat.includes('snack')) {
    return { icon: Layers, bg: '#ffedd5', text: '#c2410c', border: '#fed7aa' };
  }
  return { icon: Package, bg: '#f1f5f9', text: '#475569', border: '#e2e8f0' };
};

export const StockScreen: React.FC<StockScreenProps> = ({
  products,
  loading,
  onRestock,
  onAdjust,
  onCreateItem,
  onUpdateItem,
  onDeleteItem,
  refresh,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    animateScreenEntrance(containerRef.current);
  }, []);

  // Filter & Search states
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategoryTab, setSelectedCategoryTab] = useState<string>('Semua');
  const [statusFilter, setStatusFilter] = useState<'all' | 'low' | 'out' | 'safe'>('all');
  const [filterPosOnly, setFilterPosOnly] = useState<boolean>(false);
  const [sortBy, setSortBy] = useState<'name-asc' | 'stock-asc' | 'stock-desc' | 'valuation-desc' | 'price-asc'>('name-asc');
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [copiedSku, setCopiedSku] = useState<string | null>(null);
  const pageSize = 7;

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
  const [isQuickRestockModalOpen, setIsQuickRestockModalOpen] = useState<boolean>(false);
  const [editProduct, setEditProduct] = useState<Product | null>(null);
  const [stockProduct, setStockProduct] = useState<Product | null>(null);

  // Restock form state
  const [adjustQty, setAdjustQty] = useState<number>(10);
  const [adjustReason, setAdjustReason] = useState<'restock' | 'damaged' | 'correction'>('restock');
  const [adjustSupplier, setAdjustSupplier] = useState<string>('Supplier Utama');
  const [adjustNote, setAdjustNote] = useState<string>('');

  // Quick Restock Header Modal target
  const [quickRestockSelectedId, setQuickRestockSelectedId] = useState<string>('');

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
  const [uploading, setUploading] = useState(false);
  const [pendingUploadFile, setPendingUploadFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Available unique categories derived from active data + defaults
  const allCategories = useMemo(() => {
    return Array.from(new Set([...customCategories, ...products.map((p) => p.category).filter(Boolean)]));
  }, [customCategories, products]);

  const allUnits = useMemo(() => {
    return Array.from(new Set([...customUnits, ...products.map((p) => p.unit).filter(Boolean)]));
  }, [customUnits, products]);

  // Dynamic category counters
  const categoryCounts = useMemo(() => {
    const counts: Record<string, number> = { Semua: products.length };
    products.forEach((p) => {
      const cat = p.category || 'Lainnya';
      counts[cat] = (counts[cat] || 0) + 1;
    });
    return counts;
  }, [products]);

  // Primary active categories (only show categories that have items + defaults)
  const displayCategoryTabs = useMemo(() => {
    const presentCats = Array.from(new Set(products.map((p) => p.category).filter(Boolean)));
    const unique = ['Semua', ...presentCats];
    return unique;
  }, [products]);

  // Operational metrics
  const totalProducts = products.length;
  const lowStockProducts = useMemo(() => products.filter((p) => p.stock > 0 && p.stock <= p.minStock), [products]);
  const outOfStockProducts = useMemo(() => products.filter((p) => p.stock === 0), [products]);
  const safeStockProducts = useMemo(() => products.filter((p) => p.stock > p.minStock), [products]);

  // Total inventory valuation
  const totalValuation = useMemo(() => {
    return products.reduce((acc, p) => acc + (p.stock || 0) * (p.price || 0), 0);
  }, [products]);

  // Filtered & Sorted products
  const filteredProducts = useMemo(() => {
    return products
      .filter((p) => {
        // Search
        const query = searchQuery.trim().toLowerCase();
        const matchesSearch =
          !query ||
          p.name.toLowerCase().includes(query) ||
          (p.code && p.code.toLowerCase().includes(query)) ||
          (p.category && p.category.toLowerCase().includes(query));

        // Category Tab
        const matchesCategory = selectedCategoryTab === 'Semua' || p.category === selectedCategoryTab;

        // Status Filter
        let matchesStatus = true;
        if (statusFilter === 'low') matchesStatus = p.stock > 0 && p.stock <= p.minStock;
        else if (statusFilter === 'out') matchesStatus = p.stock === 0;
        else if (statusFilter === 'safe') matchesStatus = p.stock > p.minStock;

        // POS only filter
        let matchesPos = true;
        if (filterPosOnly) {
          const isPosCat = ['Kopi', 'Non-Kopi', 'Snack', 'Makanan'].includes(p.category);
          matchesPos = isPosCat || (p as any).isPosProduct;
        }

        return matchesSearch && matchesCategory && matchesStatus && matchesPos;
      })
      .sort((a, b) => {
        if (sortBy === 'stock-asc') return a.stock - b.stock;
        if (sortBy === 'stock-desc') return b.stock - a.stock;
        if (sortBy === 'valuation-desc') return (b.stock * (b.price || 0)) - (a.stock * (a.price || 0));
        if (sortBy === 'price-asc') return (a.price || 0) - (b.price || 0);
        return a.name.localeCompare(b.name, 'id-ID');
      });
  }, [products, searchQuery, selectedCategoryTab, statusFilter, filterPosOnly, sortBy]);

  const totalPages = Math.ceil(filteredProducts.length / pageSize) || 1;
  const paginatedProducts = useMemo(() => {
    return filteredProducts.slice((currentPage - 1) * pageSize, currentPage * pageSize);
  }, [filteredProducts, currentPage, pageSize]);

  // Handlers
  const handleSearchChange = (val: string) => {
    setSearchQuery(val);
    setCurrentPage(1);
  };

  const handleCategoryTabChange = (tab: string) => {
    setSelectedCategoryTab(tab);
    setCurrentPage(1);
  };

  const handleCopySku = (code?: string) => {
    if (!code) return;
    navigator.clipboard?.writeText(code);
    setCopiedSku(code);
    setTimeout(() => setCopiedSku(null), 1800);
  };

  const handleOpenCreateModal = () => {
    setError(null);
    setFormName('');
    setFormCategory(allCategories[0] || 'Bahan Baku');
    setFormUnit('kg');
    setFormCostPrice(20000);
    setFormSellingPrice(30000);
    setFormStock(10);
    setFormMinStock(5);
    setFormIsPos(false);
    setFormImageUrl('');
    setPendingUploadFile(null);
    setIsCreateModalOpen(true);
  };

  const handleOpenEditModal = (p: Product) => {
    setError(null);
    setEditProduct(p);
    setFormName(p.name);
    setFormCategory(p.category || 'Bahan Baku');
    setFormUnit(p.unit || 'pcs');
    setFormCostPrice(p.price || 0);
    setFormSellingPrice((p as any).sellingPrice || (p.price ? Math.round(p.price * 1.35) : 25000));
    setFormStock(p.stock);
    setFormMinStock(p.minStock);
    setFormIsPos(['Kopi', 'Non-Kopi', 'Snack', 'Makanan'].includes(p.category) || (p as any).isPosProduct);
    setFormImageUrl((p as any).image || '');
    setPendingUploadFile(null);
  };

  const handleOpenRestock = (p: Product) => {
    setError(null);
    setStockProduct(p);
    setAdjustQty(10);
    setAdjustReason('restock');
    setAdjustSupplier((p as any).supplier || 'Supplier Utama');
    setAdjustNote('');
  };

  const handleOpenQuickRestockAll = () => {
    setError(null);
    const firstLow = lowStockProducts[0] || products[0];
    setQuickRestockSelectedId(firstLow ? firstLow.id : '');
    setAdjustQty(10);
    setAdjustReason('restock');
    setAdjustSupplier('Supplier Utama');
    setAdjustNote('');
    setIsQuickRestockModalOpen(true);
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
    setPendingUploadFile(file);
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
        await onRestock(stockProduct.id, {
          quantity: adjustQty,
          cost_per_unit: stockProduct.price,
          supplier: adjustSupplier,
          note: adjustNote || 'Restock via UI Inventaris',
        });
      } else if (adjustReason === 'damaged') {
        const newQty = Math.max(0, stockProduct.stock - Math.abs(adjustQty));
        await onAdjust(stockProduct.id, {
          actual_quantity: newQty,
          reason: 'damaged',
          note: adjustNote || 'Barang rusak / kadaluarsa',
        });
      } else {
        const newQty = Math.max(0, adjustQty);
        await onAdjust(stockProduct.id, {
          actual_quantity: newQty,
          reason: 'correction',
          note: adjustNote || 'Koreksi stok fisik opname',
        });
      }
      await refresh();
      setStockProduct(null);
      setIsQuickRestockModalOpen(false);
    } catch (e: any) {
      setError(e?.error || 'Gagal menyimpan penyesuaian stok');
    } finally {
      setSaving(false);
    }
  };

  const handleSaveQuickRestockAll = async () => {
    const target = products.find((p) => p.id === quickRestockSelectedId);
    if (!target || adjustQty <= 0) return;
    setError(null);
    setSaving(true);
    try {
      await onRestock(target.id, {
        quantity: adjustQty,
        cost_per_unit: target.price,
        supplier: adjustSupplier,
        note: adjustNote || 'Restock cepat dari toolbar',
      });
      await refresh();
      setIsQuickRestockModalOpen(false);
    } catch (e: any) {
      setError(e?.error || 'Gagal melakukan restock cepat');
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
      let imageUrl: string | undefined = formImageUrl || undefined;

      if (pendingUploadFile) {
        setUploading(true);
        try {
          const res = await uploadImage(pendingUploadFile);
          imageUrl = res.url;
          setFormImageUrl(res.url);
        } catch (e: any) {
          setError(e?.error || 'Upload foto produk gagal');
          setSaving(false);
          setUploading(false);
          return;
        } finally {
          setUploading(false);
        }
      } else if (imageUrl && imageUrl.startsWith('data:')) {
        imageUrl = undefined;
      }

      if (onCreateItem) {
        await onCreateItem({
          name: formName.trim(),
          category: formCategory,
          price: Number(formCostPrice) || 0,
          sellingPrice: Number(formSellingPrice) || Number(formCostPrice),
          stock: Number(formStock) || 0,
          minStock: Number(formMinStock) || 0,
          unit: formUnit,
          isPosProduct: formIsPos,
          image: imageUrl,
        });
      }
      await refresh();
      setIsCreateModalOpen(false);
      setPendingUploadFile(null);
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
      let imageUrl: string | undefined = formImageUrl || undefined;

      if (pendingUploadFile) {
        setUploading(true);
        try {
          const res = await uploadImage(pendingUploadFile);
          imageUrl = res.url;
          setFormImageUrl(res.url);
        } catch (e: any) {
          setError(e?.error || 'Upload foto produk gagal');
          setSaving(false);
          setUploading(false);
          return;
        } finally {
          setUploading(false);
        }
      } else if (imageUrl && imageUrl.startsWith('data:')) {
        imageUrl = undefined;
      }

      if (onUpdateItem) {
        await onUpdateItem(editProduct.id, {
          name: formName.trim(),
          category: formCategory,
          price: Number(formCostPrice) || 0,
          sellingPrice: Number(formSellingPrice) || Number(formCostPrice),
          stock: Number(formStock) || 0,
          minStock: Number(formMinStock) || 0,
          unit: formUnit,
          image: imageUrl,
        } as any);
      }
      await refresh();
      setEditProduct(null);
      setPendingUploadFile(null);
    } catch (e: any) {
      setError(e?.error || 'Gagal mengupdate barang');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string, name: string) => {
    if (window.confirm(`Hapus "${name}" dari sistem inventaris toko?`)) {
      if (onDeleteItem) {
        await onDeleteItem(id);
        await refresh();
      }
    }
  };

  return (
    <div ref={containerRef} className="page-screen stock-screen-revamp">
      {/* ── 1. Screen Header Bar ── */}
      <header className="stock-header-wrap gsap-reveal">
        <div className="stock-header-info">
          <div className="stock-context-badge">
            <span className="live-pulse-dot"></span>
            <span className="context-text">Kedai Kopi Tiga Angkatan • Inventaris Real-Time</span>
          </div>
          <h1 className="stock-main-heading">Manajemen Stok &amp; Inventaris</h1>
          <p className="stock-main-desc">
            Pantau ketersediaan bahan baku, monitor nilai aset kulakan, dan lakukan restock cepat untuk kelancaran kasir.
          </p>
        </div>

        <div className="stock-header-actions">
          <button
            type="button"
            onClick={handleOpenQuickRestockAll}
            className="btn-stock-quick-restock"
            title="Lakukan restock bahan baku langsung"
          >
            <Zap size={16} className="text-emerald" />
            <span>Restock Cepat</span>
          </button>

          <button
            type="button"
            onClick={handleOpenCreateModal}
            className="btn-primary btn-stock-add"
            title="Tambah Barang / Bahan Baku Baru"
          >
            <Plus size={16} />
            <span>Tambah Barang / Bahan</span>
          </button>
        </div>
      </header>

      {/* ── 2. Executive Inventory Command Board (Replaces 3 identical slop cards) ── */}
      <section className="inventory-command-board gsap-reveal">
        {/* Left Card: Total Asset Valuation & Summary */}
        <div className="asset-valuation-card">
          <div className="valuation-card-header">
            <div className="valuation-title-group">
              <span className="valuation-eyebrow">ESTIMASI NILAI ASET INVENTARIS</span>
              <div className="valuation-figure-row">
                <span className="currency-prefix">Rp</span>
                <span className="valuation-number">{totalValuation.toLocaleString('id-ID')}</span>
              </div>
            </div>
            <div className="valuation-icon-badge">
              <Package size={22} />
            </div>
          </div>

          <div className="valuation-card-footer">
            <div className="val-stat-pill">
              <span className="stat-num">{totalProducts}</span>
              <span className="stat-label">Total SKU Terdaftar</span>
            </div>
            <div className="val-stat-divider"></div>
            <div className="val-stat-pill">
              <span className="stat-num">{safeStockProducts.length}</span>
              <span className="stat-label">Bahan Stok Aman</span>
            </div>
            <div className="val-stat-divider"></div>
            <div className="val-stat-pill">
              <span className={`stat-num ${lowStockProducts.length > 0 ? 'text-amber' : ''}`}>
                {lowStockProducts.length}
              </span>
              <span className="stat-label">Perlu Diorder</span>
            </div>
          </div>
        </div>

        {/* Right Card: AIsistenku Proactive Intelligence & Filter Controller */}
        <div className="ai-inventory-widget-card">
          <div className="ai-widget-header">
            <div className="ai-widget-brand">
              <div className="ai-bot-avatar-wrap">
                <img src="/iconAisistenku.png" alt="AIsistenku" className="ai-avatar-mini" />
              </div>
              <div className="ai-widget-titles">
                <span className="ai-widget-name">AIsistenku Copilot</span>
                <span className="ai-widget-sub">Deteksi Dini &amp; Kesehatan Stok</span>
              </div>
            </div>
            <span className="ai-live-tag">
              <Sparkles size={12} />
              <span>Real-time</span>
            </span>
          </div>

          <div className="ai-widget-message-box">
            {outOfStockProducts.length > 0 ? (
              <p className="ai-widget-text danger">
                <strong>🚨 Peringatan Kritis:</strong> Terdapat {outOfStockProducts.length} bahan yang habis (0 unit). Segera lakukan restock agar menu kasir tetap dapat dipesan.
              </p>
            ) : lowStockProducts.length > 0 ? (
              <p className="ai-widget-text warning">
                <strong>⚠️ Deteksi Stok Menipis:</strong> {lowStockProducts.map((p) => p.name).slice(0, 2).join(', ')} mendekati batas minimum. Disarankan order sebelum jam sibuk.
              </p>
            ) : (
              <p className="ai-widget-text success">
                <strong>✨ Kondisi Prima:</strong> Seluruh {totalProducts} bahan baku berada dalam ambang batas aman. Estimasi cadangan stok mencukupi operasional kedai.
              </p>
            )}
          </div>

          {/* Interactive Filter Pills */}
          <div className="ai-status-filter-pills">
            <button
              type="button"
              onClick={() => {
                setStatusFilter('all');
                setCurrentPage(1);
              }}
              className={`status-pill-btn ${statusFilter === 'all' ? 'active' : ''}`}
            >
              Semua ({totalProducts})
            </button>
            <button
              type="button"
              onClick={() => {
                setStatusFilter('safe');
                setCurrentPage(1);
              }}
              className={`status-pill-btn pill-safe ${statusFilter === 'safe' ? 'active' : ''}`}
            >
              <span className="pill-dot safe"></span>
              Aman ({safeStockProducts.length})
            </button>
            <button
              type="button"
              onClick={() => {
                setStatusFilter('low');
                setCurrentPage(1);
              }}
              className={`status-pill-btn pill-warn ${statusFilter === 'low' ? 'active' : ''}`}
            >
              <span className="pill-dot warn"></span>
              Menipis ({lowStockProducts.length})
            </button>
            <button
              type="button"
              onClick={() => {
                setStatusFilter('out');
                setCurrentPage(1);
              }}
              className={`status-pill-btn pill-danger ${statusFilter === 'out' ? 'active' : ''}`}
            >
              <span className="pill-dot danger"></span>
              Habis ({outOfStockProducts.length})
            </button>
          </div>
        </div>
      </section>

      {/* ── 3. Search, Quick Filters & Category Toolbar ── */}
      <section className="stock-control-panel card-base gsap-reveal">
        {/* Row 1: Search Bar + Quick Switches + Sorting */}
        <div className="panel-primary-row">
          <div className="search-field-wrapper">
            <Search size={16} className="search-field-icon" />
            <input
              ref={searchInputRef}
              type="text"
              placeholder="Cari nama barang, bahan baku, atau kode SKU (Ctrl+K)..."
              value={searchQuery}
              onChange={(e) => handleSearchChange(e.target.value)}
              className="stock-clean-search-input"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => handleSearchChange('')}
                className="btn-clear-search-clean"
                title="Hapus pencarian"
              >
                <X size={14} />
              </button>
            )}
          </div>

          <div className="panel-aux-controls">
            {/* POS Only Filter Toggle */}
            <button
              type="button"
              onClick={() => {
                setFilterPosOnly(!filterPosOnly);
                setCurrentPage(1);
              }}
              className={`btn-panel-toggle ${filterPosOnly ? 'active' : ''}`}
              title="Tampilkan hanya produk yang dijual langsung di POS kasir"
            >
              <Store size={14} />
              <span>Menu Kasir POS</span>
            </button>

            {/* Sort Selector */}
            <div className="sort-select-box">
              <ArrowUpDown size={14} className="sort-icon" />
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as any)}
                className="stock-sort-dropdown"
              >
                <option value="name-asc">Nama (A - Z)</option>
                <option value="stock-asc">Stok Terendah (Prioritas Restock)</option>
                <option value="stock-desc">Stok Terbanyak</option>
                <option value="valuation-desc">Nilai Aset Terbesar</option>
                <option value="price-asc">Harga Modal Terendah</option>
              </select>
            </div>
          </div>
        </div>

        {/* Row 2: Horizontal Clean Category Strip with Real Count Badges */}
        <div className="panel-categories-strip">
          <div className="categories-scroll-track">
            {displayCategoryTabs.map((cat) => {
              const count = categoryCounts[cat] ?? 0;
              const isActive = selectedCategoryTab === cat;
              return (
                <button
                  key={cat}
                  type="button"
                  onClick={() => handleCategoryTabChange(cat)}
                  className={`category-chip ${isActive ? 'active' : ''}`}
                >
                  <span className="chip-name">{cat}</span>
                  <span className="chip-badge">{count}</span>
                </button>
              );
            })}
          </div>
        </div>
      </section>

      {/* ── 4. High-Craft Inventory Data Table ── */}
      <section className="stock-table-wrapper card-base gsap-reveal">
        <div className="table-responsive">
          <table className="inventory-table">
            <thead>
              <tr>
                <th style={{ width: '28%' }}>Item &amp; Kode SKU</th>
                <th style={{ width: '15%' }}>Kategori</th>
                <th style={{ width: '18%' }}>Stok Tersedia</th>
                <th style={{ width: '11%' }}>Batas Min</th>
                <th style={{ width: '14%' }}>Harga &amp; Valuasi</th>
                <th style={{ width: '10%' }}>Status</th>
                <th style={{ width: '14%', textAlign: 'right' }}>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={7}>
                    <div className="table-state-box">
                      <Loader2 size={24} className="spin text-emerald" />
                      <span>Memuat data inventaris toko...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredProducts.length === 0 ? (
                <tr>
                  <td colSpan={7}>
                    <div className="table-state-box empty">
                      <div className="empty-icon-circle">
                        <Package size={28} />
                      </div>
                      <h4 className="empty-title">Tidak ada barang inventaris yang sesuai</h4>
                      <p className="empty-desc">
                        Coba sesuaikan kata kunci pencarian atau ubah filter kategori/status di atas.
                      </p>
                      <button
                        type="button"
                        onClick={() => {
                          setSearchQuery('');
                          setSelectedCategoryTab('Semua');
                          setStatusFilter('all');
                          setFilterPosOnly(false);
                        }}
                        className="btn-secondary btn-sm"
                      >
                        Reset Semua Filter
                      </button>
                    </div>
                  </td>
                </tr>
              ) : (
                paginatedProducts.map((product) => {
                  const isOutOfStock = product.stock === 0;
                  const isLowStock = product.stock > 0 && product.stock <= product.minStock;
                  const isSafeStock = product.stock > product.minStock;
                  const theme = getCategoryTheme(product.category);
                  const IconComp = theme.icon;

                  // Capacity calculations
                  const minThreshold = product.minStock || 1;
                  const ratio = (product.stock / (minThreshold * 2.5)) * 100;
                  const barFill = Math.min(100, Math.max(0, ratio));
                  const itemValuation = (product.stock || 0) * (product.price || 0);

                  const isPosItem =
                    ['Kopi', 'Non-Kopi', 'Snack', 'Makanan'].includes(product.category) ||
                    (product as any).isPosProduct;

                  return (
                    <tr
                      key={product.id}
                      className={`inventory-row ${
                        isOutOfStock ? 'row-out-of-stock' : isLowStock ? 'row-low-stock' : ''
                      }`}
                    >
                      {/* 1. Item Name & SKU */}
                      <td>
                        <div className="item-profile-cell">
                          {product.image ? (
                            <img
                              src={product.image}
                              alt={product.name}
                              className="item-avatar-img"
                              loading="lazy"
                            />
                          ) : (
                            <div
                              className="item-avatar-placeholder"
                              style={{ backgroundColor: theme.bg, color: theme.text }}
                            >
                              <IconComp size={18} />
                            </div>
                          )}

                          <div className="item-meta-group">
                            <div className="item-title-row">
                              <span className="item-main-title">{product.name}</span>
                              {isPosItem && <span className="tag-pos-kasir">POS</span>}
                            </div>

                            <div className="item-sku-row">
                              <span className="sku-mono-tag">{product.code || 'NO-SKU'}</span>
                              <button
                                type="button"
                                onClick={() => handleCopySku(product.code)}
                                className="btn-copy-sku"
                                title="Salin Kode SKU"
                              >
                                {copiedSku === product.code ? (
                                  <Check size={11} className="text-emerald" />
                                ) : (
                                  <Copy size={11} />
                                )}
                              </button>
                            </div>
                          </div>
                        </div>
                      </td>

                      {/* 2. Kategori */}
                      <td>
                        <span
                          className="category-badge-chip"
                          style={{
                            backgroundColor: theme.bg,
                            color: theme.text,
                            borderColor: theme.border,
                          }}
                        >
                          {product.category}
                        </span>
                      </td>

                      {/* 3. Level Stok & Progress Buffer */}
                      <td>
                        <div className="stock-level-cell">
                          <div className="stock-number-row">
                            <span className="stock-bold-qty">
                              {Number.isInteger(product.stock) ? product.stock : product.stock.toFixed(2)}
                            </span>
                            <span className="stock-unit-label">{product.unit}</span>
                          </div>

                          <div className="stock-meter-track">
                            <div
                              className={`stock-meter-fill ${
                                isOutOfStock ? 'fill-red' : isLowStock ? 'fill-amber' : 'fill-green'
                              }`}
                              style={{ width: `${barFill}%` }}
                            ></div>
                          </div>

                          <span className="stock-buffer-caption">
                            {isOutOfStock
                              ? 'Habis total'
                              : isLowStock
                              ? `Tersisa sedikit (Min: ${product.minStock})`
                              : `+${(product.stock - product.minStock).toFixed(1)} di atas batas`}
                          </span>
                        </div>
                      </td>

                      {/* 4. Batas Minimum */}
                      <td>
                        <span className="min-threshold-badge">
                          {product.minStock} {product.unit}
                        </span>
                      </td>

                      {/* 5. Harga Modal & Valuasi */}
                      <td>
                        <div className="pricing-meta-cell">
                          <span className="unit-cost-price">
                            Rp {(product.price || 0).toLocaleString('id-ID')}
                            <span className="unit-cost-sub">/{product.unit}</span>
                          </span>
                          <span className="total-asset-val">
                            Aset: Rp {itemValuation.toLocaleString('id-ID')}
                          </span>
                        </div>
                      </td>

                      {/* 6. Status Chip */}
                      <td>
                        {isOutOfStock ? (
                          <span className="status-pill-chip chip-danger">
                            <span className="status-dot red"></span>
                            Habis
                          </span>
                        ) : isLowStock ? (
                          <span className="status-pill-chip chip-warning">
                            <span className="status-dot amber"></span>
                            Menipis
                          </span>
                        ) : (
                          <span className="status-pill-chip chip-success">
                            <span className="status-dot green"></span>
                            Aman
                          </span>
                        )}
                      </td>

                      {/* 7. Action Buttons */}
                      <td style={{ textAlign: 'right' }}>
                        <div className="table-actions-group">
                          <button
                            type="button"
                            onClick={() => handleOpenRestock(product)}
                            className="btn-action-restock"
                            title="Restock atau Sesuaikan Stok"
                          >
                            <Zap size={13} />
                            <span>Restock</span>
                          </button>

                          <button
                            type="button"
                            onClick={() => handleOpenEditModal(product)}
                            className="btn-action-edit"
                            title="Ubah Detail & Harga"
                          >
                            <Edit2 size={13} />
                          </button>

                          <button
                            type="button"
                            onClick={() => handleDelete(product.id, product.name)}
                            className="btn-action-delete"
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

        {/* Table Footer with Summary & Pagination */}
        <div className="table-footer-bar">
          <div className="table-footer-info">
            <span>
              Menampilkan{' '}
              <strong>
                {filteredProducts.length === 0 ? 0 : (currentPage - 1) * pageSize + 1}-
                {Math.min(currentPage * pageSize, filteredProducts.length)}
              </strong>{' '}
              dari <strong>{filteredProducts.length}</strong> bahan inventaris
            </span>
          </div>

          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            totalItems={filteredProducts.length}
            pageSize={pageSize}
            onPageChange={setCurrentPage}
          />
        </div>
      </section>

      {/* ── MODAL 1: TAMBAH BARANG / BAHAN BAKU BARU ── */}
      {isCreateModalOpen &&
        createPortal(
          <div className="modal-overlay" onClick={() => setIsCreateModalOpen(false)}>
            <div
              className="modal-card stock-revamp-modal animate-fade-in"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="modal-header">
                <div className="modal-title-wrap">
                  <div className="modal-header-icon-box">
                    <Plus size={18} />
                  </div>
                  <div>
                    <h3>Tambah Barang &amp; Bahan Baku</h3>
                    <p className="modal-sub">Daftarkan bahan baku atau menu baru langsung ke sistem POS</p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setIsCreateModalOpen(false)}
                  className="btn-close"
                  title="Tutup Modal"
                >
                  <X size={18} />
                </button>
              </div>

              <div className="modal-body">
                <div className="form-sections-grid">
                  {/* Field 1: Nama Barang */}
                  <div className="form-field-group full-width">
                    <label className="field-label">Nama Barang / Bahan Baku *</label>
                    <input
                      type="text"
                      placeholder="e.g. Biji Kopi Arabika Gayo / Sirup Karamel Monin"
                      value={formName}
                      onChange={(e) => setFormName(e.target.value)}
                      className="field-input"
                      autoFocus
                    />
                  </div>

                  {/* Field 2: Kategori */}
                  <div className="form-field-group">
                    <div className="field-label-with-action">
                      <label className="field-label">Kategori</label>
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
                          placeholder="Nama kategori..."
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
                              if (!customCategories.includes(trimmed)) {
                                setCustomCategories([...customCategories, trimmed]);
                              }
                              setFormCategory(trimmed);
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
                        className="field-select"
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

                  {/* Field 3: Satuan Unit */}
                  <div className="form-field-group">
                    <div className="field-label-with-action">
                      <label className="field-label">Satuan Unit</label>
                      {!isAddingUnit && (
                        <button
                          type="button"
                          onClick={() => {
                            setIsAddingUnit(true);
                            setNewUnitInput('');
                          }}
                          className="btn-inline-link"
                        >
                          + Satuan Baru
                        </button>
                      )}
                    </div>

                    {isAddingUnit ? (
                      <div className="inline-add-wrapper">
                        <input
                          type="text"
                          placeholder="e.g. roll, botol, pack..."
                          value={newUnitInput}
                          onChange={(e) => setNewUnitInput(e.target.value)}
                          className="field-input inline-field"
                          autoFocus
                        />
                        <button
                          type="button"
                          onClick={() => {
                            const trimmed = newUnitInput.trim();
                            if (trimmed) {
                              if (!customUnits.includes(trimmed)) {
                                setCustomUnits([...customUnits, trimmed]);
                              }
                              setFormUnit(trimmed);
                              setIsAddingUnit(false);
                            }
                          }}
                          className="btn-inline-confirm"
                          title="Simpan Satuan"
                        >
                          <Check size={14} />
                        </button>
                        <button
                          type="button"
                          onClick={() => setIsAddingUnit(false)}
                          className="btn-inline-dismiss"
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
                        className="field-select"
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

                  {/* Field 4 & 5: Stok Awal & Batas Minimum */}
                  <div className="form-field-group">
                    <label className="field-label">Jumlah Stok Awal ({formUnit})</label>
                    <input
                      type="number"
                      value={formStock}
                      onChange={(e) => setFormStock(parseFloat(e.target.value) || 0)}
                      className="field-input"
                      min="0"
                      step="any"
                    />
                  </div>

                  <div className="form-field-group">
                    <label className="field-label">Batas Minimum Peringatan ({formUnit})</label>
                    <input
                      type="number"
                      value={formMinStock}
                      onChange={(e) => setFormMinStock(parseFloat(e.target.value) || 0)}
                      className="field-input"
                      min="0"
                      step="any"
                    />
                    <span className="field-hint">Alert muncul saat stok di bawah angka ini</span>
                  </div>

                  {/* Field 6 & 7: Harga Modal & Harga Jual */}
                  <div className="form-field-group">
                    <label className="field-label">Harga Modal / Beli per {formUnit} (Rp)</label>
                    <input
                      type="number"
                      value={formCostPrice}
                      onChange={(e) => setFormCostPrice(parseInt(e.target.value) || 0)}
                      className="field-input"
                      min="0"
                    />
                  </div>

                  <div className="form-field-group">
                    <label className="field-label">Harga Jual di Kasir POS (Rp)</label>
                    <input
                      type="number"
                      value={formSellingPrice}
                      onChange={(e) => setFormSellingPrice(parseInt(e.target.value) || 0)}
                      className="field-input"
                      min="0"
                    />
                  </div>

                  {/* Field 8: POS Integration Toggle */}
                  <div className="form-field-group full-width">
                    <label className="pos-toggle-card">
                      <input
                        type="checkbox"
                        checked={formIsPos}
                        onChange={(e) => setFormIsPos(e.target.checked)}
                        className="pos-toggle-checkbox"
                      />
                      <div className="pos-toggle-info">
                        <span className="pos-toggle-heading">
                          Tampilkan di Menu Penjualan POS Kasir
                        </span>
                        <span className="pos-toggle-sub">
                          Produk ini akan muncul sebagai menu kasir dan dapat dipesan langsung oleh pelanggan.
                        </span>
                      </div>
                    </label>
                  </div>

                  {/* Field 9: Photo Drag & Drop Uploader */}
                  <div className="form-field-group full-width">
                    <label className="field-label">Foto Produk (Opsional)</label>
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
                      <div className="photo-preview-card">
                        <img src={formImageUrl} alt="Preview" className="preview-img-square" />
                        <div className="preview-details">
                          <span className="preview-file-name">Foto Produk Terpilih</span>
                          <span className="preview-file-sub">Siap diunggah ke sistem</span>
                          <div className="preview-actions-row">
                            <button
                              type="button"
                              onClick={() => fileInputRef.current?.click()}
                              className="btn-secondary btn-sm"
                            >
                              Ganti Foto
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                setFormImageUrl('');
                                setPendingUploadFile(null);
                              }}
                              className="btn-danger-outline btn-sm"
                              title="Hapus Foto"
                            >
                              <Trash2 size={13} />
                              <span>Hapus</span>
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
                        className={`upload-zone-clean ${isDraggingFile ? 'dragging' : ''}`}
                      >
                        <div className="upload-icon-circle">
                          <UploadCloud size={22} />
                        </div>
                        <span className="upload-primary-text">
                          Tarik foto ke sini atau <strong>Pilih File</strong>
                        </span>
                        <span className="upload-secondary-text">
                          Mendukung format JPG, PNG, WebP hingga 5MB
                        </span>
                      </div>
                    )}
                  </div>
                </div>

                {error && <div className="modal-error-alert">{error}</div>}
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
                      <span>{uploading ? 'Mengunggah foto…' : 'Menyimpan…'}</span>
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

      {/* ── MODAL 2: EDIT DETAIL & HARGA ── */}
      {editProduct &&
        createPortal(
          <div className="modal-overlay" onClick={() => setEditProduct(null)}>
            <div
              className="modal-card stock-revamp-modal animate-fade-in"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="modal-header">
                <div className="modal-title-wrap">
                  <div className="modal-header-icon-box">
                    <Edit2 size={18} />
                  </div>
                  <div>
                    <h3>Edit Detail Barang</h3>
                    <p className="modal-sub">Perbarui nama, batas stok, atau harga jual menu</p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setEditProduct(null)}
                  className="btn-close"
                  title="Tutup Modal"
                >
                  <X size={18} />
                </button>
              </div>

              <div className="modal-body">
                <div className="form-sections-grid">
                  <div className="form-field-group full-width">
                    <label className="field-label">Nama Barang / Bahan Baku</label>
                    <input
                      type="text"
                      value={formName}
                      onChange={(e) => setFormName(e.target.value)}
                      className="field-input"
                    />
                  </div>

                  <div className="form-field-group">
                    <label className="field-label">Kategori</label>
                    <select
                      value={formCategory}
                      onChange={(e) => setFormCategory(e.target.value)}
                      className="field-select"
                    >
                      {allCategories.map((cat) => (
                        <option key={cat} value={cat}>
                          {cat}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-field-group">
                    <label className="field-label">Satuan Unit</label>
                    <select
                      value={formUnit}
                      onChange={(e) => setFormUnit(e.target.value)}
                      className="field-select"
                    >
                      {allUnits.map((u) => (
                        <option key={u} value={u}>
                          {u}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-field-group">
                    <label className="field-label">Jumlah Stok ({formUnit})</label>
                    <input
                      type="number"
                      value={formStock}
                      onChange={(e) => setFormStock(parseFloat(e.target.value) || 0)}
                      className="field-input"
                      step="any"
                    />
                  </div>

                  <div className="form-field-group">
                    <label className="field-label">Batas Minimum Peringatan</label>
                    <input
                      type="number"
                      value={formMinStock}
                      onChange={(e) => setFormMinStock(parseFloat(e.target.value) || 0)}
                      className="field-input"
                      step="any"
                    />
                  </div>

                  <div className="form-field-group">
                    <label className="field-label">Harga Modal / Beli (Rp)</label>
                    <input
                      type="number"
                      value={formCostPrice}
                      onChange={(e) => setFormCostPrice(parseInt(e.target.value) || 0)}
                      className="field-input"
                    />
                  </div>

                  <div className="form-field-group">
                    <label className="field-label">Harga Jual POS (Rp)</label>
                    <input
                      type="number"
                      value={formSellingPrice}
                      onChange={(e) => setFormSellingPrice(parseInt(e.target.value) || 0)}
                      className="field-input"
                    />
                  </div>

                  {/* Foto Produk Edit */}
                  <div className="form-field-group full-width">
                    <label className="field-label">Foto Produk</label>
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
                      <div className="photo-preview-card">
                        <img src={formImageUrl} alt="Preview" className="preview-img-square" />
                        <div className="preview-details">
                          <span className="preview-file-name">Foto Produk Aktif</span>
                          <div className="preview-actions-row">
                            <button
                              type="button"
                              onClick={() => fileInputRef.current?.click()}
                              className="btn-secondary btn-sm"
                            >
                              Ganti Foto
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                setFormImageUrl('');
                                setPendingUploadFile(null);
                              }}
                              className="btn-danger-outline btn-sm"
                            >
                              Hapus Foto
                            </button>
                          </div>
                        </div>
                      </div>
                    ) : (
                      <div
                        onClick={() => fileInputRef.current?.click()}
                        className="upload-zone-clean"
                      >
                        <UploadCloud size={20} className="text-muted" />
                        <span className="upload-primary-text">Pilih foto baru untuk produk ini</span>
                      </div>
                    )}
                  </div>
                </div>

                {error && <div className="modal-error-alert">{error}</div>}
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
                      <span>{uploading ? 'Mengunggah foto…' : 'Menyimpan…'}</span>
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

      {/* ── MODAL 3: RESTOCK & PENYESUAIAN STOK CEPAT (PER ITEM) ── */}
      {stockProduct &&
        createPortal(
          <div className="modal-overlay" onClick={() => setStockProduct(null)}>
            <div
              className="modal-card stock-adjust-modal animate-fade-in"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="modal-header">
                <div className="modal-title-wrap">
                  <div className="modal-header-icon-box green">
                    <Zap size={18} />
                  </div>
                  <div>
                    <h3>Restock &amp; Penyesuaian Stok</h3>
                    <p className="modal-sub">Catat stok masuk dari supplier atau koreksi fisik opname</p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setStockProduct(null)}
                  className="btn-close"
                  title="Tutup Modal"
                >
                  <X size={18} />
                </button>
              </div>

              <div className="modal-body">
                {/* Product Summary Header Card */}
                <div className="adjust-item-summary">
                  <div className="summary-left">
                    <span className="summary-sku-tag">{stockProduct.code || 'SKU'}</span>
                    <h4 className="summary-name">{stockProduct.name}</h4>
                    <span className="summary-cat">{stockProduct.category}</span>
                  </div>
                  <div className="summary-right">
                    <span className="summary-stock-label">Stok Saat Ini</span>
                    <span className="summary-stock-value">
                      {stockProduct.stock} {stockProduct.unit}
                    </span>
                    <span className="summary-min-label">Batas Min: {stockProduct.minStock}</span>
                  </div>
                </div>

                {/* Adjustment Mode Switcher */}
                <div className="adjust-type-segmented">
                  <button
                    type="button"
                    onClick={() => setAdjustReason('restock')}
                    className={`segment-btn ${adjustReason === 'restock' ? 'active' : ''}`}
                  >
                    <ArrowUpRight size={14} />
                    <span>Restock Kulakan (+)</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setAdjustReason('damaged')}
                    className={`segment-btn ${adjustReason === 'damaged' ? 'active' : ''}`}
                  >
                    <ArrowDownRight size={14} />
                    <span>Barang Rusak (-)</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setAdjustReason('correction')}
                    className={`segment-btn ${adjustReason === 'correction' ? 'active' : ''}`}
                  >
                    <RotateCcw size={14} />
                    <span>Stok Opname (=)</span>
                  </button>
                </div>

                {/* Quantity Input with Quick Stepper Presets */}
                <div className="adjust-qty-section">
                  <label className="field-label">
                    {adjustReason === 'correction'
                      ? `Jumlah Stok Fisik Sebenarnya (${stockProduct.unit}):`
                      : `Jumlah ${adjustReason === 'restock' ? 'Penambahan' : 'Pengurangan'} (${stockProduct.unit}):`}
                  </label>

                  <div className="qty-input-stepper-row">
                    <button
                      type="button"
                      onClick={() => setAdjustQty(Math.max(1, adjustQty - 1))}
                      className="btn-stepper"
                    >
                      -
                    </button>
                    <input
                      type="number"
                      value={adjustQty}
                      onChange={(e) => setAdjustQty(parseFloat(e.target.value) || 0)}
                      className="field-input stepper-input"
                      step="any"
                      min="1"
                    />
                    <button
                      type="button"
                      onClick={() => setAdjustQty(adjustQty + 1)}
                      className="btn-stepper"
                    >
                      +
                    </button>
                  </div>

                  {/* Preset Stepper Buttons */}
                  <div className="quick-presets-chips">
                    {[5, 10, 20, 50, 100].map((num) => (
                      <button
                        key={num}
                        type="button"
                        onClick={() => setAdjustQty(num)}
                        className={`chip-preset ${adjustQty === num ? 'active' : ''}`}
                      >
                        +{num} {stockProduct.unit}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Calculation Callout Preview */}
                <div className="adjust-calculation-preview">
                  <div className="preview-row">
                    <span className="calc-label">Proyeksi Stok Baru:</span>
                    <span className="calc-value highlight">
                      {adjustReason === 'restock'
                        ? stockProduct.stock + adjustQty
                        : adjustReason === 'damaged'
                        ? Math.max(0, stockProduct.stock - adjustQty)
                        : adjustQty}{' '}
                      {stockProduct.unit}
                    </span>
                  </div>
                  {adjustReason === 'restock' && (
                    <div className="preview-row">
                      <span className="calc-label">Estimasi Nilai Kulakan:</span>
                      <span className="calc-value">
                        Rp {(adjustQty * (stockProduct.price || 0)).toLocaleString('id-ID')}
                      </span>
                    </div>
                  )}
                </div>

                {/* Optional Supplier & Notes */}
                {adjustReason === 'restock' && (
                  <div className="form-field-group" style={{ marginTop: 14 }}>
                    <label className="field-label">Nama Supplier / Grosir</label>
                    <input
                      type="text"
                      placeholder="e.g. CV Biji Kopi Nusantara"
                      value={adjustSupplier}
                      onChange={(e) => setAdjustSupplier(e.target.value)}
                      className="field-input"
                    />
                  </div>
                )}

                <div className="form-field-group" style={{ marginTop: 12 }}>
                  <label className="field-label">Catatan Operasional (Opsional)</label>
                  <input
                    type="text"
                    placeholder="e.g. Restock rutin persiapan akhir pekan"
                    value={adjustNote}
                    onChange={(e) => setAdjustNote(e.target.value)}
                    className="field-input"
                  />
                </div>

                {error && <div className="modal-error-alert">{error}</div>}
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
                  className="btn-primary btn-save-restock"
                  disabled={saving}
                >
                  {saving ? (
                    <>
                      <Loader2 size={16} className="spin" />
                      <span>Menyimpan Stok…</span>
                    </>
                  ) : (
                    <>
                      <Check size={16} />
                      <span>Konfirmasi &amp; Simpan Stok</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>,
          document.body
        )}

      {/* ── MODAL 4: RESTOCK CEPAT DARI TOOLBAR HEADER ── */}
      {isQuickRestockModalOpen &&
        createPortal(
          <div className="modal-overlay" onClick={() => setIsQuickRestockModalOpen(false)}>
            <div
              className="modal-card stock-adjust-modal animate-fade-in"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="modal-header">
                <div className="modal-title-wrap">
                  <div className="modal-header-icon-box green">
                    <Zap size={18} />
                  </div>
                  <div>
                    <h3>Restock Cepat Inventaris</h3>
                    <p className="modal-sub">Pilih bahan dan catat penambahan stok langsung</p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setIsQuickRestockModalOpen(false)}
                  className="btn-close"
                  title="Tutup Modal"
                >
                  <X size={18} />
                </button>
              </div>

              <div className="modal-body">
                <div className="form-field-group">
                  <label className="field-label">Pilih Bahan Baku / Barang *</label>
                  <select
                    value={quickRestockSelectedId}
                    onChange={(e) => setQuickRestockSelectedId(e.target.value)}
                    className="field-select"
                  >
                    {products.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.name} (Stok: {p.stock} {p.unit})
                      </option>
                    ))}
                  </select>
                </div>

                {(() => {
                  const targetItem = products.find((p) => p.id === quickRestockSelectedId);
                  if (!targetItem) return null;

                  return (
                    <>
                      <div className="adjust-item-summary" style={{ marginTop: 14 }}>
                        <div className="summary-left">
                          <span className="summary-sku-tag">{targetItem.code || 'SKU'}</span>
                          <h4 className="summary-name">{targetItem.name}</h4>
                        </div>
                        <div className="summary-right">
                          <span className="summary-stock-label">Stok Saat Ini</span>
                          <span className="summary-stock-value">
                            {targetItem.stock} {targetItem.unit}
                          </span>
                        </div>
                      </div>

                      <div className="adjust-qty-section" style={{ marginTop: 16 }}>
                        <label className="field-label">Jumlah Restock Masuk ({targetItem.unit}):</label>
                        <div className="qty-input-stepper-row">
                          <button
                            type="button"
                            onClick={() => setAdjustQty(Math.max(1, adjustQty - 1))}
                            className="btn-stepper"
                          >
                            -
                          </button>
                          <input
                            type="number"
                            value={adjustQty}
                            onChange={(e) => setAdjustQty(parseFloat(e.target.value) || 0)}
                            className="field-input stepper-input"
                            step="any"
                            min="1"
                          />
                          <button
                            type="button"
                            onClick={() => setAdjustQty(adjustQty + 1)}
                            className="btn-stepper"
                          >
                            +
                          </button>
                        </div>

                        <div className="quick-presets-chips">
                          {[5, 10, 25, 50, 100].map((num) => (
                            <button
                              key={num}
                              type="button"
                              onClick={() => setAdjustQty(num)}
                              className={`chip-preset ${adjustQty === num ? 'active' : ''}`}
                            >
                              +{num} {targetItem.unit}
                            </button>
                          ))}
                        </div>
                      </div>

                      <div className="adjust-calculation-preview" style={{ marginTop: 14 }}>
                        <div className="preview-row">
                          <span className="calc-label">Stok Setelah Restock:</span>
                          <span className="calc-value highlight">
                            {targetItem.stock + adjustQty} {targetItem.unit}
                          </span>
                        </div>
                        <div className="preview-row">
                          <span className="calc-label">Estimasi Nilai Kulakan:</span>
                          <span className="calc-value">
                            Rp {(adjustQty * (targetItem.price || 0)).toLocaleString('id-ID')}
                          </span>
                        </div>
                      </div>

                      <div className="form-field-group" style={{ marginTop: 14 }}>
                        <label className="field-label">Supplier / Grosir</label>
                        <input
                          type="text"
                          placeholder="e.g. Supplier Utama"
                          value={adjustSupplier}
                          onChange={(e) => setAdjustSupplier(e.target.value)}
                          className="field-input"
                        />
                      </div>
                    </>
                  );
                })()}

                {error && <div className="modal-error-alert">{error}</div>}
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  onClick={() => setIsQuickRestockModalOpen(false)}
                  className="btn-secondary"
                  disabled={saving}
                >
                  Batal
                </button>
                <button
                  type="button"
                  onClick={handleSaveQuickRestockAll}
                  className="btn-primary btn-save-restock"
                  disabled={saving}
                >
                  {saving ? (
                    <>
                      <Loader2 size={16} className="spin" />
                      <span>Menyimpan Restock…</span>
                    </>
                  ) : (
                    <>
                      <Check size={16} />
                      <span>Simpan &amp; Tambah Stok</span>
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
