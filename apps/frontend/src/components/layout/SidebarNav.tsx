import React from 'react';
import { TabType } from '../../types';
import { Home, ShoppingBag, Bot, Package, Wallet, Sparkles, Store, Settings, LogOut } from 'lucide-react';
import './SidebarNav.css';

interface SidebarNavProps {
  activeTab: TabType;
  onTabChange: (tab: TabType) => void;
  cartCount?: number;
  stockAlertCount?: number;
}

export const SidebarNav: React.FC<SidebarNavProps> = ({
  activeTab,
  onTabChange,
  cartCount = 0,
  stockAlertCount = 0
}) => {
  const menuItems = [
    { id: 'home' as TabType, label: 'Beranda', icon: Home },
    { id: 'pos' as TabType, label: 'Point of Sale (Kasir)', icon: ShoppingBag, badge: cartCount > 0 ? cartCount : undefined },
    { id: 'ai' as TabType, label: 'AI Assistant', icon: Bot, isAi: true, highlight: 'Pro' },
    { id: 'stock' as TabType, label: 'Stok & Inventaris', icon: Package, badge: stockAlertCount > 0 ? stockAlertCount : undefined, badgeDanger: true },
    { id: 'finance' as TabType, label: 'Laporan Keuangan', icon: Wallet },
  ];

  return (
    <aside className="sidebar-nav">
      {/* Brand Header */}
      <div className="sidebar-brand">
        <div className="brand-icon">
          <Store size={22} color="#ffffff" />
        </div>
        <div className="brand-text">
          <span className="brand-title">Tiga Angkatan</span>
          <span className="brand-sub">Kasir & POS Digital</span>
        </div>
      </div>

      {/* Main Navigation */}
      <div className="sidebar-menu">
        <span className="menu-group-title">MENU UTAMA</span>
        {menuItems.map((item) => {
          const IconComp = item.icon;
          const isActive = activeTab === item.id;

          return (
            <button
              key={item.id}
              onClick={() => onTabChange(item.id)}
              className={`sidebar-item ${isActive ? 'active' : ''}`}
            >
              <div className="sidebar-icon-box">
                <IconComp size={20} />
              </div>
              <span className="sidebar-label">{item.label}</span>
              {item.highlight && <span className="sidebar-highlight">{item.highlight}</span>}
              {item.badge !== undefined && (
                <span className={`sidebar-badge ${item.badgeDanger ? 'danger' : ''}`}>
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* AI Smart Banner on Desktop */}
      <div className="sidebar-ai-banner">
        <div className="ai-banner-header">
          <Sparkles size={16} color="#0D9488" />
          <span>AI Insight Ready</span>
        </div>
        <p className="ai-banner-text">Restock otomatis & prediksi penjualan siap dianalisis.</p>
        <button onClick={() => onTabChange('ai')} className="ai-banner-btn">
          Tanya AI Assistant
        </button>
      </div>

      {/* Footer Profile & Quick Settings */}
      <div className="sidebar-footer">
        <div className="user-profile-box">
          <div className="user-avatar">B</div>
          <div className="user-info">
            <span className="user-name">Budi Santoso</span>
            <span className="user-role">Pemilik Toko</span>
          </div>
        </div>
      </div>
    </aside>
  );
};
