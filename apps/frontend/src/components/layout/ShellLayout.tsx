import React, { useState } from 'react';
import { TabType, Product, Transaction, StockAlert, AiChatMessage, CartItem } from '../../types';
import { INITIAL_PRODUCTS, INITIAL_TRANSACTIONS, STOCK_ALERTS, INITIAL_CHAT_MESSAGES } from '../../mockData';
import { TopHeader, ViewportMode } from './TopHeader';
import { SidebarNav } from './SidebarNav';
import { BottomNav } from './BottomNav';
import { HomeScreen } from '../../screens/HomeScreen';
import { PosScreen } from '../../screens/PosScreen';
import { StockScreen } from '../../screens/StockScreen';
import { FinanceScreen } from '../../screens/FinanceScreen';
import { AiAssistantScreen } from '../../screens/AiAssistantScreen';

export const ShellLayout: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabType>('home');
  const [viewportMode, setViewportMode] = useState<ViewportMode>('responsive');

  // Shared App State
  const [products, setProducts] = useState<Product[]>(INITIAL_PRODUCTS);
  const [transactions, setTransactions] = useState<Transaction[]>(INITIAL_TRANSACTIONS);
  const [stockAlerts, setStockAlerts] = useState<StockAlert[]>(STOCK_ALERTS);
  const [messages, setMessages] = useState<AiChatMessage[]>(INITIAL_CHAT_MESSAGES);
  const [cart, setCart] = useState<CartItem[]>([]);

  const handleAddTransaction = (newTx: Transaction) => {
    setTransactions((prev) => [newTx, ...prev]);

    // Update stock levels if sale
    if (newTx.type === 'sale') {
      setProducts((prev) =>
        prev.map((p) => {
          const cartMatch = cart.find((c) => c.product.id === p.id);
          if (cartMatch) {
            const updatedStock = Math.max(0, p.stock - cartMatch.quantity);
            return { ...p, stock: updatedStock };
          }
          return p;
        })
      );
    }
  };

  // Determine active view component
  const renderScreen = () => {
    switch (activeTab) {
      case 'home':
        return <HomeScreen onNavigateTab={setActiveTab} stockAlerts={stockAlerts} />;
      case 'pos':
        return (
          <PosScreen
            products={products}
            onAddTransaction={handleAddTransaction}
            cart={cart}
            setCart={setCart}
          />
        );
      case 'stock':
        return <StockScreen products={products} setProducts={setProducts} />;
      case 'finance':
        return (
          <FinanceScreen
            transactions={transactions}
            onAddTransaction={(tx) => setTransactions((prev) => [tx, ...prev])}
          />
        );
      case 'ai':
        return (
          <AiAssistantScreen
            onNavigateTab={setActiveTab}
            messages={messages}
            setMessages={setMessages}
          />
        );
      default:
        return <HomeScreen onNavigateTab={setActiveTab} stockAlerts={stockAlerts} />;
    }
  };

  const totalCartCount = cart.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <div className={`app-container viewport-${viewportMode}`}>
      {/* Sidebar for Tablet/Desktop */}
      <SidebarNav
        activeTab={activeTab}
        onTabChange={setActiveTab}
        cartCount={totalCartCount}
        stockAlertCount={stockAlerts.length}
      />

      {/* Main Content Area */}
      <main className="main-content">
        <TopHeader
          viewportMode={viewportMode}
          onViewportChange={setViewportMode}
          unreadCount={stockAlerts.length}
        />

        {/* Viewport Frame Simulator Wrapper */}
        <div className={`viewport-frame-wrapper ${viewportMode}`}>
          <div className="viewport-inner">
            {renderScreen()}
          </div>
        </div>

        {/* Bottom Nav for Mobile */}
        <BottomNav
          activeTab={activeTab}
          onTabChange={setActiveTab}
          cartCount={totalCartCount}
        />
      </main>
    </div>
  );
};
