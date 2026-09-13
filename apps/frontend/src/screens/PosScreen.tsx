import React, { useState, useEffect, useRef } from 'react';
import { Product, CartItem } from '../types';
import {
  Search,
  ShoppingBag,
  Plus,
  Minus,
  Trash2,
  CheckCircle2,
  QrCode,
  Banknote,
  Printer,
  X,
  Loader2,
  Copy,
  Check,
  Building2,
  ArrowLeft,
  Store,
  ChevronRight,
  Receipt,
  UtensilsCrossed,
  User,
  Clock,
} from 'lucide-react';
import { getStoredUser } from '../lib/auth';
import { QrisStandee } from '../components/pos/QrisStandee';
import './PosScreen.css';

interface PosScreenProps {
  products: Product[];
  productsLoading: boolean;
  onCheckout: (payload: {
    items: CartItem[];
    paymentMethod: 'qris' | 'cash' | 'transfer';
    orderType: string;
    cashGiven: number;
    change: number;
  }) => Promise<{ order_id: string; order_code: string; total_amount: number }>;
  cart: CartItem[];
  setCart: React.Dispatch<React.SetStateAction<CartItem[]>>;
}

const BANK_OPTIONS = [
  { id: 'bca', name: 'BCA Virtual Account', prefix: '8077708', logo: 'BCA' },
  { id: 'mandiri', name: 'Mandiri Virtual Account', prefix: '8890808', logo: 'MANDIRI' },
  { id: 'bri', name: 'BRI BRIVA', prefix: '123408', logo: 'BRI' },
  { id: 'bni', name: 'BNI Virtual Account', prefix: '98808', logo: 'BNI' },
];

