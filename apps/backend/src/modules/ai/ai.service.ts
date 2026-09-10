import { prisma } from '@/config/database.config.js';
import { env } from '@/config/env.config.js';
import { logger } from '@/utils/logger.js';
import {
  ActionStatus,
  FinanceSource,
  FinanceType,
  MessageSender,
  StockLogSource,
  StockLogType,
} from '@prisma/client';
import {
  executeAddExpenseProposal,
  executeAddStockProposal,
  executeGetExpense,
  executeGetSales,
  executeGetStock,
  getBusinessProductContext,
} from './ai.tools.js';
import { NotFoundError, BadRequestError } from '@/errors/http.error.js';
import { GoogleGenAI } from '@google/genai';
import crypto from 'crypto';

let genAIClient: GoogleGenAI | null = null;
if (env.GEMINI_API_KEY && env.GEMINI_API_KEY.trim() !== '') {
  try {
    genAIClient = new GoogleGenAI({ apiKey: env.GEMINI_API_KEY });
  } catch (err: any) {
    logger.warn(`[AI SERVICE] Failed to initialize GoogleGenAI: ${err.message}`);
  }
}

const SYSTEM_INSTRUCTION = `
Anda adalah AIsistenku, asisten bisnis cerdas untuk UMKM Coffee Shop dan F&B kecil ("Tiga Angkatan").
Bahasa komunikasi: Bahasa Indonesia yang ramah, sopan, ringkas, dan solutif.

PRINSIP UTAMA:
1. AKURASI DATA: Jawab pertanyaan omzet, transaksi, dan stok berdasarkan data nyata. Jika ada data yang disediakan dari sistem, gunakan data tersebut. Jangan pernah mengarang angka omzet atau stok!
2. PROPOSAL AKSI TULIS: Jika pengguna meminta menambah stok atau mencatat pengeluaran, konfirmasikan usulan tersebut ("Mau saya tambahkan stok...?") dan jangan klaim sudah tersimpan sebelum pengguna menekan konfirmasi.
3. KONTEN PROMOSI: Buatkan variasi caption promosi yang kreatif, menggugah selera, dan relevan dengan menu coffee shop, lengkap dengan rekomendasi hashtag yang pas.
`;

