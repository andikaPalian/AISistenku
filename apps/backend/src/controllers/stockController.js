import { supabase } from '../lib/supabase.js';
import { store } from '../lib/store.js';

const computeStockStatus = (currentStock, minStock) => {
  if (currentStock <= minStock * 0.6) {
    return 'kritis';
  } else if (currentStock <= minStock) {
    return 'rendah';
  } else {
    return 'baik';
  }
};

export const getStocks = async (req, res, next) => {
  try {
    const { category } = req.query;

    let items = store.stockItems;
    if (supabase) {
      const { data, error } = await supabase.from('stock_items').select('*');
      if (!error && data && data.length > 0) {
        items = data;
      }
    }

    if (category && category !== 'Semua') {
      items = items.filter((i) => i.category === category);
    }

    const formattedItems = items.map((item) => {
      const curr = Number(item.current_stock);
      const min = Number(item.min_stock);
      const cost = Number(item.cost_per_unit || 0);
      const status = computeStockStatus(curr, min);

      return {
        ...item,
        current_stock: curr,
        min_stock: min,
        cost_per_unit: cost,
        status,
        health_ratio: min <= 0 ? 1.0 : Math.min(1.0, Math.max(0.0, curr / (min * 2))),
        total_value: Math.round(curr * cost),
      };
    });

    return res.json({ stocks: formattedItems });
  } catch (err) {
    next(err);
  }
};

export const getStockSummary = async (_req, res, next) => {
  try {
    let items = store.stockItems;
    if (supabase) {
      const { data, error } = await supabase.from('stock_items').select('*');
      if (!error && data && data.length > 0) {
        items = data;
      }
    }

    let lowCount = 0;
    let criticalCount = 0;
    let safeCount = 0;
    let totalValue = 0;

    items.forEach((item) => {
      const curr = Number(item.current_stock);
      const min = Number(item.min_stock);
      const cost = Number(item.cost_per_unit || 0);
      const status = computeStockStatus(curr, min);

      if (status === 'kritis') criticalCount++;
      else if (status === 'rendah') lowCount++;
      else safeCount++;

      totalValue += Math.round(curr * cost);
    });

    return res.json({
      summary: {
        totalItemsCount: items.length,
        safeStockCount: safeCount,
        lowStockCount: lowCount,
        criticalStockCount: criticalCount,
        totalInventoryValue: totalValue,
      },
    });
  } catch (err) {
    next(err);
  }
};

export const getStockLogs = async (req, res, next) => {
  try {
    const { id } = req.params;

    let logs = store.stockLogs.filter((l) => l.stock_id === id);
    if (supabase) {
      const { data, error } = await supabase
        .from('stock_logs')
        .select('*')
        .eq('stock_id', id)
        .order('created_at', { ascending: false });
      if (!error && data && data.length > 0) {
        logs = data;
      }
    }

    return res.json({ logs });
  } catch (err) {
    next(err);
  }
};

export const createStock = async (req, res, next) => {
  try {
    const { name, category = 'Topping & Lainnya', current_stock = 0, min_stock = 5, unit = 'kg', cost_per_unit = 0, supplier, note } = req.body;
    if (!name) {
      return res.status(400).json({ error: 'Stock name is required' });
    }

    const newItem = {
      stock_id: `stock-${Date.now()}`,
      name,
      category,
      current_stock: Number(current_stock),
      min_stock: Number(min_stock),
      unit,
      cost_per_unit: Number(cost_per_unit),
      supplier: supplier || 'Supplier Utama',
      note: note || null,
      updated_at: new Date().toISOString(),
    };

    if (supabase) {
      await supabase.from('stock_items').insert([newItem]);
    }
    store.stockItems.unshift(newItem);

    // Audit log
    const initLog = {
      log_id: `log-${Date.now()}`,
      stock_id: newItem.stock_id,
      stock_name: newItem.name,
      type: 'IN',
      quantity: newItem.current_stock,
      unit: newItem.unit,
      source: 'Stok Awal',
      operator_name: req.user?.name || 'Owner',
      note: 'Pendaftaran bahan baku baru',
      created_at: new Date().toISOString(),
    };

    if (supabase) {
      await supabase.from('stock_logs').insert([initLog]);
    }
    store.stockLogs.unshift(initLog);

    return res.status(201).json({ stock: newItem });
  } catch (err) {
    next(err);
  }
};

export const updateStock = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, category, min_stock, unit, cost_per_unit, supplier, note } = req.body;

    const idx = store.stockItems.findIndex((i) => i.stock_id === id);
    if (idx === -1) {
      return res.status(404).json({ error: 'Stock item not found' });
    }

    const updated = {
      ...store.stockItems[idx],
      name: name ?? store.stockItems[idx].name,
      category: category ?? store.stockItems[idx].category,
      min_stock: min_stock !== undefined ? Number(min_stock) : store.stockItems[idx].min_stock,
      unit: unit ?? store.stockItems[idx].unit,
      cost_per_unit: cost_per_unit !== undefined ? Number(cost_per_unit) : store.stockItems[idx].cost_per_unit,
      supplier: supplier ?? store.stockItems[idx].supplier,
      note: note ?? store.stockItems[idx].note,
      updated_at: new Date().toISOString(),
    };

    if (supabase) {
      await supabase.from('stock_items').update(updated).eq('stock_id', id);
    }
    store.stockItems[idx] = updated;

    return res.json({ stock: updated });
  } catch (err) {
    next(err);
  }
};

