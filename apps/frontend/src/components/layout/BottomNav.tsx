import React from 'react';
import { TabType } from '../../types';
import { Home, Store, Package, Wallet } from 'lucide-react';
import './BottomNav.css';

interface BottomNavProps {
  activeTab: TabType;
  onTabChange: (tab: TabType) => void;
  cartCount?: number;
}

export const BottomNav: React.FC<BottomNavProps> = ({ activeTab, onTabChange, cartCount = 0 }) => {
  return (
    <nav className="bottom-nav-root">
      <div className="bottom-nav-inner">
        {/* 1. Beranda */}
        <button
          type="button"
          onClick={() => onTabChange('home')}
          className={`nav-item-btn ${activeTab === 'home' ? 'active' : ''}`}
          aria-label="Beranda"
        >
          <div className="nav-icon-box">
            <Home size={24} className="nav-icon" />
          </div>
          <span className="nav-dot"></span>
        </button>

        {/* 2. Kasir POS */}
        <button
          type="button"
          onClick={() => onTabChange('pos')}
          className={`nav-item-btn ${activeTab === 'pos' ? 'active' : ''}`}
          aria-label="Kasir POS"
        >
          <div className="nav-icon-box">
            <Store size={24} className="nav-icon" />
            {cartCount > 0 && <span className="nav-cart-badge">{cartCount}</span>}
          </div>
          <span className="nav-dot"></span>
        </button>

        {/* 3. Center Hero AI Button (Elevated) */}
        <button
          type="button"
          onClick={() => onTabChange('ai')}
          className={`center-hero-ai-btn ${activeTab === 'ai' ? 'active' : ''}`}
          aria-label="AIsistenku Copilot"
          title="Buka AIsistenku"
        >
          <div className="hero-ai-inner">
            <img
              src="/logoAisitenku.png"
              alt="AIsistenku"
              className="hero-ai-img"
              onError={(e) => {
                // Fallback to iconAisistenku if logo not loaded
                (e.target as HTMLImageElement).src = '/iconAisistenku.png';
              }}
            />
          </div>
        </button>

        {/* 4. Stok */}
        <button
          type="button"
          onClick={() => onTabChange('stock')}
          className={`nav-item-btn ${activeTab === 'stock' ? 'active' : ''}`}
          aria-label="Stok & Inventaris"
        >
          <div className="nav-icon-box">
            <Package size={24} className="nav-icon" />
          </div>
          <span className="nav-dot"></span>
        </button>

        {/* 5. Keuangan */}
        <button
          type="button"
          onClick={() => onTabChange('finance')}
          className={`nav-item-btn ${activeTab === 'finance' ? 'active' : ''}`}
          aria-label="Laporan Keuangan"
        >
          <div className="nav-icon-box">
            <Wallet size={24} className="nav-icon" />
          </div>
          <span className="nav-dot"></span>
        </button>
      </div>
    </nav>
  );
};

export default BottomNav;