export const handleChat = async (
  businessId: string,
  userId: string | null,
  messageText: string
) => {
  // 1. Simpan pesan pengguna ke database
  const userMessage = await prisma.aiMessage.create({
    data: {
      businessId,
      userId,
      sender: MessageSender.USER,
      text: messageText,
      type: 'text',
    },
  });

  const textLower = messageText.toLowerCase();

  // 2. Cek apakah ada intent aksi tulis langsung (misal: "tambah stok gula 5kg" atau "catat pengeluaran beli susu 50rb")
  // Tool Write: add_stock
  const addStockMatch = textLower.match(/(?:tambah|masukkan|isi)\s+stok\s+([a-zA-Z\s]+?)\s+(\d+(?:[.,]\d+)?)\s*([a-zA-Z]+)?/i);
  if (addStockMatch) {
    const item = addStockMatch[1].trim();
    const qty = parseFloat(addStockMatch[2].replace(',', '.'));
    const unit = (addStockMatch[3] || 'unit').trim();

    const proposal = await executeAddStockProposal(userMessage.id, {
      item,
      quantity: qty,
      unit,
    });

    const aiMessage = await prisma.aiMessage.create({
      data: {
        businessId,
        userId,
        sender: MessageSender.AI,
        text: proposal.message,
        type: 'action_confirmation',
        extraData: proposal.action as any,
      },
    });

    return {
      userMessage,
      aiResponse: aiMessage,
      action: proposal.action,
      type: 'action_confirmation',
      message: proposal.message,
    };
  }

  // Tool Write: add_expense
  const addExpenseMatch = textLower.match(/(?:catat|tambah|masukkan)?\s*(?:pengeluaran|beli|biaya)\s+([a-zA-Z\s]+?)\s*(?:sebesar|seharga|rp)?\s*(\d+[\d.,]*)\s*(?:rb|ribu|k)?/i);
  if (addExpenseMatch && !textLower.includes('berapa') && !textLower.includes('lihat') && !textLower.includes('cek')) {
    const note = addExpenseMatch[1].trim();
    let rawAmount = addExpenseMatch[2].replace(/[.,]/g, '');
    let amount = parseFloat(rawAmount);
    if (textLower.includes('rb') || textLower.includes('ribu') || textLower.includes('k')) {
      if (amount < 1000) amount *= 1000;
    }

    if (amount > 0) {
      const proposal = await executeAddExpenseProposal(userMessage.id, {
        category: 'operational',
        amount,
        note,
      });

      const aiMessage = await prisma.aiMessage.create({
        data: {
          businessId,
          userId,
          sender: MessageSender.AI,
          text: proposal.message,
          type: 'action_confirmation',
          extraData: proposal.action as any,
        },
      });

      return {
        userMessage,
        aiResponse: aiMessage,
        action: proposal.action,
        type: 'action_confirmation',
        message: proposal.message,
      };
    }
  }

  // 3. Cek apakah ada intent baca data langsung
  let dataContext = '';
  if (textLower.includes('omzet') || textLower.includes('penjualan') || textLower.includes('laku') || textLower.includes('sales')) {
    const range = textLower.includes('hari ini') || textLower.includes('today') ? 'today' : textLower.includes('bulan') ? '30d' : '7d';
    const salesData = await executeGetSales(businessId, { range });
    dataContext = `[DATA PENJUALAN]: Rentang: ${salesData.range}, Total Omzet: ${salesData.totalSalesFormatted}, Jumlah Transaksi: ${salesData.totalOrders}.`;
  } else if (textLower.includes('stok') || textLower.includes('bahan')) {
    const stockData = await executeGetStock(businessId, {});
    dataContext = `[DATA STOK]: Ditemukan ${stockData.found} item. Ringkasan: ${stockData.stocks
      .map((s) => `${s.name} (${s.currentStock} ${s.unit} - Status: ${s.status})`)
      .join(', ')}.`;
  } else if (textLower.includes('pengeluaran') || textLower.includes('biaya') || textLower.includes('expense')) {
    const range = textLower.includes('hari ini') ? 'today' : textLower.includes('bulan') ? '30d' : '7d';
    const expenseData = await executeGetExpense(businessId, { range });
    dataContext = `[DATA PENGELUARAN]: Rentang: ${expenseData.range}, Total: ${expenseData.totalExpenseFormatted}.`;
  }

  // 4. Hubungi Gemini API jika SDK tersedia dan KEY disetel
  let replyText = '';

  if (genAIClient) {
    try {
      const menuContext = await getBusinessProductContext(businessId);
      const promptWithContext = `
${SYSTEM_INSTRUCTION}

Konteks Menu Toko Saat Ini: ${menuContext || 'Kopi Susu, Americano, Latte, Croissant'}
${dataContext ? `Konteks Data Nyata Bisnis: ${dataContext}` : ''}

Pertanyaan Pengguna: "${messageText}"
Berikan jawaban ringkas, akurat sesuai konteks, dan bermanfaat bagi pengelola toko.
`;

      const response = await genAIClient.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: promptWithContext,
      });

      replyText = response.text?.trim() || '';
    } catch (apiErr: any) {
      logger.warn(`[AI SERVICE] Gemini API call error: ${apiErr.message}`);
    }
  }

  // 5. Fallback generator jika Gemini belum disetel atau offline
  if (!replyText) {
    if (dataContext.includes('[DATA PENJUALAN]')) {
      replyText = `Berdasarkan catatan sistem kami, ${dataContext.replace('[DATA PENJUALAN]: ', '')}. Ada analisis transaksi lain yang ingin Anda ketahui?`;
    } else if (dataContext.includes('[DATA STOK]')) {
      replyText = `Berikut ringkasan ketersediaan bahan baku kedai saat ini: ${dataContext.replace('[DATA STOK]: ', '')}. Ingin saya bantu buatkan usulan restock?`;
    } else if (dataContext.includes('[DATA PENGELUARAN]')) {
      replyText = `Catatan pengeluaran operasional toko: ${dataContext.replace('[DATA PENGELUARAN]: ', '')}.`;
    } else if (textLower.includes('promo') || textLower.includes('caption') || textLower.includes('ide')) {
      replyText = `Tentu! Berikut ide caption promosi:\n\n"Awali harimu dengan segelas kopi berkualitas di Tiga Angkatan ☕ Rasa pas, semangat tuntas! Nikmati diskon spesial untuk dine-in & takeaway hari ini."\n\nHashtag: #TigaAngkatan #KopiSusuNikmat #CoffeeShopMakassar #PromoKopi`;
    } else {
      replyText = `Halo! Saya AIsistenku siap membantu operasional kedai Anda. Anda bisa menanyakan omzet, mengecek stok bahan baku, mencatat pengeluaran, atau meminta ide konten promosi. Ada yang bisa saya bantu?`;
    }
  }

  // Simpan balasan AI ke database
  const aiMessage = await prisma.aiMessage.create({
    data: {
      businessId,
      userId,
      sender: MessageSender.AI,
      text: replyText,
      type: 'text',
    },
  });

  return {
    userMessage,
    aiResponse: aiMessage,
    type: 'text',
    message: replyText,
  };
};

