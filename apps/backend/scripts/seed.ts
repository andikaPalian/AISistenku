import { prisma } from '../src/config/database.config.js';
import bcrypt from 'bcrypt';
import {
  ActionStatus,
  BusinessRole,
  FinanceSource,
  FinanceType,
  MarketingContentStatus,
  MarketingContentType,
  MessageSender,
  OrderStatus,
  OrderType,
  PaymentMethod,
  ProductCategory,
  StockLogSource,
  StockLogType,
} from '@prisma/client';

async function main() {
  console.log('🌱 Memulai proses seeding database AIsistenku...');

  // 1. Bersihkan database lama (urutan cascade / dependency)
  await prisma.marketingContent.deleteMany();
  await prisma.aiAction.deleteMany();
  await prisma.aiMessage.deleteMany();
  await prisma.financeTransaction.deleteMany();
  await prisma.stockLog.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.order.deleteMany();
  await prisma.productRecipe.deleteMany();
  await prisma.product.deleteMany();
  await prisma.stockItem.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.businessMember.deleteMany();
  await prisma.business.deleteMany();
  await prisma.user.deleteMany();

  console.log('🧹 Database dibersihkan.');

  // 2. Buat Pengguna (Owner & Kasir)
  const hashedPassword = await bcrypt.hash('password123', 10);

  const ownerUser = await prisma.user.create({
    data: {
      name: 'Andika Palian',
      email: 'owner@tigaangkatan.id',
      password: hashedPassword,
    },
  });

  const cashierUser = await prisma.user.create({
    data: {
      name: 'Siti Kasir',
      email: 'kasir@tigaangkatan.id',
      password: hashedPassword,
    },
  });

  console.log(`👤 Pengguna dibuat: Owner (${ownerUser.email}), Kasir (${cashierUser.email})`);

  // 3. Buat Bisnis (Tiga Angkatan Coffee)
  const business = await prisma.business.create({
    data: {
      name: 'Kedai Kopi Tiga Angkatan',
      address: 'Jl. Sultan Alauddin No. 259, Makassar',
      phone: '081234567890',
    },
  });

  console.log(`☕ Bisnis dibuat: ${business.name} (ID: ${business.id})`);

  // 4. Hubungkan Pengguna ke Bisnis
  await prisma.businessMember.createMany({
    data: [
      {
        businessId: business.id,
        userId: ownerUser.id,
        role: BusinessRole.OWNER,
      },
      {
        businessId: business.id,
        userId: cashierUser.id,
        role: BusinessRole.CASHIER,
      },
    ],
  });

  console.log('👥 Keanggotaan bisnis dikonfigurasi (Owner & Cashier).');

  // 5. Buat Bahan Baku (Stock Items)
  const stockData = [
    {
      name: 'Biji Kopi Arabika Gayo',
      category: 'Biji Kopi',
      currentStock: 12.5,
      minStock: 5.0,
      unit: 'kg',
      costPerUnit: 120000,
      supplier: 'Aceh Gayo Specialty Roastery',
      note: 'Roasting medium-dark specialty',
    },
    {
      name: 'Susu Fresh Milk Greenfield',
      category: 'Susu & Dairy',
      currentStock: 24.0,
      minStock: 10.0,
      unit: 'L',
      costPerUnit: 22000,
      supplier: 'Greenfield Distributor',
      note: 'Susu segar pasteurisasi',
    },
    {
      name: 'Gula Aren Organik Cair',
      category: 'Gula & Pemanis',
      currentStock: 8.0,
      minStock: 4.0,
      unit: 'L',
      costPerUnit: 35000,
      supplier: 'Aren Nusantara',
      note: 'Gula aren murni asli Sulawesi',
    },
    {
      name: 'Bubuk Matcha Premium Uji',
      category: 'Bubuk & Perisa',
      currentStock: 3.5,
      minStock: 2.0,
      unit: 'kg',
      costPerUnit: 180000,
      supplier: 'Kyoto Imports Indo',
      note: 'Pure ceremonial matcha',
    },
    {
      name: 'Bubuk Cokelat Belgia',
      category: 'Bubuk & Perisa',
      currentStock: 4.0,
      minStock: 2.0,
      unit: 'kg',
      costPerUnit: 140000,
      supplier: 'Choco Delite Makassar',
      note: 'Dark cocoa 70%',
    },
    {
      name: 'Sirup Karamel Monin',
      category: 'Sirup & Perisa',
      currentStock: 1.5,
      minStock: 2.0, // Mendekati/di bawah minStock -> Kritis
      unit: 'btl',
      costPerUnit: 110000,
      supplier: 'Diva Flavor Indonesia',
      note: 'Botol 750ml',
    },
    {
      name: 'Cup Plastic 16oz Dingin',
      category: 'Cup & Kemasan',
      currentStock: 45.0, // Di bawah minStock (kritis)
      minStock: 100.0,
      unit: 'pcs',
      costPerUnit: 850,
      supplier: 'Mitra Pack Tangerang',
      note: 'Cup sablon logo Tiga Angkatan',
    },
    {
      name: 'Lid Cup Datar 16oz',
      category: 'Cup & Kemasan',
      currentStock: 80.0,
      minStock: 100.0,
      unit: 'pcs',
      costPerUnit: 250,
      supplier: 'Mitra Pack Tangerang',
    },
    {
      name: 'Croissant Mentah Beku',
      category: 'Pastry & Makanan',
      currentStock: 30.0,
      minStock: 15.0,
      unit: 'pcs',
      costPerUnit: 9000,
      supplier: 'Makassar Bakery Supply',
    },
  ];

  const createdStocks = await Promise.all(
    stockData.map((s) =>
      prisma.stockItem.create({
        data: {
          businessId: business.id,
          ...s,
        },
      })
    )
  );

  const stockMap = new Map(createdStocks.map((s) => [s.name, s]));
  console.log(`📦 ${createdStocks.length} item bahan baku stok dibuat.`);

  // 6. Buat Menu Produk (Product)
  const productData = [
    {
      name: 'Iced Kopi Susu Tiga Angkatan',
      category: ProductCategory.COFFEE,
      price: 22000,
      defaultVariant: 'Regular',
      imageUrl: 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38',
      recipes: [
        { stockName: 'Biji Kopi Arabika Gayo', qty: 0.018 },
        { stockName: 'Susu Fresh Milk Greenfield', qty: 0.12 },
        { stockName: 'Gula Aren Organik Cair', qty: 0.03 },
        { stockName: 'Cup Plastic 16oz Dingin', qty: 1 },
        { stockName: 'Lid Cup Datar 16oz', qty: 1 },
      ],
    },
    {
      name: 'Americano Dingin',
      category: ProductCategory.COFFEE,
      price: 18000,
      defaultVariant: 'Regular',
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd',
      recipes: [
        { stockName: 'Biji Kopi Arabika Gayo', qty: 0.018 },
        { stockName: 'Cup Plastic 16oz Dingin', qty: 1 },
        { stockName: 'Lid Cup Datar 16oz', qty: 1 },
      ],
    },
    {
      name: 'Caramel Macchiato',
      category: ProductCategory.COFFEE,
      price: 26000,
      defaultVariant: 'Regular',
      imageUrl: 'https://images.unsplash.com/photo-1485808191679-5f86510681a2',
      recipes: [
        { stockName: 'Biji Kopi Arabika Gayo', qty: 0.018 },
        { stockName: 'Susu Fresh Milk Greenfield', qty: 0.15 },
        { stockName: 'Sirup Karamel Monin', qty: 0.03 },
        { stockName: 'Cup Plastic 16oz Dingin', qty: 1 },
      ],
    },
    {
      name: 'Matcha Latte Dingin',
      category: ProductCategory.NON_COFFEE,
      price: 25000,
      defaultVariant: 'Regular',
      imageUrl: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a',
      recipes: [
        { stockName: 'Bubuk Matcha Premium Uji', qty: 0.02 },
        { stockName: 'Susu Fresh Milk Greenfield', qty: 0.15 },
        { stockName: 'Cup Plastic 16oz Dingin', qty: 1 },
      ],
    },
    {
      name: 'Belgian Chocolate Signature',
      category: ProductCategory.NON_COFFEE,
      price: 24000,
      defaultVariant: 'Regular',
      imageUrl: 'https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed',
      recipes: [
        { stockName: 'Bubuk Cokelat Belgia', qty: 0.025 },
        { stockName: 'Susu Fresh Milk Greenfield', qty: 0.15 },
        { stockName: 'Cup Plastic 16oz Dingin', qty: 1 },
      ],
    },
    {
      name: 'Butter Croissant Hangat',
      category: ProductCategory.FOOD,
      price: 20000,
      defaultVariant: 'Regular',
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a',
      recipes: [
        { stockName: 'Croissant Mentah Beku', qty: 1 },
      ],
    },
  ];

  for (const p of productData) {
    const product = await prisma.product.create({
      data: {
        businessId: business.id,
        name: p.name,
        category: p.category,
        price: p.price,
        defaultVariant: p.defaultVariant,
        imageUrl: p.imageUrl,
        isActive: true,
      },
    });

    // Buat resep (BOM)
    for (const r of p.recipes) {
      const stock = stockMap.get(r.stockName);
      if (stock) {
        await prisma.productRecipe.create({
          data: {
            productId: product.id,
            stockId: stock.id,
            quantityRequired: r.qty,
          },
        });
      }
    }
  }

  console.log(`☕ ${productData.length} menu produk dan resep BOM selesai dikonfigurasi.`);

  // 7. Catat Transaksi POS Historis & Otomatisasi Keuangan
  const products = await prisma.product.findMany({ where: { businessId: business.id } });

  const order1 = await prisma.order.create({
    data: {
      businessId: business.id,
      orderCode: 'ORD-20260909-001',
      userId: cashierUser.id,
      orderType: OrderType.DineIn,
      tableNumber: '03',
      customerName: 'Kak Reza',
      subtotal: 44000,
      tax: 0,
      totalAmount: 44000,
      paymentMethod: PaymentMethod.QRIS_EWallet,
      status: OrderStatus.PAID,
      items: {
        create: [
          {
            productId: products[0].id,
            productName: products[0].name,
            quantity: 2,
            priceAtSale: products[0].price,
            subtotal: 44000,
          },
        ],
      },
    },
  });

  await prisma.financeTransaction.create({
    data: {
      businessId: business.id,
      userId: cashierUser.id,
      orderId: order1.id,
      title: `Penjualan Kasir ORD-20260909-001`,
      type: FinanceType.INCOME,
      category: 'sales',
      amount: 44000,
      source: FinanceSource.POS_AUTOMATIC,
      notes: 'Dine In Meja 03 (Kak Reza)',
    },
  });

  const order2 = await prisma.order.create({
    data: {
      businessId: business.id,
      orderCode: 'ORD-20260910-002',
      userId: cashierUser.id,
      orderType: OrderType.TakeAway,
      customerName: 'Ibu Maya',
      subtotal: 69000,
      tax: 0,
      totalAmount: 69000,
      paymentMethod: PaymentMethod.Cash,
      cashGiven: 100000,
      changeAmount: 31000,
      status: OrderStatus.PAID,
      items: {
        create: [
          {
            productId: products[2].id, // Caramel Macchiato
            productName: products[2].name,
            quantity: 1,
            priceAtSale: products[2].price,
            subtotal: 26000,
          },
          {
            productId: products[3].id, // Matcha Latte
            productName: products[3].name,
            quantity: 1,
            priceAtSale: products[3].price,
            subtotal: 25000,
          },
          {
            productId: products[5].id, // Butter Croissant
            productName: products[5].name,
            quantity: 1,
            priceAtSale: products[5].price,
            subtotal: 20000,
          },
        ],
      },
    },
  });

  await prisma.financeTransaction.create({
    data: {
      businessId: business.id,
      userId: cashierUser.id,
      orderId: order2.id,
      title: `Penjualan Kasir ORD-20260910-002`,
      type: FinanceType.INCOME,
      category: 'sales',
      amount: 69000,
      source: FinanceSource.POS_AUTOMATIC,
      notes: 'Take Away (Ibu Maya)',
    },
  });

  // 8. Catat Pengeluaran Operasional Toko (FinanceTransaction EXPENSE)
  await prisma.financeTransaction.createMany({
    data: [
      {
        businessId: business.id,
        userId: ownerUser.id,
        title: 'Restock Susu Fresh Milk 20 Liter',
        type: FinanceType.EXPENSE,
        category: 'operational',
        amount: 440000,
        source: FinanceSource.MANUAL,
        notes: 'Kulakan mingguan Greenfield',
      },
      {
        businessId: business.id,
        userId: ownerUser.id,
        title: 'Tagihan Listrik & WiFi Kedai',
        type: FinanceType.EXPENSE,
        category: 'utilitas',
        amount: 350000,
        source: FinanceSource.MANUAL,
        notes: 'Bulan berjalan',
      },
    ],
  });

  console.log('💳 Transaksi kasir POS dan catatan keuangan berhasil disimpan.');

  // 9. Simpan contoh Pesan AI dan Konten Promosi
  const aiMsg = await prisma.aiMessage.create({
    data: {
      businessId: business.id,
      userId: ownerUser.id,
      sender: MessageSender.AI,
      text: 'Halo Kak Andika! Saya AIsistenku siap membantu operasional Kedai Kopi Tiga Angkatan. Ada yang ingin Anda cek hari ini?',
      type: 'text',
    },
  });

  await prisma.marketingContent.create({
    data: {
      businessId: business.id,
      sourceMessageId: aiMsg.id,
      type: MarketingContentType.CAPTION,
      platform: 'instagram',
      prompt: 'promo iced kopi susu aren hari senin',
      content: 'Senin kembali produktif ditemani Iced Kopi Susu Tiga Angkatan ☕ Gula aren asli berpadu dengan susu segar bikin harimu anti lemas! Dapatkan promo spesial sekarang.',
      status: MarketingContentStatus.SAVED,
    },
  });

  console.log('✨ Seed database selesai dengan sukses!');
  console.log(`
===================================================
Akun Percobaan:
Owner : owner@tigaangkatan.id  | Password: password123
Kasir : kasir@tigaangkatan.id  | Password: password123
Bisnis: ${business.name} (ID: ${business.id})
===================================================
  `);
}

main()
  .catch((e) => {
    console.error('❌ Terjadi kesalahan saat seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
