import React from 'react';
import { TabType } from '../../types';
import {
  Home,
  Store,
  Bot,
  Package,
  Wallet,
  ChevronLeft,
  ChevronRight,
  LogOut,
  Sparkles,
  Bell,
} from 'lucide-react';
import { getStoredUser } from '../../lib/auth';
import './SidebarNav.css';

interface SidebarNavProps {
  activeTab: TabType;
  onTabChange: (tab: TabType) => void;
  cartCount?: number;
  stockAlertCount?: number;
  isCollapsed?: boolean;
  onToggleCollapse?: () => void;
  onLogout?: () => void;
  onOpenNotification?: () => void;
}

export const SidebarNav: React.FC<SidebarNavProps> = ({
  activeTab,
  onTabChange,
  cartCount = 0,
  stockAlertCount = 0,
  isCollapsed = false,
  onToggleCollapse,
  onLogout,
  onOpenNotification,
}) => {
  const menuItems = [
    { id: 'home' as TabType, label: 'Beranda', icon: Home },
    {
      id: 'pos' as TabType,
      label: 'Kasir POS',
      icon: Store,
      badge: cartCount > 0 ? cartCount : undefined,
    },
    {
      id: 'ai' as TabType,
      label: 'AIsistenku Copilot',
      icon: Bot,
      isAi: true,
      badgeText: 'AI',
    },
    {
      id: 'stock' as TabType,
      label: 'Stok & Bahan',
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
        <div
          className="sidebar-brand"
          onClick={() => onTabChange('home')}
          style={{ cursor: 'pointer' }}
        >
          <div className="brand-icon">
            <img
              src="/iconAisistenku.png"
              alt="Logo Aisistenku"
              className="brand-logo-img"
              onError={(e) => {
                (e.target as HTMLImageElement).src = '/logoAisitenku.png';
              }}
            />
          </div>
          {!isCollapsed && (
            <div className="brand-text">
              <span className="brand-title">Tiga Angkatan</span>
              <span className="brand-sub">AISISTENKU • POS</span>
            </div>
          )}
        </div>

        <div className="sidebar-brand-actions">
          {onOpenNotification && !isCollapsed && (
            <button
              type="button"
              onClick={onOpenNotification}
              className="btn-sidebar-icon"
              title="Notifikasi & Peringatan Stok"
            >
              <Bell size={15} />
              {stockAlertCount > 0 && <span className="sidebar-notif-dot" />}
            </button>
          )}

          {onToggleCollapse && (
            <button
              type="button"
              onClick={onToggleCollapse}
              className="btn-collapse-sidebar"
              title={isCollapsed ? 'Perlebar Menu Sidebar' : 'Perkecil Menu Sidebar'}
            >
              {isCollapsed ? <ChevronRight size={15} /> : <ChevronLeft size={15} />}
            </button>
          )}
        </div>
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
                    <img
                      src="/logoAisitenku.png"
                      alt="AIsistenku"
                      className="sidebar-ai-icon-img"
                      onError={(e) => {
                        (e.target as HTMLImageElement).src = '/iconAisistenku.png';
                      }}
                    />
                  </div>
                ) : (
                  <IconComp size={20} className="sidebar-icon-svg" />
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
              {!isCollapsed && item.badgeText && (
                <span className="sidebar-badge-ai">
                  <Sparkles size={10} /> {item.badgeText}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* Footer Profile & Quick Settings */}
      {(() => {
        const currentUser = getStoredUser();
        const displayName = currentUser?.name || 'Budi Santoso';
        const initial = displayName.charAt(0).toUpperCase() || 'B';
        const displayRole =
          currentUser?.role === 'OWNER'
            ? 'Pemilik Toko'
            : currentUser?.role === 'CASHIER'
              ? 'Kasir'
              : 'Staff Toko';

        return (
          <div className="sidebar-footer">
            <div
              className="user-profile-box"
              title={isCollapsed ? `${displayName} (${displayRole})` : undefined}
            >
              <div className="user-avatar-wrap">
                <div className="user-avatar">{initial}</div>
                <span className="user-online-dot"></span>
              </div>
              {!isCollapsed && (
                <div className="user-info">
                  <span className="user-name">{displayName}</span>
                  <span className="user-role">{displayRole}</span>
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
        );
      })()}
    </aside>
  );
};

export default SidebarNav;
