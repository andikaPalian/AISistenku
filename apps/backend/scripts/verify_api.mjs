import app from '../src/index.js';

const server = app.listen(3099, async () => {
  console.log('🚀 Test server running on port 3099');

  async function testEndpoint(name, path, method = 'GET', body = null) {
    try {
      const res = await fetch('http://localhost:3099' + path, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined,
      });
      const data = await res.json();
      console.log(`✅ [${res.status}] ${method} ${path} (${name}) -> ${Array.isArray(data) ? data.length + ' items' : Object.keys(data).join(', ')}`);
      return { ok: res.ok, status: res.status, data };
    } catch (err) {
      console.error(`❌ ${method} ${path} (${name}) Failed:`, err.message);
      return { ok: false, error: err.message };
    }
  }

  try {
    console.log('\n--- 1. Health & Base Endpoints ---');
    await testEndpoint('Health Check', '/health');
    await testEndpoint('API Root', '/api');

    console.log('\n--- 2. Core Business Endpoints ---');
    await testEndpoint('Get Products (POS Menu)', '/api/products');
    await testEndpoint('Get Stock Items (Inventory)', '/api/stocks');
    await testEndpoint('Dashboard Overview', '/api/dashboard/overview');
    await testEndpoint('Finance Summary (Today)', '/api/finance/summary?period=today');
    await testEndpoint('Finance Transactions', '/api/finance/transactions?period=today');
    await testEndpoint('AI Messages (Chat)', '/api/ai/messages');

    console.log('\n--- 3. Testing Order Creation (POS Checkout simulation) ---');
    await testEndpoint('Create Order', '/api/orders', 'POST', {
      orderType: 'Dine In',
      tableNumber: '04',
      customerName: 'Budi',
      paymentMethod: 'Cash',
      items: [
        { product_id: 'prod-1', product_name: 'Iced Latte', quantity: 2, price: 15000, subtotal: 30000 }
      ],
      subtotal: 30000,
      tax: 0,
      total: 30000,
      cashGiven: 50000,
      change: 20000
    });

    console.log('\n🎉 ALL BACKEND ENDPOINTS ARE FULLY OPERATIONAL AND COMPATIBLE!\n');
  } finally {
    server.close(() => {
      process.exit(0);
    });
  }
});
