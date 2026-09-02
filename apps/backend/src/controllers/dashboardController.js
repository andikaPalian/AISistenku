import { supabase } from '../lib/supabase.js';
import { store, DEMO_USER_ID } from '../lib/store.js';

export const getDashboardOverview = async (req, res, next) => {
  try {
    const userId = req.user?.user_id || DEMO_USER_ID;
    const isDemoUser = userId === DEMO_USER_ID;

    if (isDemoUser) {
      let lowStockCount = store.stockItems.filter(
        (i) => i.user_id === DEMO_USER_ID && i.current_stock <= i.min_stock
      ).length;

      return res.json({
        dailyRevenue: {
          amount: 1250000,
          percentChange: 12.0,
        },
        dailyActivity: {
          transactionCount: 18,
          percentChange: 8.5,
          bestSellerName: 'Iced Latte',
          bestSellerQty: 24,
          bestSellerUnit: 'cup',
        },
        lowStockAlertsCount: lowStockCount,
        aiInsight: {
          message:
            'Kinerja bisnis hari ini tampak baik. Penjualan Iced Latte meningkat 15% pada jam sibuk siang.',
          timestamp: new Date().toISOString(),
        },
      });
    }

    // Real user calculations
    let userOrders = store.orders.filter((o) => o.user_id === userId);
    let userStocks = store.stockItems.filter((s) => s.user_id === userId);

    if (supabase) {
      const { data: ords } = await supabase.from('orders').select('*').eq('user_id', userId);
      if (ords) userOrders = ords;
      const { data: stks } = await supabase.from('stock_items').select('*').eq('user_id', userId);
      if (stks) userStocks = stks;
    }

    const todayIncome = userOrders.reduce((sum, o) => sum + (Number(o.total_amount) || 0), 0);
    const lowStockCount = userStocks.filter((s) => Number(s.current_stock) <= Number(s.min_stock)).length;

    return res.json({
      dailyRevenue: {
        amount: todayIncome,
        percentChange: 0.0,
      },
      dailyActivity: {
        transactionCount: userOrders.length,
        percentChange: 0.0,
        bestSellerName: userOrders.length > 0 ? 'Menu Pilihan' : '-',
        bestSellerQty: userOrders.length > 0 ? userOrders.length : 0,
        bestSellerUnit: 'cup',
      },
      lowStockAlertsCount: lowStockCount,
      aiInsight: {
        message: userOrders.length > 0 || userStocks.length > 0
          ? 'Data operasional Anda telah sinkron secara realtime.'
          : 'Selamat datang! Tambahkan produk menu dan bahan baku pertama Anda di menu Produk & Stok untuk memulai penjualan.',
        timestamp: new Date().toISOString(),
      },
    });
  } catch (err) {
    next(err);
  }
};