export const PosScreen: React.FC<PosScreenProps> = ({
  products,
  productsLoading,
  onCheckout,
  cart,
  setCart,
}) => {
  const searchInputRef = useRef<HTMLInputElement>(null);

  const [selectedCategory, setSelectedCategory] = useState<string>('Semua');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [sidebarStep, setSidebarStep] = useState<'cart' | 'payment' | 'receipt'>('cart');
  const [paymentMethod, setPaymentMethod] = useState<'qris' | 'cash' | 'transfer'>('qris');
  const [selectedBank, setSelectedBank] = useState<string>('bca');
  const [cashAmount, setCashAmount] = useState<string>('');
  const [orderType, setOrderType] = useState<string>('Dine In');
  const [customerNote, setCustomerNote] = useState<string>('Meja 04');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [copiedVA, setCopiedVA] = useState(false);
  const [completedOrder, setCompletedOrder] = useState<{
    order_id: string;
    order_code: string;
    total_amount: number;
  } | null>(null);

  const currentUser = getStoredUser();
  const cashierName = currentUser?.name || 'Andika Palian';

  const categories = ['Semua', 'Kopi', 'Non-Kopi', 'Snack', 'Makanan'];

  const filteredProducts = products.filter((p) => {
    const matchesCategory =
      selectedCategory === 'Semua' ||
      p.category === selectedCategory ||
      p.category?.toLowerCase() === selectedCategory.toLowerCase() ||
      (selectedCategory === 'Kopi' && p.category?.toUpperCase() === 'COFFEE') ||
      (selectedCategory === 'Non-Kopi' && p.category?.toUpperCase() === 'NON_COFFEE') ||
      (selectedCategory === 'Makanan' && p.category?.toUpperCase() === 'FOOD') ||
      (selectedCategory === 'Snack' && p.category?.toUpperCase() === 'SNACK');

    const matchesSearch =
      (p.name && p.name.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (p.category && p.category.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesCategory && matchesSearch;
  });

  const addToCart = (product: Product) => {
    if (sidebarStep === 'receipt') {
      setSidebarStep('cart');
      setCompletedOrder(null);
    }
    setCart((prev) => {
      const existing = prev.find((item) => item.product.id === product.id);
      if (existing) {
        return prev.map((item) =>
          item.product.id === product.id ? { ...item, quantity: item.quantity + 1 } : item
        );
      }
      return [...prev, { product, quantity: 1 }];
    });
  };

  const updateQuantity = (productId: string, delta: number) => {
    setCart((prev) =>
      prev
        .map((item) => {
          if (item.product.id === productId) {
            const newQty = item.quantity + delta;
            return newQty > 0 ? { ...item, quantity: newQty } : null;
          }
          return item;
        })
        .filter(Boolean) as CartItem[]
    );
  };

  const removeFromCart = (productId: string) => {
    setCart((prev) => prev.filter((item) => item.product.id !== productId));
  };

  const clearCart = () => {
    setCart([]);
    setError(null);
  };

  const subtotal = cart.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
  const totalItemCount = cart.reduce((sum, item) => sum + item.quantity, 0);
  const numericCash = parseFloat(cashAmount) || 0;
  const changeAmount = numericCash >= subtotal ? numericCash - subtotal : 0;

  const activeBankObj = BANK_OPTIONS.find((b) => b.id === selectedBank) || BANK_OPTIONS[0];
  const virtualAccountNumber = `${activeBankObj.prefix}12938475`;

  const copyToClipboard = (text: string) => {
    navigator.clipboard?.writeText(text);
    setCopiedVA(true);
    setTimeout(() => setCopiedVA(false), 2000);
  };

  const handleProceedToPayment = () => {
    if (cart.length === 0) return;
    setError(null);
    setCashAmount(subtotal.toString());
    setSidebarStep('payment');
  };

  const handleConfirmCheckout = async () => {
    if (cart.length === 0) return;
    if (paymentMethod === 'cash' && numericCash < subtotal) {
      setError('Nominal uang tunai kurang dari total tagihan.');
      return;
    }
    setError(null);
    setSubmitting(true);
    try {
      const order = await onCheckout({
        items: cart,
        paymentMethod,
        orderType: `${orderType}${customerNote ? ` • ${customerNote}` : ''}`,
        cashGiven: paymentMethod === 'cash' ? numericCash : subtotal,
        change: paymentMethod === 'cash' ? changeAmount : 0,
      });
      setCompletedOrder(order);
      setSidebarStep('receipt');
    } catch (e: any) {
      setError(e?.error || 'Gagal memproses pesanan. Silakan coba kembali.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleFinish = () => {
    setCompletedOrder(null);
    setCart([]);
    setCashAmount('');
    setSidebarStep('cart');
  };

  // Keyboard shortcut listener for fast cashier workflow
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // F2: New Order / Focus Search
      if (e.key === 'F2') {
        e.preventDefault();
        if (sidebarStep === 'receipt') {
          handleFinish();
        } else {
          searchInputRef.current?.focus();
        }
      }
      // Escape: Back to Cart from Payment
      if (e.key === 'Escape' && sidebarStep === 'payment') {
        e.preventDefault();
        setSidebarStep('cart');
      }
      // Enter: Proceed to Payment from Cart, or Confirm Checkout from Payment
      if (e.key === 'Enter') {
        if (sidebarStep === 'cart' && cart.length > 0) {
          e.preventDefault();
          handleProceedToPayment();
        } else if (sidebarStep === 'payment' && !submitting) {
          if (paymentMethod !== 'cash' || numericCash >= subtotal) {
            e.preventDefault();
            handleConfirmCheckout();
          }
        } else if (sidebarStep === 'receipt') {
          e.preventDefault();
          handleFinish();
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [sidebarStep, submitting, paymentMethod, numericCash, subtotal, cart.length]);

  // Suggested Cash Quick Denominations
  const quickCashOptions = [
    { label: 'Uang Pas', value: subtotal },
    { label: 'Rp 20.000', value: 20000 },
    { label: 'Rp 50.000', value: 50000 },
    { label: 'Rp 100.000', value: 100000 },
    { label: 'Rp 200.000', value: 200000 },
  ].filter((opt) => opt.value >= subtotal || opt.label === 'Uang Pas');

  // Quick additive chips
  const addCash = (added: number) => {
    const current = parseFloat(cashAmount) || 0;
    setCashAmount((current + added).toString());
  };

  return (
    <div className="page-screen pos-container">
      {/* ── 1. Clean POS Header ── */}
      <header className="pos-screen-header">
        <div className="pos-header-left">
          <div className="pos-header-icon">
            <Store size={20} />
          </div>
          <div>
            <h2 className="pos-header-title">Kasir & Point of Sale (POS)</h2>
            <p className="pos-header-sub">
              Sistem kasir cepat • Klik menu untuk pesan • Standar QRIS Nasional & Tunai
            </p>
          </div>
        </div>
        <div className="pos-header-right">
          <span className="shift-badge-active">
            <span className="pulsing-dot-green"></span>
            Kasir Aktif: <strong>{cashierName}</strong>
          </span>
        </div>
      </header>

      {/* ── 2. POS Split Layout: Catalog Grid (Left) + Order Cart (Right) ── */}
      <div className="pos-layout">
        {/* LEFT COLUMN: Menu Catalog Section */}
        <section className="pos-catalog-section">
          {/* Search & Category Filter Bar */}
          <div className="catalog-filter-bar">
            <div className="search-bar-wrap">
              <Search size={17} className="search-icon" />
              <input
                ref={searchInputRef}
                type="text"
                placeholder="Cari menu kopi, minuman, snack, makanan... (F2)"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pos-search-input"
              />
              {searchQuery && (
                <button
                  type="button"
                  onClick={() => setSearchQuery('')}
                  className="search-clear-btn"
                  title="Hapus pencarian"
                >
                  <X size={14} />
                </button>
              )}
            </div>

            {/* Category Filter Chips */}
            <div className="category-chips-scroll">
              {categories.map((cat) => (
                <button
                  key={cat}
                  type="button"
                  onClick={() => setSelectedCategory(cat)}
                  className={`category-chip ${selectedCategory === cat ? 'active' : ''}`}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          {/* Product Cards Grid */}
          <div className="pos-catalog-grid">
            {productsLoading ? (
              <div className="catalog-loading-state">
                <Loader2 size={28} className="spin text-emerald" />
                <p>Memuat katalog produk...</p>
              </div>
            ) : filteredProducts.length === 0 ? (
              <div className="catalog-empty-state">
                <ShoppingBag size={40} className="text-slate-300" />
                <p className="empty-title">Tidak ada menu yang cocok</p>
                <p className="empty-sub">Coba ubah kata kunci pencarian atau pilih kategori lain.</p>
              </div>
            ) : (
              filteredProducts.map((product) => {
                const inCartItem = cart.find((item) => item.product.id === product.id);
                const isOutOfStock = product.stock !== undefined && product.stock <= 0;

                return (
                  <div
                    key={product.id}
                    className={`product-card ${inCartItem ? 'in-cart' : ''} ${
                      isOutOfStock ? 'out-of-stock' : ''
                    }`}
                    onClick={() => !isOutOfStock && addToCart(product)}
                    role="button"
                    tabIndex={0}
                  >
                    {/* Clean Product Image */}
                    <div className="product-image-box">
                      {product.image ? (
                        <img
                          src={product.image}
                          alt={product.name}
                          className="product-img"
                          loading="lazy"
                        />
                      ) : (
                        <div className="product-img-placeholder">
                          <UtensilsCrossed size={32} />
                        </div>
                      )}

                      {/* Active In-Cart Indicator */}
                      {inCartItem && (
                        <span className="in-cart-indicator">
                          {inCartItem.quantity}x di keranjang
                        </span>
                      )}
                    </div>

                    {/* Product Card Details */}
                    <div className="product-info-box">
                      <div className="product-category-row">
                        <span className="product-category-text">
                          {product.category || 'Menu'}
                        </span>
                        <span
                          className={`product-stock-tag ${
                            (product.stock ?? 10) < 5 ? 'low' : 'safe'
                          }`}
                        >
                          Sisa: {product.stock ?? 100} pcs
                        </span>
                      </div>

                      <h3 className="product-card-title">{product.name}</h3>

                      <div className="product-footer-row">
                        <span className="product-card-price">
                          Rp {product.price.toLocaleString('id-ID')}
                        </span>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            addToCart(product);
                          }}
                          className="btn-add-quick"
                          title="Tambah pesanan"
                        >
                          <Plus size={15} />
                          <span>Tambah</span>
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </section>

        {/* RIGHT COLUMN: Active Cart Sidebar */}
        <aside className="pos-cart-sidebar">
          <div className="cart-header">
            <div className="cart-title-group">
              <ShoppingBag size={18} className="cart-icon" />
              <h3>Keranjang Pesanan</h3>
              {cart.length > 0 && <span className="cart-count-chip">{totalItemCount} item</span>}
            </div>
            {cart.length > 0 && (
              <button
                type="button"
                onClick={clearCart}
                className="btn-clear-cart"
                title="Kosongkan seluruh keranjang"
              >
                <Trash2 size={13} />
                <span>Kosongkan</span>
              </button>
            )}
          </div>

          {cart.length === 0 ? (
            <div className="empty-cart-state">
              <div className="empty-cart-icon-box">
                <ShoppingBag size={32} />
              </div>
              <p className="empty-title">Keranjang Kosong</p>
              <p className="empty-sub">
                Klik salah satu menu di katalog sebelah kiri untuk memulai pesanan kasir.
              </p>
            </div>
          ) : (
            <>
              {/* Order Context: Dine In / Take Away & Note */}
              <div className="order-context-box">
                <div className="order-type-tabs">
                  {['Dine In', 'Take Away'].map((type) => (
                    <button
                      key={type}
                      type="button"
                      onClick={() => setOrderType(type)}
                      className={`order-type-tab ${orderType === type ? 'active' : ''}`}
                    >
                      {type}
                    </button>
                  ))}
                </div>

                <input
                  type="text"
                  placeholder="Nomor Meja / Nama Pelanggan (e.g. Meja 04)"
                  value={customerNote}
                  onChange={(e) => setCustomerNote(e.target.value)}
                  className="table-note-input"
                />
              </div>

              {/* Cart Items Scroll List */}
              <div className="cart-items-list">
                {cart.map((item) => (
                  <div key={item.product.id} className="cart-item-row">
                    <div className="cart-item-info">
                      <span className="cart-item-title">{item.product.name}</span>
                      <span className="cart-item-unit-price">
                        Rp {item.product.price.toLocaleString('id-ID')}
                      </span>
                    </div>

                    <div className="cart-item-actions">
                      <div className="qty-control-box">
                        <button
                          type="button"
                          onClick={() => updateQuantity(item.product.id, -1)}
                          className="btn-qty"
                          title="Kurangi"
                        >
                          <Minus size={11} />
                        </button>
                        <span className="qty-text">{item.quantity}</span>
                        <button
                          type="button"
                          onClick={() => updateQuantity(item.product.id, 1)}
                          className="btn-qty"
                          title="Tambah"
                        >
                          <Plus size={11} />
                        </button>
                      </div>

                      <span className="cart-item-subtotal">
                        Rp {(item.product.price * item.quantity).toLocaleString('id-ID')}
                      </span>

                      <button
                        type="button"
                        onClick={() => removeFromCart(item.product.id)}
                        className="btn-remove-item"
                        title="Hapus menu"
                      >
                        <Trash2 size={13} />
                      </button>
                    </div>
                  </div>
                ))}
              </div>

              {/* Cart Summary & Checkout Trigger */}
              <div className="cart-summary-card">
                <div className="summary-line">
                  <span>Total Item</span>
                  <span>{totalItemCount} porsi</span>
                </div>
                <div className="summary-line total-line">
                  <span>Total Tagihan</span>
                  <strong className="summary-total-amount">
                    Rp {subtotal.toLocaleString('id-ID')}
                  </strong>
                </div>

                <button
                  type="button"
                  onClick={handleProceedToPayment}
                  className="btn-checkout-primary"
                >
                  <span>Lanjut ke Pembayaran (Enter)</span>
                  <ChevronRight size={16} />
                </button>
              </div>
            </>
          )}
        </aside>
      </div>

      {/* ══════════════════════════════════════════════════════════════ */}
      {/* ── 3. DEDICATED MODERN POS CHECKOUT MODAL (SPLIT WORKSPACE) ── */}
      {/* ══════════════════════════════════════════════════════════════ */}
      {sidebarStep === 'payment' && (
        <div className="pos-modal-overlay" onClick={() => setSidebarStep('cart')}>
          <div
            className="pos-checkout-modal"
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
          >
            {/* 1. FIXED MODAL HEADER */}
            <div className="checkout-modal-header">
              <div className="modal-header-brand">
                <div className="modal-header-icon">
                  <Receipt size={18} />
                </div>
                <div>
                  <h3 className="modal-title">Kasir Pembayaran</h3>
                  <span className="modal-subtitle">
                    Kedai Kopi Tiga Angkatan • Kasir: {cashierName}
                  </span>
                </div>
              </div>
              <div className="modal-header-tags">
                <span className="order-type-badge-pill">
                  {orderType} • {customerNote || 'Meja Reguler'}
                </span>
                <button
                  type="button"
                  onClick={() => setSidebarStep('cart')}
                  className="btn-modal-close"
                  title="Tutup (Esc)"
                >
                  <X size={18} />
                </button>
              </div>
            </div>

            {/* 2. MODAL BODY (TWO BALANCED COLUMNS) */}
            <div className="checkout-modal-grid">
              {/* COL 1: ORDER SUMMARY BREAKDOWN */}
              <div className="modal-order-col">
                <div className="order-summary-header">
                  <span className="summary-label">RINCIAN PESANAN</span>
                  <span className="summary-count-tag">{totalItemCount} Menu</span>
                </div>

                {/* Itemized list with clean structure */}
                <div className="modal-order-items-scroll">
                  {cart.map((item) => (
                    <div key={item.product.id} className="modal-summary-item-line">
                      <span className="item-qty-tag">{item.quantity}×</span>
                      <div className="item-name-col">
                        <span className="item-name">{item.product.name}</span>
                        <span className="item-qty-rate">
                          @ Rp {item.product.price.toLocaleString('id-ID')}
                        </span>
                      </div>
                      <span className="item-line-total">
                        Rp {(item.product.price * item.quantity).toLocaleString('id-ID')}
                      </span>
                    </div>
                  ))}
                </div>

                {/* Pricing Math Box */}
                <div className="modal-pricing-math-card">
                  <div className="math-row">
                    <span>Subtotal Menu</span>
                    <span>Rp {subtotal.toLocaleString('id-ID')}</span>
                  </div>
                  <div className="math-row">
                    <span>Pajak Resto (PB1)</span>
                    <span className="badge-tax-free">Termasuk</span>
                  </div>
                  <div className="math-divider"></div>
                  <div className="math-total-row">
                    <div>
                      <span className="math-total-label">TOTAL TAGIHAN</span>
                      <span className="math-total-sub">Nominal bersih yang harus dibayar</span>
                    </div>
                    <strong className="math-total-amount">
                      Rp {subtotal.toLocaleString('id-ID')}
                    </strong>
                  </div>
                </div>
              </div>

              {/* COL 2: PAYMENT METHOD & INTERACTIVE WORKSPACE */}
              <div className="modal-payment-col">
                {/* Method Tabs */}
                <div className="payment-tab-row">
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('qris')}
                    className={`payment-nav-tab ${paymentMethod === 'qris' ? 'active' : ''}`}
                  >
                    <QrCode size={16} />
                    <span>QRIS Nasional</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setPaymentMethod('cash')}
                    className={`payment-nav-tab ${paymentMethod === 'cash' ? 'active' : ''}`}
                  >
                    <Banknote size={16} />
                    <span>Tunai (Cash)</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setPaymentMethod('transfer')}
                    className={`payment-nav-tab ${paymentMethod === 'transfer' ? 'active' : ''}`}
                  >
                    <Building2 size={16} />
                    <span>Transfer Bank</span>
                  </button>
                </div>

                {/* TAB CONTENT 1: AUTHENTIC NATIONAL QRIS STANDEE */}
                {paymentMethod === 'qris' && (
                  <div className="qris-tab-content">
                    <QrisStandee
                      amount={subtotal}
                      orderCode="ORD-LIVE"
                      merchantName="KEDAI KOPI TIGA ANGKATAN"
                    />
                  </div>
                )}

                {/* TAB CONTENT 2: CASH CALCULATOR */}
                {paymentMethod === 'cash' && (
                  <div className="cash-tab-content">
                    <div className="cash-input-wrapper">
                      <label className="cash-label">Nominal Uang Tunai Diterima Kasir:</label>
                      <div className="cash-input-box">
                        <span className="cash-prefix">Rp</span>
                        <input
                          type="number"
                          placeholder="Masukkan nominal uang..."
                          value={cashAmount}
                          onChange={(e) => setCashAmount(e.target.value)}
                          className="cash-large-input"
                          autoFocus
                        />
                      </div>
                    </div>

                    {/* Fast Presets */}
                    <div className="cash-shortcuts-group">
                      <span className="shortcuts-label">Pilihan Cepat:</span>
                      <div className="preset-chips-row">
                        {quickCashOptions.map((opt, i) => (
                          <button
                            key={i}
                            type="button"
                            onClick={() => setCashAmount(opt.value.toString())}
                            className={`cash-preset-pill ${
                              numericCash === opt.value ? 'selected' : ''
                            }`}
                          >
                            {opt.label}
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Quick Additive Buttons */}
                    <div className="cash-shortcuts-group">
                      <span className="shortcuts-label">Tambah Cepat:</span>
                      <div className="preset-chips-row">
                        {[5000, 10000, 20000, 50000].map((val) => (
                          <button
                            key={val}
                            type="button"
                            onClick={() => addCash(val)}
                            className="cash-add-pill"
                          >
                            +Rp {val.toLocaleString('id-ID')}
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Real-time Kembalian Banner */}
                    {numericCash > 0 && (
                      <div
                        className={`change-banner-box ${
                          numericCash >= subtotal ? 'is-sufficient' : 'is-insufficient'
                        }`}
                      >
                        <div className="change-info-col">
                          <span className="change-status-title">
                            {numericCash >= subtotal ? 'Kembalian Kasir:' : 'Uang Masih Kurang:'}
                          </span>
                          <span className="change-sub-text">
                            {numericCash >= subtotal
                              ? 'Uang tunai pelanggan mencukupi'
                              : 'Tambahkan pembayaran tunai'}
                          </span>
                        </div>
                        <strong className="change-num">
                          Rp{' '}
                          {(numericCash >= subtotal
                            ? changeAmount
                            : subtotal - numericCash
                          ).toLocaleString('id-ID')}
                        </strong>
                      </div>
                    )}
                  </div>
                )}

                {/* TAB CONTENT 3: TRANSFER / VIRTUAL ACCOUNT */}
                {paymentMethod === 'transfer' && (
                  <div className="transfer-tab-content">
                    <div className="bank-select-grid">
                      {BANK_OPTIONS.map((bank) => (
                        <button
                          key={bank.id}
                          type="button"
                          onClick={() => setSelectedBank(bank.id)}
                          className={`bank-pill ${selectedBank === bank.id ? 'active' : ''}`}
                        >
                          <span className="bank-logo-text">{bank.logo}</span>
                          <span className="bank-name-text">{bank.name}</span>
                        </button>
                      ))}
                    </div>

                    <div className="va-card-box">
                      <span className="va-header-label">{activeBankObj.name}</span>
                      <div className="va-details-row">
                        <span className="va-number-string">{virtualAccountNumber}</span>
                        <button
                          type="button"
                          onClick={() => copyToClipboard(virtualAccountNumber)}
                          className="btn-copy-va-number"
                          title="Salin nomor VA"
                        >
                          {copiedVA ? (
                            <Check size={14} className="text-emerald" />
                          ) : (
                            <Copy size={14} />
                          )}
                          <span>{copiedVA ? 'Tersalin' : 'Salin Nomor'}</span>
                        </button>
                      </div>
                      <p className="va-instruction-text">
                        Tunjukkan nomor VA di atas kepada pelanggan. Transaksi akan terkonfirmasi
                        setelah transfer berhasil diverifikasi.
                      </p>
                    </div>
                  </div>
                )}

                {error && <div className="checkout-error-banner">{error}</div>}
              </div>
            </div>

            {/* 3. FIXED MODAL FOOTER (ALWAYS VISIBLE, NEVER SCROLLED OUT OF VIEW!) */}
            <div className="checkout-modal-footer">
              <button
                type="button"
                onClick={() => setSidebarStep('cart')}
                className="btn-modal-cancel"
              >
                <ArrowLeft size={15} />
                <span>Kembali ke Keranjang (Esc)</span>
              </button>

              <div className="modal-footer-action-group">
                {paymentMethod === 'cash' && numericCash > 0 && numericCash >= subtotal && (
                  <div className="footer-quick-change">
                    Kembalian: <strong>Rp {changeAmount.toLocaleString('id-ID')}</strong>
                  </div>
                )}

                <button
                  type="button"
                  onClick={handleConfirmCheckout}
                  disabled={submitting || (paymentMethod === 'cash' && numericCash < subtotal)}
                  className="btn-modal-confirm-pay"
                >
                  {submitting ? (
                    <>
                      <Loader2 size={16} className="spin" />
                      <span>Memproses...</span>
                    </>
                  ) : (
                    <>
                      <CheckCircle2 size={17} />
                      <span>
                        {paymentMethod === 'qris'
                          ? 'Konfirmasi Pembayaran QRIS (Enter)'
                          : paymentMethod === 'cash'
                          ? `Selesaikan Bayar Rp ${subtotal.toLocaleString('id-ID')} (Enter)`
                          : 'Konfirmasi Transfer Bank (Enter)'}
                      </span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ══════════════════════════════════════════════════════════════ */}
      {/* ── 4. DEDICATED THERMAL RECEIPT MODAL (STRUK TRANSAKSI) ── */}
      {/* ══════════════════════════════════════════════════════════════ */}
      {sidebarStep === 'receipt' && completedOrder && (
        <div className="pos-modal-overlay" onClick={handleFinish}>
          <div
            className="pos-receipt-modal"
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
          >
            {/* Header Success */}
            <div className="receipt-modal-header">
              <div className="success-icon-badge">
                <CheckCircle2 size={32} />
              </div>
              <h3 className="success-title">Transaksi Berhasil!</h3>
              <span className="success-code">{completedOrder.order_code}</span>
            </div>

            {/* Thermal Paper Receipt Simulator */}
            <div className="thermal-receipt-sheet">
              <div className="receipt-paper-header">
                <h4 className="receipt-store-title">KEDAI KOPI TIGA ANGKATAN</h4>
                <p className="receipt-store-sub">Jl. Angkatan No. 3, Bandung</p>
                <p className="receipt-store-sub">AIsistenku Smart POS Retail</p>
              </div>

              <div className="receipt-meta-grid">
                <div className="meta-row">
                  <span>Waktu:</span>
                  <span>
                    {new Date().toLocaleTimeString('id-ID', {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}{' '}
                    WIB
                  </span>
                </div>
                <div className="meta-row">
                  <span>Kasir:</span>
                  <span>{cashierName}</span>
                </div>
                <div className="meta-row">
                  <span>Metode:</span>
                  <span className="receipt-method-badge">{paymentMethod.toUpperCase()}</span>
                </div>
                <div className="meta-row">
                  <span>Tipe:</span>
                  <span>{orderType} • {customerNote || 'Regular'}</span>
                </div>
              </div>

              <div className="receipt-dashed-line"></div>

              {/* Items Breakdown */}
              <div className="receipt-items-lines">
                {cart.map((item) => (
                  <div key={item.product.id} className="receipt-item-row">
                    <span className="receipt-item-name">
                      {item.product.name} × {item.quantity}
                    </span>
                    <span className="receipt-item-price">
                      Rp {(item.product.price * item.quantity).toLocaleString('id-ID')}
                    </span>
                  </div>
                ))}
              </div>

              <div className="receipt-dashed-line"></div>

              {/* Total & Change */}
              <div className="receipt-total-row">
                <span>TOTAL BAYAR:</span>
                <strong className="receipt-total-digit">
                  Rp {completedOrder.total_amount.toLocaleString('id-ID')}
                </strong>
              </div>

              {paymentMethod === 'cash' && (
                <>
                  <div className="meta-row">
                    <span>Tunai Diterima:</span>
                    <span>Rp {numericCash.toLocaleString('id-ID')}</span>
                  </div>
                  <div className="meta-row change-highlight">
                    <span>Kembalian:</span>
                    <strong>Rp {changeAmount.toLocaleString('id-ID')}</strong>
                  </div>
                </>
              )}

              <div className="receipt-paper-footer">
                <p>Terima kasih atas kunjungan Anda!</p>
                <p>Silakan berkunjung kembali ☕</p>
              </div>
            </div>

            {/* Receipt Action Buttons */}
            <div className="receipt-modal-actions">
              <button
                type="button"
                onClick={() => window.print()}
                className="btn-print-receipt-modal"
              >
                <Printer size={16} />
                <span>Cetak Struk</span>
              </button>

              <button
                type="button"
                onClick={handleFinish}
                className="btn-new-order-modal"
              >
                <span>+ Transaksi Baru (F2)</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PosScreen;
