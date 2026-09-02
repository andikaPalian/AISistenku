import React from 'react';
import { TabType } from '../../types';
import { Home, ShoppingBag, Bot, Package, Wallet } from 'lucide-react';
import './BottomNav.css';

interface BottomNavProps {
  activeTab: TabType;
  onTabChange: (tab: TabType) => void;
  cartCount?: number;
}

export const BottomNav: React.FC<BottomNavProps> = ({ activeTab, onTabChange, cartCount = 0 }) => {
  const tabs = [
    { id: 'home' as TabType, label: 'Beranda', icon: Home },
    { id: 'pos' as TabType, label: 'Kasir', icon: ShoppingBag, badge: cartCount > 0 ? cartCount : undefined },
    { id: 'ai' as TabType, label: 'AI Assistant', icon: Bot, isAi: true },
    { id: 'stock' as TabType, label: 'Stok', icon: Package },
    { id: 'finance' as TabType, label: 'Keuangan', icon: Wallet },
  ];

  return (
    <nav className="bottom-nav">
      <div className="bottom-nav-inner">
        {tabs.map((tab) => {
          const IconComponent = tab.icon;
          const isActive = activeTab === tab.id;

          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className={`bottom-nav-item ${isActive ? 'active' : ''} ${tab.isAi ? 'ai-item' : ''}`}
            >
              <div className="icon-wrapper">
                {tab.isAi ? (
                  <div className="bottom-nav-ai-container">
                    <img src="/iconAisistenku.png" alt="AI Assistant" className="bottom-nav-ai-img" />
                  </div>
                ) : (
                  <IconComponent className="icon" size={20} />
                )}
                {tab.badge && <span className="nav-badge">{tab.badge}</span>}
              </div>
              <span className="label">{tab.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
