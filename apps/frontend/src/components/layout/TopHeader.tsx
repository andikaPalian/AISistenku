import React from 'react';
import { Bell, Store, Smartphone, Tablet, Monitor, RefreshCw, LogOut } from 'lucide-react';
import './TopHeader.css';

export type ViewportMode = 'responsive' | 'mobile' | 'tablet' | 'desktop';

interface TopHeaderProps {
  viewportMode: ViewportMode;
  onViewportChange: (mode: ViewportMode) => void;
  unreadCount?: number;
  onLogout?: () => void;
}

export const TopHeader: React.FC<TopHeaderProps> = ({
  viewportMode,
  onViewportChange,
  unreadCount = 2,
  onLogout
}) => {
  return (
    <header className="top-header">
      <div className="header-left">
        <div className="store-chip">
          <Store size={16} className="store-icon" />
          <span className="store-name">Tiga Angkatan Mart</span>
          <span className="store-status">Online</span>
        </div>
      </div>

      {/* Viewport Simulator Control Box */}
      <div className="viewport-switcher">
        <span className="switcher-label">Pratinjau Viewport:</span>
        <div className="switcher-btn-group">
          <button
            onClick={() => onViewportChange('responsive')}
            className={`switcher-btn ${viewportMode === 'responsive' ? 'active' : ''}`}
            title="Auto Responsive (Ukuran Layar Sekarang)"
          >
            <RefreshCw size={14} />
            <span className="btn-text">Auto</span>
          </button>
          <button
            onClick={() => onViewportChange('mobile')}
            className={`switcher-btn ${viewportMode === 'mobile' ? 'active' : ''}`}
            title="Simulasi Mobile (< 640px)"
          >
            <Smartphone size={14} />
            <span className="btn-text">Mobile</span>
          </button>
          <button
            onClick={() => onViewportChange('tablet')}
            className={`switcher-btn ${viewportMode === 'tablet' ? 'active' : ''}`}
            title="Simulasi Tablet (768px)"
          >
            <Tablet size={14} />
            <span className="btn-text">Tablet</span>
          </button>
          <button
            onClick={() => onViewportChange('desktop')}
            className={`switcher-btn ${viewportMode === 'desktop' ? 'active' : ''}`}
            title="Simulasi Desktop (1200px+)"
          >
            <Monitor size={14} />
            <span className="btn-text">Desktop</span>
          </button>
        </div>
      </div>

      <div className="header-right">
        <button className="header-icon-btn" title="Notifikasi">
          <Bell size={18} />
          {unreadCount > 0 && <span className="notification-badge">{unreadCount}</span>}
        </button>
        {onLogout && (
          <button className="header-icon-btn" onClick={onLogout} title="Keluar">
            <LogOut size={18} />
          </button>
        )}
        <div className="header-avatar" title="Owner">
          O
        </div>
      </div>
    </header>
  );
};
