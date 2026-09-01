import { supabase } from '../lib/supabase.js';
import { store } from '../lib/store.js';

export const createOrder = async (req, res, next) => {
  try {
    const {
      orderType = 'Dine In',
      tableNumber,
      customerName,
      paymentMethod = 'Cash',
      items = [],
      subtotal = 0,
      tax = 0,
      total = 0,
      cashGiven = 0,
      change = 0,
    } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({ error: 'Order must contain at least one item' });
    }

    const orderId = `ord-${Date.now()}`;
    const orderCode = `#3A-${Math.floor(10000 + Math.random() * 90000)}`;

    const newOrder = {
      order_id: orderId,
      order_code: orderCode,
      user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
      order_type: orderType,
      table_number: tableNumber || null,
      customer_name: customerName || null,
      subtotal: Number(subtotal),
      tax: Number(tax),
      total_amount: Number(total),
      payment_method: paymentMethod,
      cash_given: Number(cashGiven),
      change_amount: Number(change),
      status: 'PAID',
      created_at: new Date().toISOString(),
    };

    const newOrderItems = items.map((item, idx) => ({
      order_item_id: `item-${Date.now()}-${idx}`,
      order_id: orderId,
      product_id: item.product_id || item.product?.id || null,
      product_name: item.product_name || item.product?.name || 'Menu Item',
      variant: item.variant || 'Regular',
      quantity: Number(item.quantity || 1),
      price_at_sale: Number(item.price || item.product?.price || 0),
      subtotal: Number(item.subtotal || (item.price || 0) * (item.quantity || 1)),
      note: item.note || null,
    }));

    // Perform database operations if Supabase is active
    if (supabase) {
      await supabase.from('orders').insert([newOrder]);
      await supabase.from('order_items').insert(newOrderItems);
    }

    // Always update store
    store.orders.unshift(newOrder);
    store.orderItems.push(...newOrderItems);

    // Auto deduct recipe stock & create stock log
    for (const orderItem of newOrderItems) {
      const recipes = store.productRecipes.filter(
        (r) => r.product_id === orderItem.product_id
      );

      for (const recipe of recipes) {
        const stockIdx = store.stockItems.findIndex((s) => s.stock_id === recipe.stock_id);
        if (stockIdx !== -1) {
          const deductQty = recipe.quantity_required * orderItem.quantity;
          store.stockItems[stockIdx].current_stock = Math.max(
            0,
            store.stockItems[stockIdx].current_stock - deductQty
          );
          store.stockItems[stockIdx].updated_at = new Date().toISOString();

          // Create stock log OUT
          const stockLog = {
            log_id: `log-${Date.now()}-${Math.random()}`,
            stock_id: recipe.stock_id,
            stock_name: store.stockItems[stockIdx].name,
            type: 'OUT',
            quantity: deductQty,
            unit: store.stockItems[stockIdx].unit,
            source: 'POS',
            reference_code: orderCode,
            operator_name: req.user?.name || 'Kasir',
            note: `Penjualan ${orderItem.product_name} (${orderItem.quantity}x)`,
            created_at: new Date().toISOString(),
          };

          if (supabase) {
            await supabase.from('stock_logs').insert([stockLog]);
            await supabase
              .from('stock_items')
              .update({ current_stock: store.stockItems[stockIdx].current_stock })
              .eq('stock_id', recipe.stock_id);
          }
          store.stockLogs.unshift(stockLog);
        }
      }
    }

    // Auto record Income transaction in finance
    const financeTx = {
      transaction_id: `tx-${Date.now()}`,
      user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
      order_id: orderId,
      title: `Penjualan POS ${orderCode}`,
      type: 'INCOME',
      category: 'sales',
      amount: Number(total),
      source: 'POS_AUTOMATIC',
      notes: `Pesanan ${orderType} - ${items.length} item`,
      timestamp: new Date().toISOString(),
    };

    if (supabase) {
      await supabase.from('finance_transactions').insert([financeTx]);
    }
    store.financeTransactions.unshift(financeTx);

    return res.status(201).json({
      message: 'Order created successfully',
      order: newOrder,
      items: newOrderItems,
    });
  } catch (err) {
    next(err);
  }
};

export const getOrders = async (_req, res, next) => {
  try {
    if (supabase) {
      const { data, error } = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', { ascending: false });
      if (!error && data && data.length > 0) {
        return res.json({ orders: data });
      }
    }

    const ordersWithItems = store.orders.map((ord) => ({
      ...ord,
      items: store.orderItems.filter((i) => i.order_id === ord.order_id),
    }));

    return res.json({ orders: ordersWithItems });
  } catch (err) {
    next(err);
  }
};

export const getOrderById = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (supabase) {
      const { data, error } = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('order_id', id)
        .single();
      if (!error && data) {
        return res.json({ order: data });
      }
    }

    const order = store.orders.find((o) => o.order_id === id);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const items = store.orderItems.filter((i) => i.order_id === id);
    return res.json({ order: { ...order, items } });
  } catch (err) {
    next(err);
  }
};
