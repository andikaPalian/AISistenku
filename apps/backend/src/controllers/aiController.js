import { supabase } from '../lib/supabase.js';
import { store } from '../lib/store.js';

export const getAiMessages = async (_req, res, next) => {
  try {
    let messages = store.aiMessages;
    if (supabase) {
      const { data, error } = await supabase
        .from('ai_messages')
        .select('*, ai_actions(*)')
        .order('timestamp', { ascending: true });
      if (!error && data && data.length > 0) {
        messages = data;
      }
    }

    return res.json({ messages });
  } catch (err) {
    next(err);
  }
};

export const sendChatMessage = async (req, res, next) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ error: 'Message text is required' });
    }

    const cleanText = text.trim();
    const now = new Date();

    const userMsg = {
      message_id: `msg-${Date.now()}`,
      user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
      sender: 'USER',
      text: cleanText,
      type: 'text',
      extra_data: null,
      timestamp: now.toISOString(),
    };

    if (supabase) {
      await supabase.from('ai_messages').insert([userMsg]);
    }
    store.aiMessages.push(userMsg);

    // Generate AI response with Rule-based NLP Engine
    const lower = cleanText.toLowerCase();
    let aiResponseMsg = null;

    // 1. Purchase / Expense / Restock Intent
    if (
      lower.includes('beli') ||
      lower.includes('belanja') ||
      lower.includes('restock') ||
      lower.includes('habis beli')
    ) {
      let qty = 5;
      let unit = 'kg';
      let item = 'Sugar';
      let price = 170000;

      const qtyRegex = /(\d+)\s*(kg|g|liter|l|botol|btl|dus|karton|pack|pcs)/i;
      const qtyMatch = lower.match(qtyRegex);
      if (qtyMatch) {
        qty = parseFloat(qtyMatch[1]) || 5;
        unit = qtyMatch[2].toLowerCase();
      }

      if (lower.includes('gula')) item = 'Sugar';
      else if (lower.includes('kopi') || lower.includes('beans')) item = 'Coffee Beans';
      else if (lower.includes('susu') || lower.includes('milk')) {
        item = 'Fresh Milk';
        unit = 'L';
      } else if (lower.includes('sirup') || lower.includes('syrup')) {
        item = 'Caramel Syrup';
        unit = 'btl';
      }

      const priceRegex = /(\d+)\s*(rb|ribu|k|000)/i;
      const priceMatch = lower.match(priceRegex);
      if (priceMatch) {
        const rawNum = parseInt(priceMatch[1], 10) || 170;
        price = rawNum * 1000;
      }

      const actionId = `act-${Date.now()}`;
      const actionPayload = {
        actionId,
        intent: 'ADD_STOCK_AND_EXPENSE',
        itemName: item,
        quantity: qty,
        unit,
        expenseAmount: price,
        category: 'Bahan Baku',
        status: 'pending',
      };

      aiResponseMsg = {
        message_id: `msg-${Date.now() + 1}`,
        user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
        sender: 'AI',
        text: 'Saya mendeteksi transaksi pembelian baru. Apakah ingin saya catat ke Stok & Keuangan?',
        type: 'actionConfirm',
        actionPayload,
        extra_data: null,
        timestamp: new Date().toISOString(),
      };

      const aiAction = {
        action_id: actionId,
        message_id: aiResponseMsg.message_id,
        intent: 'ADD_STOCK_AND_EXPENSE',
        payload: actionPayload,
        status: 'PENDING',
        created_at: new Date().toISOString(),
      };

      if (supabase) {
        await supabase.from('ai_messages').insert([aiResponseMsg]);
        await supabase.from('ai_actions').insert([aiAction]);
      }
      store.aiActions.push(aiAction);
    }
    // 2. Social Media / Caption Generation
    else if (
      lower.includes('caption') ||
      lower.includes('konten') ||
      lower.includes('sosmed') ||
      lower.includes('promo') ||
      lower.includes('ide')
    ) {
      let title = 'Rekomendasi Konten Instagram & TikTok';
      let captionText =
        '☕ Ngantuk di jam rawan siang? Tenang, segelas Kopi Susu Gula Aren racikan spesial @KopiTiga siap balikin semangatmu!\n\nPaduan espresso mantap, susu creamy, dan manis legit aren asli bikin harimu makin fokus. Yuk mampir atau order via POS sekarang!';
      let hashtags = ['#KopiSusuAren', '#NgopiSore', '#PromoKopi', '#CoffeeShopLife', '#UMKMJuara'];

      if (lower.includes('diskon') || lower.includes('jumat')) {
        title = 'Promo Spesial Jumat Berkah 🎁';
        captionText =
          '✨ Jumat Berkah, ngopi makin hemat! Dapatkan Diskon 20% untuk semua varian Non-Kopi & Snack setiap pembelian Kopi Susu Aren hari ini.\n\nTag teman nongkrongmu dan serbu outlet sebelum kehabisan!';
        hashtags = ['#JumatBerkah', '#PromoJumat', '#DiskonKopi', '#KopiLokal'];
      }

      const actionId = `cap-${Date.now()}`;
      const actionPayload = {
        actionId,
        intent: 'PROMO_CAPTION',
        captionTitle: title,
        captionText,
        hashtags,
        platform: 'Instagram & TikTok',
        tone: 'Santai & Menarik',
        status: 'pending',
      };

      aiResponseMsg = {
        message_id: `msg-${Date.now() + 1}`,
        user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
        sender: 'AI',
        text: 'Berikut rekomendasi ide konten dan caption menarik yang siap Anda gunakan:',
        type: 'contentCaption',
        actionPayload,
        extra_data: null,
        timestamp: new Date().toISOString(),
      };

      if (supabase) {
        await supabase.from('ai_messages').insert([aiResponseMsg]);
      }
    }
    // 3. Stock Inquiries
    else if (lower.includes('stok') || lower.includes('habis') || lower.includes('bahan')) {
      const lowItems = store.stockItems
        .filter((i) => i.current_stock <= i.min_stock)
        .map((i) => ({
          name: i.name,
          qty: i.current_stock,
          unit: i.unit,
          status: i.current_stock <= i.min_stock * 0.6 ? 'Kritis' : 'Rendah',
        }));

      aiResponseMsg = {
        message_id: `msg-${Date.now() + 1}`,
        user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
        sender: 'AI',
        text:
          lowItems.length > 0
            ? `Ada ${lowItems.length} bahan baku yang perlu diperhatikan karena berada di bawah batas aman minimum:`
            : 'Semua stok bahan baku saat ini berada dalam kondisi aman (Baik).',
        type: 'stockAlert',
        extra_data: { lowItems },
        timestamp: new Date().toISOString(),
      };

      if (supabase) {
        await supabase.from('ai_messages').insert([aiResponseMsg]);
      }
    }
    // 4. Default / Business Overview Query
    else {
      aiResponseMsg = {
        message_id: `msg-${Date.now() + 1}`,
        user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
        sender: 'AI',
        text: 'Kinerja bisnis hari ini berjalan lancar. Total penjualan mencapai Rp1.250.000 dengan estimasi laba bersih Rp800.000.',
        type: 'businessSummary',
        extra_data: {
          revenue: 1250000.0,
          profit: 800000.0,
          bestSeller: 'Iced Latte',
        },
        timestamp: new Date().toISOString(),
      };

      if (supabase) {
        await supabase.from('ai_messages').insert([aiResponseMsg]);
      }
    }

    store.aiMessages.push(aiResponseMsg);

    return res.json({
      userMessage: userMsg,
      aiResponse: aiResponseMsg,
    });
  } catch (err) {
    next(err);
  }
};

