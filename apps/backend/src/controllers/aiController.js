import { supabase } from '../lib/supabase.js';
import { store, DEMO_USER_ID } from '../lib/store.js';

const KELONTONG_API_URL = process.env.KELONTONG_API_URL || 'https://api.kelontongai.my.id/v1';
const KELONTONG_API_KEY = process.env.KELONTONG_API_KEY || '';
const KELONTONG_MODEL = process.env.KELONTONG_MODEL || 'mimo-v2.5';
const KELONTONG_TIMEOUT_MS = 15000;

async function callKelontongAI(messages, opts = {}) {
  if (!KELONTONG_API_KEY) {
    console.warn('[KelontongAI] KELONTONG_API_KEY not set — using local fallback.');
    return null;
  }
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), KELONTONG_TIMEOUT_MS);
  try {
    const res = await fetch(`${KELONTONG_API_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${KELONTONG_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: opts.model || KELONTONG_MODEL,
        messages,
        temperature: opts.temperature ?? 0.5,
        max_tokens: opts.max_tokens ?? 500,
      }),
      signal: controller.signal,
    });
    clearTimeout(timeout);
    if (!res.ok) {
      console.warn(`[KelontongAI] HTTP ${res.status}: ${await res.text().catch(() => '')}`);
      return null;
    }
    const data = await res.json();
    return data?.choices?.[0]?.message?.content || null;
  } catch (err) {
    clearTimeout(timeout);
    if (err.name === 'AbortError') {
      console.warn(`[KelontongAI] request timed out after ${KELONTONG_TIMEOUT_MS}ms`);
    } else {
      console.warn('[KelontongAI] call failed:', err.message);
    }
    return null;
  }
}

export const getAiMessages = async (req, res, next) => {
  try {
    const userId = req.user?.user_id || DEMO_USER_ID;
    let messages = store.aiMessages.filter((m) => m.user_id === userId);

    if (supabase) {
      let q = supabase
        .from('ai_messages')
        .select('*')
        .order('timestamp', { ascending: true });
      if (userId) q = q.eq('user_id', userId);
      const { data, error } = await q;
      if (!error && data) messages = data;
    }
    return res.json({ messages });
  } catch (err) { next(err); }
};

export const sendChatMessage = async (req, res, next) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ error: 'Message text is required' });
    }
    const cleanText = text.trim();
    const now = new Date();
    const lower = cleanText.toLowerCase();

    const userMsg = {
      message_id: `msg-${Date.now()}`,
      user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
      sender: 'USER',
      text: cleanText,
      type: 'text',
      actionPayload: null,
      extra_data: null,
      timestamp: now.toISOString(),
    };
    if (supabase) await supabase.from('ai_messages').insert([userMsg]);
    store.aiMessages.push(userMsg);

    let aiResponseMsg = null;

    // -------- Intent 1: Restock / Beli bahan --------
    if (lower.includes('beli') || lower.includes('belanja') || lower.includes('restock')) {
      let qty = 5, unit = 'kg', item = 'Sugar', price = 170000;

      const qtyRegex = /(\d+(?:[.,]\d+)?)\s*(kg|g|liter|l|botol|btl|dus|karton|pack|pcs)/i;
      const qtyMatch = lower.match(qtyRegex);
      if (qtyMatch) {
        qty = parseFloat(qtyMatch[1].replace(',', '.')) || 5;
        unit = qtyMatch[2].toLowerCase();
      }
      if (lower.includes('gula')) item = 'Sugar';
      else if (lower.includes('kopi') || lower.includes('beans')) item = 'Coffee Beans';
      else if (lower.includes('susu') || lower.includes('milk')) { item = 'Fresh Milk'; unit = 'L'; }
      else if (lower.includes('sirup') || lower.includes('syrup')) { item = 'Caramel Syrup'; unit = 'btl'; }
      else if (lower.includes('minyak')) { item = 'Minyak Goreng SunCo'; unit = 'pouch'; }

      const priceMatch = lower.match(/(?:rp\.?\s*|harga\s*)?(\d+(?:[.,]\d+)?)\s*(rb|ribu|k|000|jt|juta)/i);
      if (priceMatch) {
        const num = parseFloat(priceMatch[1].replace(',', '.'));
        const mult = /jt|juta/i.test(priceMatch[2]) ? 1_000_000 : 1000;
        price = num * mult;
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

      const aiText = await callKelontongAI([
        { role: 'system', content: 'Anda adalah AI asisten bisnis toko kelontong berbahasa Indonesia. Ringkas, sopan, dan actionable.' },
        { role: 'user', content: `Owner ingin mencatat pembelian: ${qty} ${unit} ${item} seharga Rp${price.toLocaleString('id-ID')}. Beri respons singkat (maks 2 kalimat) untuk konfirmasi pencatatan stok & pengeluaran.` },
      ]) || `Saya mendeteksi pembelian ${qty} ${unit} ${item} sebesar Rp${price.toLocaleString('id-ID')}. Apakah saya akan catat ke Stok & Keuangan?`;

      aiResponseMsg = {
        message_id: `msg-${Date.now() + 1}`,
        user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
        sender: 'AI',
        text: aiText,
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
    // -------- Intent 2: Stock inquiry --------
    else if (lower.includes('stok') || lower.includes('habis') || lower.includes('bahan') || lower.includes('menipis')) {
      let items = store.stockItems;
      if (supabase) {
        const { data } = await supabase.from('stock_items').select('*');
        if (data && data.length) items = data;
      }
      const lowItems = items
        .filter((i) => Number(i.current_stock) <= Number(i.min_stock))
        .map((i) => ({
          name: i.name,
          qty: Number(i.current_stock),
          unit: i.unit,
          status: Number(i.current_stock) <= Number(i.min_stock) * 0.6 ? 'Kritis' : 'Rendah',
        }));

      const stockSummary = lowItems.length > 0
        ? lowItems.map((i) => `${i.name} (${i.qty} ${i.unit}, ${i.status})`).join(', ')
        : 'semua stok aman';

      const aiText = await callKelontongAI([
        { role: 'system', content: 'Anda AI asisten toko kelontong. Ringkas & helpful.' },
        { role: 'user', content: `Status stok menipis: ${stockSummary}. Buat respons singkat (maks 2 kalimat) untuk owner.` },
      ]) || (lowItems.length > 0
        ? `Ada ${lowItems.length} bahan baku yang perlu diperhatikan: ${lowItems.map((i) => i.name).join(', ')}.`
        : 'Semua stok bahan baku saat ini dalam kondisi aman (Baik).');

      aiResponseMsg = {
        message_id: `msg-${Date.now() + 1}`,
        user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
        sender: 'AI',
        text: aiText,
        type: 'stockAlert',
        actionPayload: { lowItems },
        extra_data: { lowItems },
        timestamp: new Date().toISOString(),
      };
      if (supabase) await supabase.from('ai_messages').insert([aiResponseMsg]);
    }
    // -------- Intent 3: Caption / Promo --------
    else if (lower.includes('caption') || lower.includes('konten') || lower.includes('sosmed') || lower.includes('promo') || lower.includes('ide')) {
      const aiText = await callKelontongAI([
        { role: 'system', content: 'Anda copywriter media sosial toko kelontong Indonesia. Buat caption singkat, catchy, dengan emoji dan hashtag.' },
        { role: 'user', content: `Buat caption Instagram untuk ${lower.includes('jumat') ? 'Promo Jumat Berkah diskon 20%' : 'Kopi Susu Gula Aren'}. Maks 4 kalimat + 5 hashtag.` },
      ]) || '☕ Kopi Susu Gula Aren spesial @KopiTiga siap balikin semangatmu! #KopiSusuAren #CoffeeShopLife #UMKMJuara';

      const actionId = `cap-${Date.now()}`;
      const actionPayload = {
        actionId,
        intent: 'PROMO_CAPTION',
        captionTitle: lower.includes('jumat') ? 'Promo Spesial Jumat' : 'Rekomendasi Caption',
        captionText: aiText,
        platform: 'Instagram & TikTok',
        status: 'pending',
      };
      aiResponseMsg = {
        message_id: `msg-${Date.now() + 1}`,
        user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
        sender: 'AI',
        text: 'Berikut ide konten & caption yang siap dipakai:',
        type: 'contentCaption',
        actionPayload,
        extra_data: null,
        timestamp: new Date().toISOString(),
      };
      if (supabase) await supabase.from('ai_messages').insert([aiResponseMsg]);
    }
    // -------- Default: General business Q&A via KelontongAI --------
    else {
      // Gather simple business context
      let txCount = 0, totalIncome = 0, totalExpense = 0;
      if (supabase) {
        const { data } = await supabase.from('finance_transactions').select('type, amount');
        if (data) {
          txCount = data.length;
          totalIncome = data.filter((t) => t.type === 'INCOME').reduce((s, t) => s + Number(t.amount), 0);
          totalExpense = data.filter((t) => t.type === 'EXPENSE').reduce((s, t) => s + Number(t.amount), 0);
        }
      }

      const aiText = await callKelontongAI([
        {
          role: 'system',
          content: 'Anda adalah AI Assistant untuk aplikasi manajemen toko kelontong "Tiga Angkatan" berbahasa Indonesia. Berikan jawaban ringkas (maks 3 kalimat), sopan, dan actionable. Gunakan data konteks yang diberikan user.',
        },
        {
          role: 'user',
          content: `Konteks bisnis: total ${txCount} transaksi, pemasukan Rp${totalIncome.toLocaleString('id-ID')}, pengeluaran Rp${totalExpense.toLocaleString('id-ID')}. Pertanyaan owner: "${cleanText}"`,
        },
      ]) || `Kinerja bisnis: ${txCount} transaksi dengan pemasukan Rp${totalIncome.toLocaleString('id-ID')}. Ada yang ingin ditanyakan lebih lanjut?`;

      aiResponseMsg = {
        message_id: `msg-${Date.now() + 1}`,
        user_id: req.user?.user_id || '00000000-0000-0000-0000-000000000001',
        sender: 'AI',
        text: aiText,
        type: 'businessSummary',
        actionPayload: null,
        extra_data: { revenue: totalIncome, expense: totalExpense, txCount },
        timestamp: new Date().toISOString(),
      };
      if (supabase) await supabase.from('ai_messages').insert([aiResponseMsg]);
    }

    store.aiMessages.push(aiResponseMsg);
    return res.json({ userMessage: userMsg, aiResponse: aiResponseMsg });
  } catch (err) { next(err); }
};

export const confirmAiAction = async (req, res, next) => {
  try {
    const { actionId } = req.params;
    let actionItem = store.aiActions.find((a) => a.action_id === actionId);
    const msg = store.aiMessages.find((m) => m.actionPayload && m.actionPayload.actionId === actionId);
    const payload = msg?.actionPayload || actionItem?.payload;
    if (!payload) return res.status(404).json({ error: 'AI Action not found' });

    payload.status = 'confirmed';
    if (actionItem) actionItem.status = 'CONFIRMED';

    let resolvedStockId = null;
    let isNewStock = false;
    let newStockSnapshot = null;

    if (payload.itemName && payload.quantity) {
      // Try store first (dev fallback)…
      let existingIdx = store.stockItems.findIndex(
        (i) => i.name.toLowerCase() === payload.itemName.toLowerCase()
      );

      // …then query DB if store didn't match.
      if (existingIdx === -1 && supabase) {
        const { data } = await supabase
          .from('stock_items')
          .select('*')
          .ilike('name', payload.itemName);
        if (data && data.length) {
          // Mirror into store so subsequent calls work
          store.stockItems.push(data[0]);
          existingIdx = store.stockItems.length - 1;
        }
      }

      if (existingIdx !== -1) {
        store.stockItems[existingIdx].current_stock += Number(payload.quantity);
        store.stockItems[existingIdx].updated_at = new Date().toISOString();
        resolvedStockId = store.stockItems[existingIdx].stock_id;
      } else {
        const slug = `stock-${Date.now()}`;
        const newStock = {
          stock_id: slug,
          name: payload.itemName,
          category: 'Bahan Baku',
          current_stock: Number(payload.quantity),
          min_stock: 5.0,
          unit: payload.unit || 'kg',
          cost_per_unit: Math.round((payload.expenseAmount || 170000) / (payload.quantity || 1)),
          supplier: 'Supplier Utama',
          updated_at: new Date().toISOString(),
        };
        store.stockItems.unshift(newStock);
        resolvedStockId = slug;
        isNewStock = true;
        newStockSnapshot = newStock;
      }

      const log = {
        log_id: `log-${Date.now()}`,
        stock_id: resolvedStockId,
        stock_name: payload.itemName,
        type: 'IN',
        quantity: Number(payload.quantity),
        unit: payload.unit || 'kg',
        source: 'AI Agent',
        reference_code: `#AI-${Date.now().toString().substring(7)}`,
        operator_name: 'AI Assistant',
        note: 'Restock otomatis via konfirmasi AI',
        created_at: new Date().toISOString(),
      };
      store.stockLogs.unshift(log);
      if (supabase) {
        if (isNewStock && newStockSnapshot) {
          await supabase.from('stock_items').insert([newStockSnapshot]);
        } else if (existingIdx !== -1) {
          await supabase
            .from('stock_items')
            .update({ current_stock: store.stockItems[existingIdx].current_stock })
            .eq('stock_id', resolvedStockId);
        }
        await supabase.from('stock_logs').insert([log]);
      }
    }

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
        notes: 'Restock otomatis via konfirmasi AI Assistant',
        timestamp: new Date().toISOString(),
      };
      if (supabase) {
        await supabase.from('finance_transactions').insert([financeTx]);
        await supabase.from('ai_actions').update({ status: 'CONFIRMED' }).eq('action_id', actionId);
      }
      store.financeTransactions.unshift(financeTx);
    }

    return res.json({ message: 'AI action confirmed and executed', actionId, status: 'CONFIRMED', payload });
  } catch (err) { next(err); }
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
  } catch (err) { next(err); }
};