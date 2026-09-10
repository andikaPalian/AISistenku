import React, { useState } from 'react';
import { TabType, CartItem } from '../../types';
import { SidebarNav } from './SidebarNav';
import { BottomNav } from './BottomNav';
import { HomeScreen } from '../../screens/HomeScreen';
import { PosScreen } from '../../screens/PosScreen';
import { StockScreen } from '../../screens/StockScreen';
import { FinanceScreen } from '../../screens/FinanceScreen';
import { AiAssistantScreen } from '../../screens/AiAssistantScreen';
import { useProducts, useStocks, useTransactions, useDashboard, useAiMessages, useStockAlerts } from '../../hooks/useData';
import { logout } from '../../lib/auth';

export const ShellLayout: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabType>('home');
  const [cart, setCart] = useState<CartItem[]>([]);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState<boolean>(() => {
    return localStorage.getItem('sidebar_collapsed') === 'true';
  });

  const toggleSidebar = () => {
    setIsSidebarCollapsed((prev) => {
      const next = !prev;
      localStorage.setItem('sidebar_collapsed', String(next));
      return next;
    });
  };

  const productsHook = useProducts();
  const stocksHook = useStocks();
  const transactionsHook = useTransactions();
  const dashboardHook = useDashboard();
  const aiHook = useAiMessages();
  const alertsHook = useStockAlerts();

  const renderScreen = () => {
    switch (activeTab) {
      case 'home':
        return (
          <HomeScreen
            onNavigateTab={setActiveTab}
            stockAlerts={alertsHook.data}
            dashboard={dashboardHook.data}
            dashboardLoading={dashboardHook.loading}
          />
        );
      case 'pos':
        return (
          <PosScreen
            products={productsHook.data}
            productsLoading={productsHook.loading}
            onCheckout={async (payload) => {
              const order = await productsHook.createOrder(payload);
              await Promise.all([stocksHook.refresh(), transactionsHook.refresh(), alertsHook.refresh()]);
              return order;
            }}
            cart={cart}
            setCart={setCart}
          />
        );
      case 'stock':
        return (
          <StockScreen
            products={stocksHook.data}
            loading={stocksHook.loading}
            onRestock={stocksHook.restock}
            onAdjust={stocksHook.adjust}
            onCreateItem={async (body) => {
              const item = await stocksHook.create(body);
              await Promise.all([stocksHook.refresh(), productsHook.refresh(), alertsHook.refresh()]);
              return item;
            }}
            onUpdateItem={async (id, body) => {
              const item = await stocksHook.update(id, body);
              await Promise.all([stocksHook.refresh(), productsHook.refresh(), alertsHook.refresh()]);
              return item;
            }}
            onDeleteItem={async (id) => {
              await stocksHook.remove(id);
              await Promise.all([stocksHook.refresh(), productsHook.refresh(), alertsHook.refresh()]);
            }}
            refresh={stocksHook.refresh}
          />
        );
      case 'finance':
        return (
          <FinanceScreen
            transactions={transactionsHook.data}
            loading={transactionsHook.loading}
            onCreate={transactionsHook.create}
            onRefresh={transactionsHook.refresh}
          />
        );
        case 'ai':
          return (
            <AiAssistantScreen
              onNavigateTab={setActiveTab}
              messages={aiHook.data}
              messagesRaw={aiHook.raw}
              loading={aiHook.loading}
              onSend={aiHook.send}
              onConfirmAction={async (actionId: string) => {
                await aiHook.confirmAction(actionId);
                await Promise.all([stocksHook.refresh(), transactionsHook.refresh()]);
              }}
              onClear={aiHook.clear}
              refresh={aiHook.refresh}
            />
          );
      default:
        return (
          <HomeScreen
            onNavigateTab={setActiveTab}
            stockAlerts={alertsHook.data}
            dashboard={dashboardHook.data}
            dashboardLoading={dashboardHook.loading}
          />
        );
    }
  };

  const totalCartCount = cart.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <div className="app-container">
      <SidebarNav
        activeTab={activeTab}
        onTabChange={setActiveTab}
        cartCount={totalCartCount}
        stockAlertCount={alertsHook.data.length}
        isCollapsed={isSidebarCollapsed}
        onToggleCollapse={toggleSidebar}
        onLogout={logout}
      />

      <main className={`main-content ${isSidebarCollapsed ? 'collapsed-sidebar' : ''}`}>
        {renderScreen()}

        <BottomNav
          activeTab={activeTab}
          onTabChange={setActiveTab}
          cartCount={totalCartCount}
        />
      </main>
    </div>
  );
};

export default ShellLayout;