export const confirmAiAction = async (req, res, next) => {
  try {
    const { actionId } = req.params;

    // Find action in store or supabase
    let actionItem = store.aiActions.find((a) => a.action_id === actionId);

    // Find message containing action payload
    const msg = store.aiMessages.find(
      (m) => m.actionPayload && m.actionPayload.actionId === actionId
    );

    const payload = msg?.actionPayload || actionItem?.payload;
    if (!payload) {
      return res.status(404).json({ error: 'AI Action not found' });
    }

    payload.status = 'confirmed';
    if (actionItem) actionItem.status = 'CONFIRMED';

    // Execute mutations if action is ADD_STOCK_AND_EXPENSE or RESTOCK
    if (payload.itemName && payload.quantity) {
      const existingIdx = store.stockItems.findIndex(
        (i) => i.name.toLowerCase() === payload.itemName.toLowerCase()
      );

      if (existingIdx !== -1) {
        store.stockItems[existingIdx].current_stock += Number(payload.quantity);
        store.stockItems[existingIdx].updated_at = new Date().toISOString();
      } else {
        const newStock = {
          stock_id: `stock-${Date.now()}`,
          name: payload.itemName,
          category: 'Gula & Pemanis',
          current_stock: Number(payload.quantity),
          min_stock: 5.0,
          unit: payload.unit || 'kg',
          cost_per_unit: Math.round(
            (payload.expenseAmount || 170000) / (payload.quantity || 1)
          ),
          supplier: 'Supplier Utama',
          updated_at: new Date().toISOString(),
        };
        store.stockItems.unshift(newStock);
      }

      // Add Stock Log
      const log = {
        log_id: `log-${Date.now()}`,
        stock_id: existingIdx !== -1 ? store.stockItems[existingIdx].stock_id : `stock-${Date.now()}`,
        stock_name: payload.itemName,
        type: 'IN',
        quantity: Number(payload.quantity),
        unit: payload.unit || 'kg',
        source: 'AI Agent',
        reference_code: `#AI-${Date.now().toString().substring(7)}`,
        operator_name: 'AI Asisten',
        note: 'Restock otomatis via konfirmasi AIsisten',
        created_at: new Date().toISOString(),
      };
      store.stockLogs.unshift(log);

      if (supabase) {
        await supabase.from('stock_logs').insert([log]);
      }
    }

    // Add Finance Expense
    if (payload.expenseAmount && payload.expenseAmount > 0) {
      const financeTx = {
        transaction_id: `tx-${Date.now()}`,
        user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
        order_id: null,
        title: `Pembelian ${payload.itemName || 'Bahan Baku'}`,
        type: 'EXPENSE',
        category: 'ingredients',
        amount: Number(payload.expenseAmount),
        source: 'AI_AGENT',
        notes: 'Restock otomatis via konfirmasi AIsisten',
        timestamp: new Date().toISOString(),
      };

      if (supabase) {
        await supabase.from('finance_transactions').insert([financeTx]);
        await supabase
          .from('ai_actions')
          .update({ status: 'CONFIRMED' })
          .eq('action_id', actionId);
      }
      store.financeTransactions.unshift(financeTx);
    }

    return res.json({
      message: 'AI action confirmed and executed successfully',
      actionId,
      status: 'CONFIRMED',
      payload,
    });
  } catch (err) {
    next(err);
  }
};

export const clearAiMessages = async (_req, res, next) => {
  try {
    if (supabase) {
      await supabase.from('ai_messages').delete().neq('message_id', '0');
      await supabase.from('ai_actions').delete().neq('action_id', '0');
    }
    store.aiMessages = [];
    store.aiActions = [];

    return res.json({ message: 'Chat history cleared' });
  } catch (err) {
    next(err);
  }
};
