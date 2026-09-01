import { supabase } from '../lib/supabase.js';
import { store } from '../lib/store.js';

export const getFinanceSummary = async (req, res, next) => {
  try {
    const { period = 'today' } = req.query;

    let transactions = store.financeTransactions;
    if (supabase) {
      const { data, error } = await supabase.from('finance_transactions').select('*');
      if (!error && data && data.length > 0) {
        transactions = data;
      }
    }

    let income = 0;
    let expense = 0;

    transactions.forEach((tx) => {
      const amt = Number(tx.amount);
      if (tx.type === 'INCOME') {
        income += amt;
      } else {
        expense += amt;
      }
    });

    if (income === 0 && expense === 0) {
      if (period === 'today') {
        income = 1250000;
        expense = 450000;
      } else if (period === 'thisWeek') {
        income = 4550000;
        expense = 1680000;
      } else {
        income = 18450000;
        expense = 6200000;
      }
    }

    const netProfit = income - expense;
    const grossMargin = income > 0 ? (netProfit / income) * 100 : 0;
    const currentBalance = 5250000 + income - expense;

    // Chart points based on period
    let chartPoints = [];
    if (period === 'today') {
      chartPoints = [
        { label: '08:00', income: 150000, expense: 50000 },
        { label: '10:00', income: 280000, expense: 250000 },
        { label: '12:00', income: 420000, expense: 0 },
        { label: '14:00', income: 210000, expense: 0 },
        { label: '16:00', income: 190000, expense: 150000 },
        { label: '18:00', income: 380000, expense: 0 },
        { label: '20:00', income: 290000, expense: 0 },
      ];
    } else if (period === 'thisWeek') {
      chartPoints = [
        { label: 'Sen', income: 650000, expense: 200000 },
        { label: 'Sel', income: 720000, expense: 150000 },
        { label: 'Rab', income: 590000, expense: 420000 },
        { label: 'Kam', income: 840000, expense: 180000 },
        { label: 'Jum', income: 1100000, expense: 350000 },
        { label: 'Sab', income: 1550000, expense: 480000 },
        { label: 'Min', income: 1420000, expense: 220000 },
      ];
    } else {
      chartPoints = [
        { label: 'Mgg 1', income: 4200000, expense: 1600000 },
        { label: 'Mgg 2', income: 4850000, expense: 1450000 },
        { label: 'Mgg 3', income: 5100000, expense: 1900000 },
        { label: 'Mgg 4', income: 4300000, expense: 1250000 },
      ];
    }

    const peakHours = [
      { timeRange: '08-11', orderCount: 14, revenue: 320000, isPeak: false },
      { timeRange: '12-14', orderCount: 38, revenue: 950000, isPeak: true },
      { timeRange: '15-17', orderCount: 22, revenue: 540000, isPeak: false },
      { timeRange: '18-21', orderCount: 45, revenue: 1180000, isPeak: true },
      { timeRange: '21-23', orderCount: 12, revenue: 260000, isPeak: false },
    ];

    const topProducts = [
      {
        name: 'Kopi Susu Gula Aren',
        soldQuantity: 68,
        totalRevenue: 1224000,
        contributionPercent: 42.5,
        badgeColorHex: '#0D9488',
      },
      {
        name: 'Croissant Butter',
        soldQuantity: 42,
        totalRevenue: 756000,
        contributionPercent: 26.3,
        badgeColorHex: '#14B8A6',
      },
      {
        name: 'Matcha Oat Latte',
        soldQuantity: 28,
        totalRevenue: 588000,
        contributionPercent: 20.4,
        badgeColorHex: '#3B82F6',
      },
    ];

    return res.json({
      summary: {
        currentBalance,
        totalIncome: income,
        totalExpense: expense,
        netProfit,
        grossMarginPercent: Number(grossMargin.toFixed(1)),
      },
      chartPoints,
      peakHours,
      topProducts,
    });
  } catch (err) {
    next(err);
  }
};

export const getTransactions = async (req, res, next) => {
  try {
    const { type, category, query } = req.query;

    let list = store.financeTransactions;
    if (supabase) {
      const { data, error } = await supabase
        .from('finance_transactions')
        .select('*')
        .order('timestamp', { ascending: false });
      if (!error && data && data.length > 0) {
        list = data;
      }
    }

    if (type) {
      list = list.filter((t) => t.type.toLowerCase() === type.toLowerCase());
    }
    if (category) {
      list = list.filter((t) => t.category.toLowerCase() === category.toLowerCase());
    }
    if (query) {
      const q = query.toLowerCase();
      list = list.filter(
        (t) =>
          t.title.toLowerCase().includes(q) ||
          t.category.toLowerCase().includes(q) ||
          (t.notes && t.notes.toLowerCase().includes(q))
      );
    }

    return res.json({ transactions: list });
  } catch (err) {
    next(err);
  }
};

export const createTransaction = async (req, res, next) => {
  try {
    const { title, type = 'EXPENSE', category = 'operational', amount = 0, source = 'MANUAL', notes } = req.body;
    if (!title || !amount || Number(amount) <= 0) {
      return res.status(400).json({ error: 'Title and positive amount are required' });
    }

    const newTx = {
      transaction_id: `tx-${Date.now()}`,
      user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
      order_id: null,
      title: title.trim(),
      type,
      category,
      amount: Number(amount),
      source,
      notes: notes || null,
      timestamp: new Date().toISOString(),
    };

    if (supabase) {
      await supabase.from('finance_transactions').insert([newTx]);
    }
    store.financeTransactions.unshift(newTx);

    return res.status(201).json({ transaction: newTx });
  } catch (err) {
    next(err);
  }
};

export const deleteTransaction = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (supabase) {
      await supabase.from('finance_transactions').delete().eq('transaction_id', id);
    }
    store.financeTransactions = store.financeTransactions.filter((t) => t.transaction_id !== id);

    return res.json({ message: 'Transaction deleted successfully', transaction_id: id });
  } catch (err) {
    next(err);
  }
};
