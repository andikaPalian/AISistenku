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
  Coffee,
  Clock,
  Building2,
  ArrowLeft,
  Receipt,
  UtensilsCrossed,
} from 'lucide-react';
import { animateScreenEntrance } from '../lib/animations';
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
  products, productsLoading, onCheckout, cart, setCart,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    animateScreenEntrance(containerRef.current);
  }, []);

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
  const [completedOrder, setCompletedOrder] = useState<{ order_id: string; order_code: string; total_amount: number } | null>(null);

  const categories = ['Semua', 'Kopi', 'Non-Kopi', 'Snack', 'Makanan'];

  const filteredProducts = products.filter((p) => {
    const matchesCategory = selectedCategory === 'Semua' || p.category === selectedCategory;
    const matchesSearch = p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (p.code && p.code.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesCategory && matchesSearch;
  });

  const addToCart = (product: Product) => {
    // If currently on receipt, reset to new cart
    if (sidebarStep === 'receipt') {
      setSidebarStep('cart');
      setCompletedOrder(null);
    }
    setCart((prev) => {
      const existing = prev.find((item) => item.product.id === product.id);
      if (existing) {
        return prev.map((item) => item.product.id === product.id ? { ...item, quantity: item.quantity + 1 } : item);
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
      setError('Uang tunai kurang dari total tagihan');
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
      setError(e?.error || 'Gagal memproses pesanan');
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

  return (
    <div ref={containerRef} className="page-screen pos-container">
      <div className="pos-layout">
        {/* ── Left Product Catalog Section ── */}
        <div className="pos-catalog-section gsap-reveal">
          <div className="catalog-header">
            <div className="search-bar-wrap">
              <Search size={18} className="search-icon" />
              <input
                type="text"
                placeholder="Cari menu kopi, minuman, snack, makanan..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pos-search-input"
              />
              {searchQuery && (
                <button onClick={() => setSearchQuery('')} className="btn-clear-search">
                  <X size={14} />
                </button>
              )}
            </div>

            <div className="category-pills">
              {categories.map((cat) => (
                <button
                  key={cat}
                  onClick={() => setSelectedCategory(cat)}
                  className={`category-pill ${selectedCategory === cat ? 'active' : ''}`}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          <div className="product-grid">
            {productsLoading ? (
              <div className="empty-state-small">Memuat menu kafe...</div>
            ) : filteredProducts.length === 0 ? (
              <div className="empty-state-small">Tidak ada menu ditemukan.</div>
            ) : (
              filteredProducts.map((product) => {
                const inCartItem = cart.find((c) => c.product.id === product.id);
                const isLowStock = product.stock <= product.minStock;

                return (
                  <div key={product.id} className="card-base product-card gsap-reveal">
                    {/* Product Image Banner */}
                    <div className="product-image-wrap">
                      {product.image ? (
                        <img
                          src={product.image}
                          alt={product.name}
                          className="product-img"
                          loading="lazy"
                        />
                      ) : (
                        <div className="product-img-fallback">
                          <Coffee size={32} />
                        </div>
                      )}
                      <span className="product-cat-tag">{product.category}</span>
                      <span className="product-code-tag">{product.code}</span>
                    </div>

                    <div className="product-card-body">
                      <h4 className="product-name">{product.name}</h4>
                      <div className="product-stock-badge">
                        <span className={`stock-indicator ${isLowStock ? 'low' : ''}`}>
                          Sisa: <strong>{product.stock} {product.unit}</strong>
                        </span>
                      </div>
                    </div>

                    <div className="product-card-footer">
                      <span className="product-price">Rp {product.price.toLocaleString('id-ID')}</span>
                      {inCartItem ? (
                        <div className="qty-control-inline">
                          <button
                            onClick={() => updateQuantity(product.id, -1)}
                            className="btn-qty-sm"
                            title="Kurangi"
                          >
                            <Minus size={12} />
                          </button>
                          <span className="qty-val">{inCartItem.quantity}</span>
                          <button
                            onClick={() => updateQuantity(product.id, 1)}
                            className="btn-qty-sm"
                            title="Tambah"
                          >
                            <Plus size={12} />
                          </button>
                        </div>
                      ) : (
                        <button onClick={() => addToCart(product)} className="btn-add-cart">
                          <Plus size={14} /> Tambah
                        </button>
                      )}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* ── Right Cashier Sidebar (In-Place Workflow: Cart -> Payment -> Receipt) ── */}
        <div className="pos-cart-sidebar gsap-reveal">
          {/* ══════════ STEP 1: CART VIEW ══════════ */}
          {sidebarStep === 'cart' && (
            <>
              <div className="cart-header">
                <div className="cart-title-group">
                  <ShoppingBag size={20} className="cart-icon" />
                  <h3>Keranjang Pesanan</h3>
                </div>
                {cart.length > 0 && <span className="badge badge-teal">{totalItemCount} Item</span>}
              </div>

              {cart.length === 0 ? (
                <div className="empty-cart-state">
                  <ShoppingBag size={44} className="empty-icon" />
                  <p className="empty-title">Keranjang Kosong</p>
                  <p className="empty-sub">Pilih menu dari katalog di sebelah kiri untuk memulai kasir.</p>
                </div>
              ) : (
                <>
                  <div className="cart-items-list">
                    {cart.map((item) => (
                      <div key={item.product.id} className="cart-item">
                        <div className="cart-item-details">
                          <span className="cart-item-name">{item.product.name}</span>
                          <span className="cart-item-price">
                            Rp {item.product.price.toLocaleString('id-ID')} × {item.quantity}
                          </span>
                        </div>
                        <div className="cart-item-actions">
                          <div className="qty-control">
                            <button onClick={() => updateQuantity(item.product.id, -1)} className="btn-qty">
                              <Minus size={12} />
                            </button>
                            <span className="qty-number">{item.quantity}</span>
                            <button onClick={() => updateQuantity(item.product.id, 1)} className="btn-qty">
                              <Plus size={12} />
                            </button>
                          </div>
                          <span className="cart-item-subtotal">
                            Rp {(item.product.price * item.quantity).toLocaleString('id-ID')}
                          </span>
                          <button onClick={() => removeFromCart(item.product.id)} className="btn-remove" title="Hapus">
                            <Trash2 size={14} />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="order-settings-block">
                    <div className="form-group-compact">
                      <label>Tipe Pesanan & Meja:</label>
                      <div className="order-type-chips">
                        {['Dine In', 'Take Away'].map((type) => (
                          <button
                            key={type}
                            type="button"
                            onClick={() => setOrderType(type)}
                            className={`type-chip-btn ${orderType === type ? 'active' : ''}`}
                          >
                            {type}
                          </button>
                        ))}
                      </div>
                      <input
                        type="text"
                        placeholder="Catatan / No. Meja (e.g. Meja 04)"
                        value={customerNote}
                        onChange={(e) => setCustomerNote(e.target.value)}
                        className="input-compact"
                      />
                    </div>
                  </div>

                  <div className="cart-summary-footer">
                    <div className="summary-row">
                      <span>Subtotal</span>
                      <span>Rp {subtotal.toLocaleString('id-ID')}</span>
                    </div>
                    <div className="summary-row total">
                      <span>Total Tagihan</span>
                      <span className="total-amount">Rp {subtotal.toLocaleString('id-ID')}</span>
                    </div>
                    <button
                      type="button"
                      onClick={handleProceedToPayment}
                      className="btn-primary btn-checkout"
                    >
                      Lanjut ke Pembayaran
                    </button>
                  </div>
                </>
              )}
            </>
          )}

          {/* ══════════ STEP 2: IN-SIDEBAR PAYMENT VIEW ══════════ */}
          {sidebarStep === 'payment' && (
            <div className="sidebar-payment-flow animate-fade-in">
              <div className="payment-sidebar-header">
                <button
                  type="button"
                  onClick={() => setSidebarStep('cart')}
                  className="btn-back-sidebar"
                  title="Kembali ke Keranjang"
                >
                  <ArrowLeft size={16} />
                  <span>Ubah Pesanan</span>
                </button>
                <span className="payment-step-badge">Langkah 2/2</span>
              </div>

              {/* Total Tagihan Pill */}
              <div className="payment-bill-card">
                <span className="bill-label">TOTAL TAGIHAN</span>
                <h3 className="bill-amount">Rp {subtotal.toLocaleString('id-ID')}</h3>
                <span className="bill-sub">
                  {orderType} • {customerNote || 'Tanpa Catatan'}
                </span>
              </div>

              {/* Payment Method Selector */}
              <div className="payment-method-block">
                <span className="section-label-sm">Metode Pembayaran:</span>
                <div className="method-grid-compact">
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('qris')}
                    className={`method-chip ${paymentMethod === 'qris' ? 'active' : ''}`}
                  >
                    <QrCode size={16} />
                    <span>QRIS</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('cash')}
                    className={`method-chip ${paymentMethod === 'cash' ? 'active' : ''}`}
                  >
                    <Banknote size={16} />
                    <span>Tunai</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('transfer')}
                    className={`method-chip ${paymentMethod === 'transfer' ? 'active' : ''}`}
                  >
                    <Building2 size={16} />
                    <span>Transfer</span>
                  </button>
                </div>
              </div>

              {/* ── Sub-view 1: QRIS ── */}
              {paymentMethod === 'qris' && (
                <div className="sidebar-qris-container">
                  <div className="qris-card-clean">
                    <div className="qris-brand-banner">
                      <span className="brand-qris">QRIS</span>
                      <span className="brand-sub">PEMBAYARAN NASIONAL</span>
                    </div>

                    <div className="qris-svg-wrapper">
                      <svg viewBox="0 0 140 140" className="qris-code-svg">
                        <rect width="140" height="140" fill="#FFFFFF" rx="6" />
                        <rect x="10" y="10" width="34" height="34" fill="#0F172A" rx="4" />
                        <rect x="16" y="16" width="22" height="22" fill="#FFFFFF" rx="2" />
                        <rect x="21" y="21" width="12" height="12" fill="#0F172A" rx="2" />

                        <rect x="96" y="10" width="34" height="34" fill="#0F172A" rx="4" />
                        <rect x="102" y="16" width="22" height="22" fill="#FFFFFF" rx="2" />
                        <rect x="107" y="21" width="12" height="12" fill="#0F172A" rx="2" />

                        <rect x="10" y="96" width="34" height="34" fill="#0F172A" rx="4" />
                        <rect x="16" y="102" width="22" height="22" fill="#FFFFFF" rx="2" />
                        <rect x="21" y="107" width="12" height="12" fill="#0F172A" rx="2" />

                        <rect x="52" y="16" width="8" height="8" fill="#0F172A" />
                        <rect x="68" y="16" width="8" height="8" fill="#0F172A" />
                        <rect x="60" y="28" width="8" height="8" fill="#0F172A" />
                        <rect x="76" y="28" width="8" height="8" fill="#0F172A" />

                        <rect x="16" y="52" width="8" height="8" fill="#0F172A" />
                        <rect x="32" y="52" width="8" height="8" fill="#0F172A" />
                        <rect x="52" y="52" width="12" height="12" fill="#0D9488" rx="2" />
                        <rect x="76" y="52" width="8" height="8" fill="#0F172A" />
                        <rect x="96" y="52" width="8" height="8" fill="#0F172A" />

                        <rect x="24" y="68" width="8" height="8" fill="#0F172A" />
                        <rect x="40" y="68" width="8" height="8" fill="#0F172A" />
                        <rect x="64" y="68" width="14" height="14" fill="#0F766E" rx="3" />
                        <rect x="88" y="68" width="8" height="8" fill="#0F172A" />
                        <rect x="108" y="68" width="8" height="8" fill="#0F172A" />

                        <rect x="16" y="80" width="8" height="8" fill="#0F172A" />
                        <rect x="32" y="80" width="8" height="8" fill="#0F172A" />
                        <rect x="52" y="80" width="8" height="8" fill="#0D9488" />
                        <rect x="76" y="80" width="10" height="10" fill="#0F172A" />
                        <rect x="100" y="80" width="8" height="8" fill="#0F172A" />

                        <rect x="52" y="96" width="8" height="8" fill="#0F172A" />
                        <rect x="72" y="96" width="8" height="8" fill="#0F172A" />
                        <rect x="92" y="96" width="8" height="8" fill="#0F172A" />
                        <rect x="112" y="96" width="8" height="8" fill="#0F172A" />

                        <rect x="60" y="112" width="8" height="8" fill="#0F172A" />
                        <rect x="80" y="112" width="8" height="8" fill="#0F172A" />
                        <rect x="100" y="112" width="8" height="8" fill="#0F172A" />

                        <rect x="58" y="58" width="24" height="24" fill="#FFFFFF" rx="4" />
                        <rect x="62" y="62" width="16" height="16" fill="#0D9488" rx="3" />
                        <text x="70" y="74" fill="#FFFFFF" fontSize="9" fontWeight="bold" textAnchor="middle">TA</text>
                      </svg>
                    </div>

                    <div className="qris-helper-text">
                      <span>BCA • GoPay • OVO • Dana • ShopeePay</span>
                    </div>
                  </div>
                </div>
              )}

              {/* ── Sub-view 2: Tunai (Cash) ── */}
              {paymentMethod === 'cash' && (
                <div className="sidebar-cash-container">
                  <div className="cash-field-group">
                    <label>Uang Diterima:</label>
                    <input
                      type="number"
                      placeholder="Nominal uang tunai..."
                      value={cashAmount}
                      onChange={(e) => setCashAmount(e.target.value)}
                      className="cash-input-main"
                    />
                  </div>

                  <div className="cash-chips-row">
                    <button
                      type="button"
                      onClick={() => setCashAmount(subtotal.toString())}
                      className="chip-btn-sm uang-pas"
                    >
                      Uang Pas
                    </button>
                    {[50000, 100000].map((val) => (
                      <button
                        key={val}
                        type="button"
                        onClick={() => setCashAmount(val.toString())}
                        className="chip-btn-sm"
                      >
                        Rp {(val / 1000).toFixed(0)}k
                      </button>
                    ))}
                  </div>

                  {numericCash > 0 && (
                    <div className={`change-banner-pill ${numericCash >= subtotal ? 'ok' : 'short'}`}>
                      <span>Kembalian:</span>
                      <strong>
                        {numericCash >= subtotal
                          ? `Rp ${changeAmount.toLocaleString('id-ID')}`
                          : `Kurang Rp ${(subtotal - numericCash).toLocaleString('id-ID')}`}
                      </strong>
                    </div>
                  )}
                </div>
              )}

              {/* ── Sub-view 3: Bank Transfer ── */}
              {paymentMethod === 'transfer' && (
                <div className="sidebar-transfer-container">
                  <label className="section-label-sm">Pilih Bank Virtual Account:</label>
                  <div className="bank-select-pills">
                    {BANK_OPTIONS.map((bank) => (
                      <button
                        key={bank.id}
                        type="button"
                        onClick={() => setSelectedBank(bank.id)}
                        className={`bank-pill-btn ${selectedBank === bank.id ? 'active' : ''}`}
                      >
                        {bank.logo}
                      </button>
                    ))}
                  </div>

                  <div className="va-box-clean">
                    <span className="va-label">{activeBankObj.name}</span>
                    <div className="va-copy-row">
                      <span className="va-digits">{virtualAccountNumber}</span>
                      <button
                        type="button"
                        onClick={() => copyToClipboard(virtualAccountNumber)}
                        className="btn-copy-chip"
                        title="Salin Nomor VA"
                      >
                        {copiedVA ? <Check size={14} className="text-teal" /> : <Copy size={14} />}
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {error && <div className="pos-error-pill">{error}</div>}

              {/* Action Buttons */}
              <div className="payment-action-footer">
                <button
                  type="button"
                  onClick={handleConfirmCheckout}
                  disabled={submitting || (paymentMethod === 'cash' && numericCash < subtotal)}
                  className="btn-primary btn-checkout"
                >
                  {submitting ? (
                    <>
                      <Loader2 size={16} className="spin" />
                      <span>Memproses...</span>
                    </>
                  ) : (
                    <>
                      <CheckCircle2 size={16} />
                      <span>Konfirmasi Pembayaran</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          )}

          {/* ══════════ STEP 3: IN-SIDEBAR RECEIPT VIEW ══════════ */}
          {sidebarStep === 'receipt' && completedOrder && (
            <div className="sidebar-receipt-flow animate-fade-in">
              <div className="receipt-success-banner">
                <div className="success-icon-box">
                  <CheckCircle2 size={32} />
                </div>
                <h4>Pembayaran Berhasil!</h4>
                <span className="receipt-code">{completedOrder.order_code}</span>
              </div>

              <div className="receipt-items-card">
                <div className="receipt-meta-line">
                  <span>Waktu:</span>
                  <span>{new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })} WIB</span>
                </div>
                <div className="receipt-meta-line">
                  <span>Metode:</span>
                  <span className="receipt-method-tag">{paymentMethod.toUpperCase()}</span>
                </div>

                <div className="receipt-dashed-line"></div>

                <div className="receipt-breakdown">
                  {cart.map((item) => (
                    <div key={item.product.id} className="breakdown-row">
                      <span>{item.product.name} × {item.quantity}</span>
                      <span>Rp {(item.product.price * item.quantity).toLocaleString('id-ID')}</span>
                    </div>
                  ))}
                </div>

                <div className="receipt-dashed-line"></div>

                <div className="receipt-total-line">
                  <span>Total Bayar</span>
                  <strong className="receipt-total-val">
                    Rp {completedOrder.total_amount.toLocaleString('id-ID')}
                  </strong>
                </div>

                {paymentMethod === 'cash' && (
                  <div className="receipt-meta-line" style={{ marginTop: '6px' }}>
                    <span>Kembalian:</span>
                    <strong>Rp {changeAmount.toLocaleString('id-ID')}</strong>
                  </div>
                )}
              </div>

              <div className="receipt-action-buttons">
                <button
                  type="button"
                  onClick={() => window.print()}
                  className="btn-secondary btn-print-receipt"
                >
                  <Printer size={16} />
                  <span>Cetak Struk</span>
                </button>
                <button
                  type="button"
                  onClick={handleFinish}
                  className="btn-primary btn-new-order"
                >
                  Transaksi Baru
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default PosScreen;
