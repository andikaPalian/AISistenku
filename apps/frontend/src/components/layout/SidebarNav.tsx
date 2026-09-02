import React from 'react';
import { TabType } from '../../types';
import {
  Home,
  ShoppingBag,
  Bot,
  Package,
  Wallet,
  Sparkles,
  Store,
  ChevronLeft,
  ChevronRight,
  PanelLeftClose,
  PanelLeftOpen,
  LogOut,
} from 'lucide-react';
import './SidebarNav.css';

interface SidebarNavProps {
  activeTab: TabType;
  onTabChange: (tab: TabType) => void;
  cartCount?: number;
  stockAlertCount?: number;
  isCollapsed?: boolean;
  onToggleCollapse?: () => void;
  onLogout?: () => void;
}

export const SidebarNav: React.FC<SidebarNavProps> = ({
  activeTab,
  onTabChange,
  cartCount = 0,
  stockAlertCount = 0,
  isCollapsed = false,
  onToggleCollapse,
  onLogout,
}) => {
  const menuItems = [
    { id: 'home' as TabType, label: 'Beranda', icon: Home },
    {
      id: 'pos' as TabType,
      label: 'Point of Sale (Kasir)',
      icon: ShoppingBag,
      badge: cartCount > 0 ? cartCount : undefined,
    },
    { id: 'ai' as TabType, label: 'AIsistenku (AI Copilot)', icon: Bot, isAi: true },
    {
      id: 'stock' as TabType,
      label: 'Stok & Inventaris',
      icon: Package,
      badge: stockAlertCount > 0 ? stockAlertCount : undefined,
      badgeDanger: true,
    },
    { id: 'finance' as TabType, label: 'Laporan Keuangan', icon: Wallet },
  ];

  return (
    <aside className={`sidebar-nav ${isCollapsed ? 'collapsed' : ''}`}>
      {/* Brand Header & Collapse Trigger */}
      <div className="sidebar-brand-wrapper">
        <div className="sidebar-brand">
          <div className="brand-icon">
            <Store size={22} color="#ffffff" />
          </div>
          {!isCollapsed && (
            <div className="brand-text">
              <span className="brand-title">Tiga Angkatan</span>
              <span className="brand-sub">AISISTENKU</span>
            </div>
          )}
        </div>

        {onToggleCollapse && (
          <button
            type="button"
            onClick={onToggleCollapse}
            className="btn-collapse-sidebar"
            title={isCollapsed ? 'Perlebar Menu Sidebar' : 'Perkecil Menu Sidebar (Hanya Ikon)'}
          >
            {isCollapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
          </button>
        )}
      </div>

      {/* Main Navigation */}
      <div className="sidebar-menu">
        {!isCollapsed && <span className="menu-group-title">MENU UTAMA</span>}
        {menuItems.map((item) => {
          const IconComp = item.icon;
          const isActive = activeTab === item.id;

          return (
            <button
              key={item.id}
              type="button"
              onClick={() => onTabChange(item.id)}
              className={`sidebar-item ${isActive ? 'active' : ''} ${item.isAi ? 'ai-menu-item' : ''}`}
              title={isCollapsed ? item.label : undefined}
            >
              <div className="sidebar-icon-box">
                {item.isAi ? (
                  <div className="sidebar-ai-icon-container">
                    <img src="/iconAisistenku.png" alt="AIsistenku" className="sidebar-ai-icon-img" />
                  </div>
                ) : (
                  <IconComp size={20} />
                )}
                {isCollapsed && item.badge !== undefined && (
                  <span className={`sidebar-mini-dot ${item.badgeDanger ? 'danger' : ''}`}></span>
                )}
              </div>
              {!isCollapsed && <span className="sidebar-label">{item.label}</span>}
              {!isCollapsed && item.badge !== undefined && (
                <span className={`sidebar-badge ${item.badgeDanger ? 'danger' : ''}`}>
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* AI Smart Banner on Desktop (Full Mode only) */}
      {!isCollapsed ? (
        <div className="sidebar-ai-banner">
          <div className="ai-banner-header">
            <div className="ai-banner-icon-container">
              <img src="/iconAisistenku.png" alt="AIsistenku" className="ai-banner-icon-img" />
            </div>
            <span>AI Insight Ready</span>
          </div>
          <p className="ai-banner-text">Restock otomatis & prediksi penjualan siap dianalisis.</p>
          <button onClick={() => onTabChange('ai')} className="ai-banner-btn">
            Tanya AI Assistant
          </button>
        </div>
      ) : (
        <div className="sidebar-ai-mini-badge" title="AIsistenku Copilot">
          <button
            type="button"
            onClick={() => onTabChange('ai')}
            className="ai-mini-btn"
            title="Buka AIsistenku"
          >
            <img src="/iconAisistenku.png" alt="AIsistenku" className="ai-mini-icon-img" />
          </button>
        </div>
      )}

      {/* Footer Profile & Quick Settings */}
      <div className="sidebar-footer">
        <div className="user-profile-box" title={isCollapsed ? 'Budi Santoso (Pemilik Toko)' : undefined}>
          <div className="user-avatar">B</div>
          {!isCollapsed && (
            <div className="user-info">
              <span className="user-name">Budi Santoso</span>
              <span className="user-role">Pemilik Toko</span>
            </div>
          )}
          {onLogout && (
            <button 
              type="button" 
              onClick={onLogout} 
              className="sidebar-logout-btn" 
              title="Keluar"
            >
              <LogOut size={16} />
            </button>
          )}
        </div>
      </div>
    </aside>
  );
};

export default SidebarNav;
