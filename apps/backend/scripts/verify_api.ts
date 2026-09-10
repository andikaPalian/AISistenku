import 'dotenv/config';
import { createApp } from '../src/app.js';
import { prisma } from '../src/config/database.config.js';
import http from 'http';

const TEST_PORT = 3099;
const BASE_URL = `http://localhost:${TEST_PORT}/api/v1`;

let server: http.Server;

function assert(condition: any, message: string) {
  if (!condition) {
    console.error(`❌ GAGAL: ${message}`);
    throw new Error(`Assertion failed: ${message}`);
  }
  console.log(`✅ ${message}`);
}

async function runTests() {
  const app = createApp();

  await new Promise<void>((resolve) => {
    server = app.listen(TEST_PORT, () => {
      console.log(`🚀 Test Server aktif di ${BASE_URL}`);
      resolve();
    });
  });

  try {
    console.log('\n--- 1. TESTING AUTH ---');
    // Login
    const loginRes = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'owner@tigaangkatan.id',
        password: 'password123',
      }),
    });
    const loginJson = await loginRes.json();
    assert(loginRes.status === 200, 'POST /auth/login berhasil (status 200)');
    assert(loginJson.data.accessToken, 'Access token diterima');
    assert(loginJson.data.user.email === 'owner@tigaangkatan.id', 'User email cocok');

    const token = loginJson.data.accessToken;
    const refreshToken = loginJson.data.refreshToken;

    // GET /auth/me
    const meRes = await fetch(`${BASE_URL}/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const meJson = await meRes.json();
    assert(meRes.status === 200, 'GET /auth/me berhasil');
    assert(meJson.data.email === 'owner@tigaangkatan.id', 'Data profil me sesuai');

    // POST /auth/refresh
    const refreshRes = await fetch(`${BASE_URL}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });
    const refreshJson = await refreshRes.json();
    assert(refreshRes.status === 200, 'POST /auth/refresh berhasil');
    assert(refreshJson.data.accessToken, 'Token baru berhasil diterbitkan');
    const activeToken = refreshJson.data.accessToken;

    console.log('\n--- 2. TESTING BUSINESS CONTEXT ---');
    // GET /businesses
    const bizRes = await fetch(`${BASE_URL}/businesses`, {
      headers: { Authorization: `Bearer ${activeToken}` },
    });
    const bizJson = await bizRes.json();
    assert(bizRes.status === 200, 'GET /businesses berhasil');
    assert(bizJson.data.length > 0, 'Ditemukan setidaknya 1 bisnis');
    const activeBusiness = bizJson.data[0];
    const businessId = activeBusiness.id;
    console.log(`📌 Bisnis aktif: ${activeBusiness.name} (${businessId})`);

    const domainHeaders = {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${activeToken}`,
      'X-Business-Id': businessId,
    };

    console.log('\n--- 3. TESTING STOCK ---');
    // GET /stock
    const stockRes = await fetch(`${BASE_URL}/stock`, { headers: domainHeaders });
    const stockJson = await stockRes.json();
    assert(stockRes.status === 200, 'GET /stock berhasil');
    assert(Array.isArray(stockJson.data), 'Data stok berupa array');
    const existingStock = stockJson.data[0];

    // POST /stock
    const newStockRes = await fetch(`${BASE_URL}/stock`, {
      method: 'POST',
      headers: domainHeaders,
      body: JSON.stringify({
        name: 'Gula Cair Vanila',
        category: 'Sirup & Perisa',
        currentStock: 10,
        minStock: 3,
        unit: 'btl',
        costPerUnit: 45000,
        supplier: 'Supplier Test',
      }),
    });
    const newStockJson = await newStockRes.json();
    assert(newStockRes.status === 201, 'POST /stock berhasil membuat item stok baru');
    const createdStockId = newStockJson.data.id;

    // POST /stock/:id/adjust
    const adjustRes = await fetch(`${BASE_URL}/stock/${createdStockId}/adjust`, {
      method: 'POST',
      headers: domainHeaders,
      body: JSON.stringify({
        type: 'IN',
        quantity: 5,
        note: 'Penyesuaian stok manual uji coba',
      }),
    });
    const adjustJson = await adjustRes.json();
    assert(adjustRes.status === 200, 'POST /stock/:id/adjust berhasil');
    assert(Number(adjustJson.data.stock.currentStock) === 15, 'Stok bertambah menjadi 15');

    // GET /stock/:id/logs
    const logsRes = await fetch(`${BASE_URL}/stock/${createdStockId}/logs`, {
      headers: domainHeaders,
    });
    const logsJson = await logsRes.json();
    assert(logsRes.status === 200, 'GET /stock/:id/logs berhasil');
    assert(logsJson.data.length > 0, 'Audit trail log mutasi tercatat');

    console.log('\n--- 4. TESTING PRODUCTS & RECIPES ---');
    // GET /products
    const prodRes = await fetch(`${BASE_URL}/products`, { headers: domainHeaders });
    const prodJson = await prodRes.json();
    assert(prodRes.status === 200, 'GET /products berhasil');
    assert(prodJson.data.length > 0, 'Daftar produk tidak kosong');

    // POST /products
    const newProdRes = await fetch(`${BASE_URL}/products`, {
      method: 'POST',
      headers: domainHeaders,
      body: JSON.stringify({
        name: 'Espresso Vanilla Float',
        price: 28000,
        category: 'COFFEE',
        defaultVariant: 'Regular',
      }),
    });
    const newProdJson = await newProdRes.json();
    assert(newProdRes.status === 201, 'POST /products berhasil');
    const createdProductId = newProdJson.data.id;

    // PUT /products/:id/recipe (Set BOM)
    const setRecipeRes = await fetch(`${BASE_URL}/products/${createdProductId}/recipe`, {
      method: 'PUT',
      headers: domainHeaders,
      body: JSON.stringify({
        items: [{ stockId: createdStockId, quantityRequired: 0.5 }],
      }),
    });
    assert(setRecipeRes.status === 200, 'PUT /products/:id/recipe berhasil mengaitkan resep BOM');

    console.log('\n--- 5. TESTING POS ORDERS (TRANSAKSI DEDUKSI STOK OTOMATIS) ---');
    const stockBeforeOrder = Number(adjustJson.data.stock.currentStock); // 15
    const orderRes = await fetch(`${BASE_URL}/orders`, {
      method: 'POST',
      headers: domainHeaders,
      body: JSON.stringify({
        orderType: 'DineIn',
        tableNumber: '08',
        customerName: 'Pelanggan Uji Coba',
        paymentMethod: 'Cash',
        cashGiven: 50000,
        items: [
          {
            productId: createdProductId,
            quantity: 2, // butuh 2 * 0.5 = 1 btl stok
          },
        ],
      }),
    });
    const orderJson = await orderRes.json();
    assert(orderRes.status === 201, 'POST /orders berhasil mencatat transaksi POS');
    assert(orderJson.data.orderCode, `Order code diterbitkan: ${orderJson.data.orderCode}`);
    assert(Number(orderJson.data.totalAmount) === 56000, 'Total transaksi tepat (28.000 x 2 = 56.000)');

    // Verifikasi stok bahan terpotong otomatis via resep
    const checkStockRes = await fetch(`${BASE_URL}/stock/${createdStockId}`, {
      headers: domainHeaders,
    });
    const checkStockJson = await checkStockRes.json();
    const stockAfterOrder = Number(checkStockJson.data.currentStock);
    assert(
      stockAfterOrder === stockBeforeOrder - 1,
      `Deduksi stok otomatis sukses (dari ${stockBeforeOrder} menjadi ${stockAfterOrder})`
    );

    console.log('\n--- 6. TESTING FINANCE ---');
    // GET /finance
    const finRes = await fetch(`${BASE_URL}/finance`, { headers: domainHeaders });
    const finJson = await finRes.json();
    assert(finRes.status === 200, 'GET /finance berhasil');
    assert(finJson.data.length > 0, 'Buku kas mencatat transaksi');

    // POST /finance (Manual Expense)
    const expenseRes = await fetch(`${BASE_URL}/finance`, {
      method: 'POST',
      headers: domainHeaders,
      body: JSON.stringify({
        title: 'Beli Sabun Cuci Piring',
        type: 'EXPENSE',
        category: 'operational',
        amount: 25000,
        notes: 'Pencatatan manual kasir',
      }),
    });
    assert(expenseRes.status === 201, 'POST /finance berhasil mencatat pengeluaran');

    console.log('\n--- 7. TESTING DASHBOARD / ANALYTICS ---');
    const dashRes = await fetch(`${BASE_URL}/dashboard/summary`, { headers: domainHeaders });
    const dashJson = await dashRes.json();
    assert(dashRes.status === 200, 'GET /dashboard/summary berhasil');
    assert(dashJson.data.todayRevenue >= 56000, 'Omzet hari ini mencakup transaksi POS');

    const trendRes = await fetch(`${BASE_URL}/dashboard/sales-trend?range=7d`, {
      headers: domainHeaders,
    });
    const trendJson = await trendRes.json();
    assert(trendRes.status === 200, 'GET /dashboard/sales-trend berhasil');
    assert(trendJson.data.length === 7, 'Tren penjualan mengembalikan 7 hari data');

    console.log('\n--- 8. TESTING AI AGENT ---');
    // Chat query baca omzet
    const chatSalesRes = await fetch(`${BASE_URL}/ai/chat`, {
      method: 'POST',
      headers: domainHeaders,
      body: JSON.stringify({ message: 'Berapa omzet hari ini?' }),
    });
    const chatSalesJson = await chatSalesRes.json();
    assert(chatSalesRes.status === 200, 'POST /ai/chat (read omzet) berhasil direspons');
    console.log(`🤖 Jawaban AI: "${chatSalesJson.data.message}"`);

    // Chat query usulan aksi tulis tambah stok
    const chatActionRes = await fetch(`${BASE_URL}/ai/chat`, {
      method: 'POST',
      headers: domainHeaders,
      body: JSON.stringify({ message: 'tambah stok Gula Cair Vanila 4 btl' }),
    });
    const chatActionJson = await chatActionRes.json();
    assert(chatActionRes.status === 200, 'POST /ai/chat (write proposal) berhasil');
    assert(chatActionJson.data.action.status === 'PENDING', 'Usulan aksi berstatus PENDING (belum dieksekusi)');
    const actionId = chatActionJson.data.action.id;

    // Konfirmasi aksi AI
    const confirmRes = await fetch(`${BASE_URL}/ai/actions/${actionId}/confirm`, {
      method: 'POST',
      headers: domainHeaders,
    });
    const confirmJson = await confirmRes.json();
    assert(confirmRes.status === 200, 'POST /ai/actions/:id/confirm berhasil');
    assert(confirmJson.data.status === 'CONFIRMED', 'Status aksi berubah menjadi CONFIRMED');

    // Cek stok setelah konfirmasi AI
    const stockAfterAiRes = await fetch(`${BASE_URL}/stock/${createdStockId}`, {
      headers: domainHeaders,
    });
    const stockAfterAiJson = await stockAfterAiRes.json();
    assert(
      Number(stockAfterAiJson.data.currentStock) === stockAfterOrder + 4,
      `Stok bertambah 4 setelah konfirmasi aksi AI (kini: ${stockAfterAiJson.data.currentStock})`
    );

    // AI Content Ideas
    const ideasRes = await fetch(`${BASE_URL}/ai/content-ideas`, {
      method: 'POST',
      headers: domainHeaders,
      body: JSON.stringify({ theme: 'Promo Jumat Berkah Diskon 20%', platform: 'instagram' }),
    });
    const ideasJson = await ideasRes.json();
    assert(ideasRes.status === 200, 'POST /ai/content-ideas berhasil');
    assert(ideasJson.data.captions.length > 0, 'AI menghasilkan variasi caption promosi');

    console.log('\n--- 9. TESTING MARKETING CONTENT LIBRARY ---');
    const saveContentRes = await fetch(`${BASE_URL}/marketing-content`, {
      method: 'POST',
      headers: domainHeaders,
      body: JSON.stringify({
        type: 'CAPTION',
        platform: 'instagram',
        content: ideasJson.data.captions[0],
        prompt: 'Promo Jumat Berkah Diskon 20%',
      }),
    });
    const saveContentJson = await saveContentRes.json();
    assert(saveContentRes.status === 201, 'POST /marketing-content berhasil menyimpan caption terpilih');

    const listContentRes = await fetch(`${BASE_URL}/marketing-content`, {
      headers: domainHeaders,
    });
    const listContentJson = await listContentRes.json();
    assert(listContentRes.status === 200, 'GET /marketing-content berhasil');
    assert(listContentJson.data.length > 0, 'Pustaka konten promosi tersimpan');

    console.log('\n🎉 SEMUA FITUR BACKEND TELAH DIVERIFIKASI & BERFUNGSI 100% SESUAI DOKUMENTASI!');
  } finally {
    server.close();
    await prisma.$disconnect();
  }
}

runTests().catch((err) => {
  console.error('💥 Verifikasi API gagal:', err);
  if (server) server.close();
  process.exit(1);
});