export const confirmAction = async (
  actionId: string,
  businessId: string,
  userId: string | null
) => {
  const action = await prisma.aiAction.findUnique({
    where: { id: actionId },
    include: { message: true },
  });

  if (!action) {
    throw new NotFoundError('Aksi AI', 'ACTION_NOT_FOUND');
  }

  if (action.status !== ActionStatus.PENDING) {
    throw new BadRequestError(
      `Aksi ini tidak dapat dikonfirmasi karena statusnya sudah ${action.status}.`,
      'ACTION_ALREADY_PROCESSED'
    );
  }

  const payload = action.payload as any;

  if (action.intent === 'add_stock') {
    const itemName = String(payload.item || 'Bahan').trim();
    const quantity = Number(payload.quantity || 0);
    const unit = String(payload.unit || 'kg').trim();

    // Cari stok yang cocok atau buat baru
    let stock = await prisma.stockItem.findFirst({
      where: {
        businessId,
        name: { equals: itemName, mode: 'insensitive' },
      },
    });

    if (stock) {
      stock = await prisma.stockItem.update({
        where: { id: stock.id },
        data: {
          currentStock: { increment: quantity },
        },
      });
    } else {
      stock = await prisma.stockItem.create({
        data: {
          businessId,
          name: itemName,
          currentStock: quantity,
          minStock: 5,
          unit,
        },
      });
    }

    // Catat StockLog
    await prisma.stockLog.create({
      data: {
        stockId: stock.id,
        stockName: stock.name,
        type: StockLogType.IN,
        quantity,
        unit: stock.unit,
        source: StockLogSource.AI_AGENT,
        userId,
        operatorName: 'AI Agent (Confirmed)',
        note: `Penambahan stok diajukan AI dan dikonfirmasi user`,
      },
    });
  } else if (action.intent === 'add_expense') {
    const category = String(payload.category || 'operational');
    const amount = Number(payload.amount || 0);
    const note = payload.note ? String(payload.note) : 'Pencatatan pengeluaran via AI Agent';

    await prisma.financeTransaction.create({
      data: {
        businessId,
        userId,
        title: `Pengeluaran: ${note}`,
        type: FinanceType.EXPENSE,
        category,
        amount,
        source: FinanceSource.AI_AGENT,
        notes: note,
      },
    });
  }

  const updatedAction = await prisma.aiAction.update({
    where: { id: actionId },
    data: { status: ActionStatus.CONFIRMED },
  });

  return {
    success: true,
    action: updatedAction,
    message: 'Aksi berhasil dikonfirmasi dan diterapkan ke sistem.',
  };
};

