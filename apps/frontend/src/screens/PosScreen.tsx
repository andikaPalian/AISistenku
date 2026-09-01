import React, { useState } from 'react';
import { Product, CartItem, Transaction } from '../types';
import { Search, ShoppingBag, Plus, Minus, Trash2, CheckCircle2, QrCode, Banknote, CreditCard, Printer, ArrowLeft, X } from 'lucide-react';
import './PosScreen.css';

interface PosScreenProps {
  products: Product[];
  onAddTransaction: (tx: Transaction) => void;
  cart: CartItem[];
  setCart: React.Dispatch<React.SetStateAction<CartItem[]>>;
}

export const PosScreen: React.FC<PosScreenProps> = ({
  products,
  onAddTransaction,
  cart,
  setCart
}) => {
  const [selectedCategory, setSelectedCategory] = useState<string>('Semua');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isCheckoutModalOpen, setIsCheckoutModalOpen] = useState<boolean>(false);
  const [isMobileCartOpen, setIsMobileCartOpen] = useState<boolean>(false);
  const [paymentMethod, setPaymentMethod] = useState<'qris' | 'cash' | 'transfer'>('qris');
  const [cashAmount, setCashAmount] = useState<string>('');
  const [completedTransaction, setCompletedTransaction] = useState<Transaction | null>(null);

  const categories = ['Semua', 'Sembako', 'Minuman', 'Makanan', 'Kebutuhan Rumah'];

  // Filter products
  const filteredProducts = products.filter((p) => {
    const matchesCategory = selectedCategory === 'Semua' || p.category === selectedCategory;
    const matchesSearch = p.name.toLowerCase().includes(searchQuery.toLowerCase()) || (p.code && p.code.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesCategory && matchesSearch;
  });

  // Cart helper functions
  const addToCart = (product: Product) => {
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

  const subtotal = cart.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
  const totalItemCount = cart.reduce((sum, item) => sum + item.quantity, 0);
  const numericCash = parseFloat(cashAmount) || 0;
  const changeAmount = numericCash >= subtotal ? numericCash - subtotal : 0;

  const handleProcessCheckout = () => {
    if (cart.length === 0) return;

    const newTx: Transaction = {
      id: `tx-${Date.now()}`,
      invoiceNo: `INV/${new Date().getFullYear()}${String(new Date().getMonth() + 1).padStart(2, '0')}${String(new Date().getDate()).padStart(2, '0')}/${Math.floor(100 + Math.random() * 900)}`,
      date: new Date().toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }),
      time: new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
      type: 'sale',
      category: 'Penjualan Kasir',
      amount: subtotal,
      paymentMethod,
      status: 'success',
      itemCount: totalItemCount,
      notes: `Pembayaran via ${paymentMethod.toUpperCase()}`
    };

    onAddTransaction(newTx);
    setCompletedTransaction(newTx);
    setIsCheckoutModalOpen(false);
  };

  const handleFinishTransaction = () => {
    setCompletedTransaction(null);
    setCart([]);
    setCashAmount('');
    setIsMobileCartOpen(false);
  };

  return (
    <div className="page-screen pos-container animate-fade-in">
      {/* Main Split Layout: Left Catalog, Right Cart (Desktop/Tablet) */}
      <div className="pos-layout">
        {/* Left Section: Catalog & Search */}
        <div className="pos-catalog-section">
          {/* Search & Categories */}
          <div className="catalog-header">
            <div className="search-bar-wrap">
              <Search size={18} className="search-icon" />
              <input
                type="text"
                placeholder="Cari produk atau scan barcode SKU..."
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

          {/* Product Grid */}
          <div className="product-grid">
            {filteredProducts.map((product) => {
              const inCartItem = cart.find((c) => c.product.id === product.id);
              const isLowStock = product.stock <= product.minStock;

              return (
                <div key={product.id} className="card-base product-card">
                  <div className="product-card-body">
                    <span className="product-code">{product.code}</span>
                    <h4 className="product-name">{product.name}</h4>
                    <div className="product-stock-badge">
                      <span className={`stock-indicator ${isLowStock ? 'low' : ''}`}>
                        Stok: {product.stock} {product.unit}
                      </span>
                    </div>
                  </div>

                  <div className="product-card-footer">
                    <span className="product-price">
                      Rp {product.price.toLocaleString('id-ID')}
                    </span>

                    {inCartItem ? (
                      <div className="qty-control-inline">
                        <button onClick={() => updateQuantity(product.id, -1)} className="btn-qty-sm">
                          <Minus size={12} />
                        </button>
                        <span className="qty-val">{inCartItem.quantity}</span>
                        <button onClick={() => updateQuantity(product.id, 1)} className="btn-qty-sm">
                          <Plus size={12} />
                        </button>
                      </div>
                    ) : (
                      <button onClick={() => addToCart(product)} className="btn-add-cart">
                        <Plus size={14} />
                        Tambah
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Section: Order Cart (Desktop & Tablet persistent panel) */}
        <div className="pos-cart-sidebar">
          <div className="cart-header">
            <div className="cart-title-group">
              <ShoppingBag size={20} className="cart-icon" />
              <h3>Keranjang Belanja</h3>
            </div>
            {cart.length > 0 && (
              <span className="badge badge-teal">{totalItemCount} Item</span>
            )}
          </div>

          {cart.length === 0 ? (
            <div className="empty-cart-state">
              <ShoppingBag size={48} className="empty-icon" />
              <p className="empty-title">Keranjang masih kosong</p>
              <p className="empty-sub">Pilih produk dari katalog untuk memulai pesanan.</p>
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
                      <button onClick={() => removeFromCart(item.product.id)} className="btn-remove">
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </div>
                ))}
              </div>

              <div className="cart-summary-footer">
                <div className="summary-row">
                  <span>Subtotal</span>
                  <span>Rp {subtotal.toLocaleString('id-ID')}</span>
                </div>
                <div className="summary-row">
                  <span>Pajak (0%)</span>
                  <span>Rp 0</span>
                </div>
                <div className="summary-row total">
                  <span>Total Pembayaran</span>
                  <span className="total-amount">Rp {subtotal.toLocaleString('id-ID')}</span>
                </div>

                <button onClick={() => setIsCheckoutModalOpen(true)} className="btn-primary btn-checkout">
                  Lanjut ke Pembayaran
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Floating Mobile Cart Bar (Visible on mobile screens) */}
      {cart.length > 0 && (
        <div className="mobile-cart-bar">
          <div className="mobile-cart-info">
            <span className="mobile-cart-count">{totalItemCount} Item</span>
            <span className="mobile-cart-total">Rp {subtotal.toLocaleString('id-ID')}</span>
          </div>
          <button onClick={() => setIsCheckoutModalOpen(true)} className="btn-primary">
            Bayar Sekarang
          </button>
        </div>
      )}

      {/* Checkout Modal */}
      {isCheckoutModalOpen && (
        <div className="modal-overlay">
          <div className="modal-card animate-fade-in">
            <div className="modal-header">
              <h3>Proses Pembayaran</h3>
              <button onClick={() => setIsCheckoutModalOpen(false)} className="btn-close">
                <X size={18} />
              </button>
            </div>

            <div className="modal-body">
              <div className="checkout-total-banner">
                <span className="banner-label">Total Tagihan</span>
                <h2 className="banner-amount">Rp {subtotal.toLocaleString('id-ID')}</h2>
              </div>

              {/* Payment Methods */}
              <div className="payment-method-selector">
                <span className="section-label">Pilih Metode Pembayaran:</span>
                <div className="method-grid">
                  <button
                    onClick={() => setPaymentMethod('qris')}
                    className={`method-card ${paymentMethod === 'qris' ? 'active' : ''}`}
                  >
                    <QrCode size={24} />
                    <span>QRIS Instant</span>
                  </button>

                  <button
                    onClick={() => setPaymentMethod('cash')}
                    className={`method-card ${paymentMethod === 'cash' ? 'active' : ''}`}
                  >
                    <Banknote size={24} />
                    <span>Tunai (Cash)</span>
                  </button>

                  <button
                    onClick={() => setPaymentMethod('transfer')}
                    className={`method-card ${paymentMethod === 'transfer' ? 'active' : ''}`}
                  >
                    <CreditCard size={24} />
                    <span>Bank Transfer</span>
                  </button>
                </div>
              </div>

              {/* Cash Input if Payment Method = Cash */}
              {paymentMethod === 'cash' && (
                <div className="cash-input-group">
                  <label>Uang Diterima (Rp):</label>
                  <input
                    type="number"
                    placeholder="Masukkan nominal uang..."
                    value={cashAmount}
                    onChange={(e) => setCashAmount(e.target.value)}
                    className="cash-input"
                  />
                  <div className="cash-quick-chips">
                    {[subtotal, 50000, 100000, 200000].map((val) => (
                      <button
                        key={val}
                        onClick={() => setCashAmount(val.toString())}
                        className="chip-btn"
                      >
                        Rp {val.toLocaleString('id-ID')}
                      </button>
                    ))}
                  </div>
                  {numericCash > 0 && (
                    <div className="change-calc-box">
                      <span>Kembalian:</span>
                      <span className={`change-amount ${numericCash < subtotal ? 'insufficient' : ''}`}>
                        {numericCash >= subtotal
                          ? `Rp ${changeAmount.toLocaleString('id-ID')}`
                          : 'Uang tidak cukup'}
                      </span>
                    </div>
                  )}
                </div>
              )}

              {/* QRIS Graphic Preview */}
              {paymentMethod === 'qris' && (
                <div className="qris-preview-box">
                  <div className="qris-qr-code">
                    <QrCode size={120} color="#0D9488" />
                  </div>
                  <p className="qris-sub">Scan QRIS menggunakan GoPay, OVO, ShopeePay, DANA, atau M-Banking.</p>
                </div>
              )}
            </div>

            <div className="modal-footer">
              <button onClick={() => setIsCheckoutModalOpen(false)} className="btn-secondary">
                Batal
              </button>
              <button
                onClick={handleProcessCheckout}
                disabled={paymentMethod === 'cash' && numericCash < subtotal}
                className="btn-primary"
              >
                Konfirmasi & Bayar
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Payment Success Modal */}
      {completedTransaction && (
        <div className="modal-overlay">
          <div className="modal-card receipt-modal animate-fade-in">
            <div className="receipt-success-badge">
              <CheckCircle2 size={48} color="#10B981" />
              <h3>Pembayaran Berhasil!</h3>
              <span className="receipt-invoice">{completedTransaction.invoiceNo}</span>
            </div>

            <div className="receipt-content">
              <div className="receipt-row">
                <span>Tanggal & Waktu</span>
                <span>{completedTransaction.date} {completedTransaction.time}</span>
              </div>
              <div className="receipt-row">
                <span>Metode Pembayaran</span>
                <span className="badge badge-teal">{completedTransaction.paymentMethod.toUpperCase()}</span>
              </div>

              <div className="receipt-divider"></div>

              <div className="receipt-items-summary">
                {cart.map((item) => (
                  <div key={item.product.id} className="receipt-item">
                    <span>{item.product.name} × {item.quantity}</span>
                    <span>Rp {(item.product.price * item.quantity).toLocaleString('id-ID')}</span>
                  </div>
                ))}
              </div>

              <div className="receipt-divider"></div>

              <div className="receipt-row total-row">
                <span>Total Bayar</span>
                <span className="receipt-total">Rp {completedTransaction.amount.toLocaleString('id-ID')}</span>
              </div>
            </div>

            <div className="modal-footer">
              <button onClick={() => alert('Mencetak struk ke printer thermal...')} className="btn-secondary">
                <Printer size={16} />
                Cetak Struk
              </button>
              <button onClick={handleFinishTransaction} className="btn-primary">
                Selesai & Transaksi Baru
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