export const deleteStock = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (supabase) {
      await supabase.from('stock_items').delete().eq('stock_id', id);
      await supabase.from('stock_logs').delete().eq('stock_id', id);
    }

    store.stockItems = store.stockItems.filter((i) => i.stock_id !== id);
    store.stockLogs = store.stockLogs.filter((l) => l.stock_id !== id);

    return res.json({ message: 'Stock item deleted successfully', stock_id: id });
  } catch (err) {
    next(err);
  }
};

export const restockItem = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { quantity, cost_per_unit, supplier, note, recordExpense = true } = req.body;

    if (!quantity || Number(quantity) <= 0) {
      return res.status(400).json({ error: 'Quantity must be greater than 0' });
    }

    const idx = store.stockItems.findIndex((i) => i.stock_id === id);
    if (idx === -1) {
      return res.status(404).json({ error: 'Stock item not found' });
    }

    const addedQty = Number(quantity);
    const updatedCost = cost_per_unit ? Number(cost_per_unit) : store.stockItems[idx].cost_per_unit;

    store.stockItems[idx].current_stock += addedQty;
    store.stockItems[idx].cost_per_unit = updatedCost;
    if (supplier) store.stockItems[idx].supplier = supplier;
    store.stockItems[idx].updated_at = new Date().toISOString();

    const log = {
      log_id: `log-${Date.now()}`,
      stock_id: id,
      stock_name: store.stockItems[idx].name,
      type: 'IN',
      quantity: addedQty,
      unit: store.stockItems[idx].unit,
      source: 'Restock / Pembelian',
      reference_code: `#RC-${Date.now().toString().substring(7)}`,
      operator_name: req.user?.name || 'Owner',
      note: note || null,
      created_at: new Date().toISOString(),
    };

    if (supabase) {
      await supabase
        .from('stock_items')
        .update({
          current_stock: store.stockItems[idx].current_stock,
          cost_per_unit: updatedCost,
          supplier: store.stockItems[idx].supplier,
          updated_at: store.stockItems[idx].updated_at,
        })
        .eq('stock_id', id);

      await supabase.from('stock_logs').insert([log]);
    }
    store.stockLogs.unshift(log);

    // Optional Finance Expense
    let financeTx = null;
    if (recordExpense) {
      const expenseAmount = addedQty * updatedCost;
      financeTx = {
        transaction_id: `tx-${Date.now()}`,
        user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
        order_id: null,
        title: `Restock ${store.stockItems[idx].name}`,
        type: 'EXPENSE',
        category: 'ingredients',
        amount: expenseAmount,
        source: 'MANUAL',
        notes: note || `Pembelian ${addedQty} ${store.stockItems[idx].unit} ${store.stockItems[idx].name}`,
        timestamp: new Date().toISOString(),
      };

      if (supabase) {
        await supabase.from('finance_transactions').insert([financeTx]);
      }
      store.financeTransactions.unshift(financeTx);
    }

    return res.json({
      message: 'Restock successful',
      stock: store.stockItems[idx],
      log,
      financeTransaction: financeTx,
    });
  } catch (err) {
    next(err);
  }
};

export const adjustStock = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { actual_quantity, reason, note } = req.body;

    if (actual_quantity === undefined || actual_quantity < 0) {
      return res.status(400).json({ error: 'Actual quantity must be 0 or greater' });
    }

    const idx = store.stockItems.findIndex((i) => i.stock_id === id);
    if (idx === -1) {
      return res.status(404).json({ error: 'Stock item not found' });
    }

    const currentQty = store.stockItems[idx].current_stock;
    const newQty = Number(actual_quantity);
    const delta = Math.abs(newQty - currentQty);
    const isDeduction = newQty < currentQty;

    store.stockItems[idx].current_stock = newQty;
    store.stockItems[idx].updated_at = new Date().toISOString();

    const log = {
      log_id: `log-${Date.now()}`,
      stock_id: id,
      stock_name: store.stockItems[idx].name,
      type: isDeduction ? 'OUT' : 'IN',
      quantity: delta,
      unit: store.stockItems[idx].unit,
      source: `Opname: ${reason || 'Penyesuaian Fisik'}`,
      reference_code: `#OP-${Date.now().toString().substring(7)}`,
      operator_name: req.user?.name || 'Owner',
      note: note || null,
      created_at: new Date().toISOString(),
    };

    if (supabase) {
      await supabase
        .from('stock_items')
        .update({ current_stock: newQty, updated_at: store.stockItems[idx].updated_at })
        .eq('stock_id', id);

      await supabase.from('stock_logs').insert([log]);
    }
    store.stockLogs.unshift(log);

    return res.json({
      message: 'Stock adjusted successfully',
      stock: store.stockItems[idx],
      log,
    });
  } catch (err) {
    next(err);
  }
};