export const cancelAction = async (actionId: string, _businessId: string) => {
  const action = await prisma.aiAction.findUnique({
    where: { id: actionId },
  });

  if (!action) {
    throw new NotFoundError('Aksi AI', 'ACTION_NOT_FOUND');
  }

  if (action.status !== ActionStatus.PENDING) {
    throw new BadRequestError(
      `Aksi ini tidak dapat dibatalkan karena statusnya sudah ${action.status}.`,
      'ACTION_ALREADY_PROCESSED'
    );
  }

  const updatedAction = await prisma.aiAction.update({
    where: { id: actionId },
    data: { status: ActionStatus.CANCELLED },
  });

  return {
    success: true,
    action: updatedAction,
    message: 'Aksi telah dibatalkan. Tidak ada perubahan data.',
  };
};

export const generateContentIdeas = async (
  businessId: string,
  params: { theme: string; tone?: string; platform?: string }
) => {
  const draftId = `draft-${crypto.randomUUID()}`;
  const menuContext = await getBusinessProductContext(businessId);
  const platform = params.platform || 'instagram';
  const tone = params.tone || 'santai dan ramah';

  let captions: string[] = [];
  let hashtags: string[] = ['#TigaAngkatan', '#CoffeeShop', '#PromoKopi', '#UMKMCoffee'];

  if (genAIClient) {
    try {
      const prompt = `
Buatkan 3 variasi caption promosi media sosial untuk kedai kopi "Tiga Angkatan".
Tema Promosi: "${params.theme}"
Platform: ${platform}
Nada Bahasa: ${tone}
Daftar Menu Tersedia: ${menuContext || 'Kopi Susu Gula Aren, Americano, Latte, Matcha'}

Format keluaran HARUS valid JSON:
{
  "captions": [
    "variasi 1...",
    "variasi 2...",
    "variasi 3..."
  ],
  "hashtags": ["#tag1", "#tag2", "#tag3", "#tag4", "#tag5"]
}
`;

      const res = await genAIClient.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: prompt,
      });

      const text = res.text?.trim() || '';
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        if (Array.isArray(parsed.captions) && parsed.captions.length > 0) {
          captions = parsed.captions;
        }
        if (Array.isArray(parsed.hashtags) && parsed.hashtags.length > 0) {
          hashtags = parsed.hashtags;
        }
      }
    } catch (err: any) {
      logger.warn(`[AI SERVICE] Error generating content with Gemini: ${err.message}`);
    }
  }

  if (captions.length === 0) {
    captions = [
      `Senin makin semangat kalau ada Kopi Susu favorit dari Tiga Angkatan ☕✨ Segarkan harimu dengan racikan kopi istimewa. Yuk mampir atau pesan takeaway sekarang!`,
      `Ngopi santai bareng teman makin seru dengan promo spesial "${params.theme}". Cita rasa otentik yang bikin nagih setiap tegukan. Jangan sampai kehabisan ya!`,
      `Butuh booster konsentrasi hari ini? Menu andalan kami siap menemani aktivitasmu. Dapatkan penawaran terbaik hanya di kedai Tiga Angkatan!`,
    ];
  }

  return {
    draftId,
    captions,
    hashtags,
  };
};

export const listMessages = async (businessId: string) => {
  return await prisma.aiMessage.findMany({
    where: { businessId },
    orderBy: { timestamp: 'asc' },
    include: {
      actions: true,
    },
    take: 100,
  });
};

export const clearMessages = async (businessId: string) => {
  return await prisma.aiMessage.deleteMany({
    where: { businessId },
  });
};
