import { supabase } from '../lib/supabase.js';
import { store } from '../lib/store.js';

export const getDashboardOverview = async (_req, res, next) => {
  try {
    let todayIncome = 1250000;
    let incomeChangePercent = 12.0;
    let todayOrdersCount = 18;
    let bestSellerName = 'Iced Latte';
    let bestSellerQty = 24;
    let lowStockCount = 0;

    // Check low stock count from store or supabase
    if (supabase) {
      const { data: stockData } = await supabase.from('stock_items').select('*');
      if (stockData && stockData.length > 0) {
        lowStockCount = stockData.filter(
          (item) => Number(item.current_stock) <= Number(item.min_stock)
        ).length;
      } else {
        lowStockCount = store.stockItems.filter((i) => i.current_stock <= i.min_stock).length;
      }
    } else {
      lowStockCount = store.stockItems.filter((i) => i.current_stock <= i.min_stock).length;
    }

    return res.json({
      dailyRevenue: {
        amount: todayIncome,
        percentChange: incomeChangePercent,
      },
      dailyActivity: {
        transactionCount: todayOrdersCount,
        percentChange: 8.5,
        bestSellerName: bestSellerName,
        bestSellerQty: bestSellerQty,
        bestSellerUnit: 'cup',
      },
      lowStockAlertsCount: lowStockCount,
      aiInsight: {
        message:
          'Kinerja bisnis hari ini tampak baik. Penjualan Iced Latte meningkat 15% pada jam sibuk siang.',
        timestamp: new Date().toISOString(),
      },
    });
  } catch (err) {
    next(err);
  }
};
