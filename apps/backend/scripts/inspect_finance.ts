import { prisma } from '../src/config/database.config.js';

async function main() {
  console.log('=== INSPECTING FINANCE TRANSACTIONS IN DATABASE ===');
  const txs = await prisma.financeTransaction.findMany({
    orderBy: { timestamp: 'desc' },
    take: 20
  });
  console.log(`Found ${txs.length} transactions:`);
  for (const t of txs) {
    console.log(`[${t.timestamp.toISOString()}] ${t.type} | ${t.category} | ${t.amount} | ${t.title} (orderId: ${t.orderId})`);
  }

  console.log('\n=== INSPECTING ORDERS IN DATABASE ===');
  const orders = await prisma.order.findMany({
    orderBy: { createdAt: 'desc' },
    take: 10,
    include: { items: true }
  });
  console.log(`Found ${orders.length} orders:`);
  for (const o of orders) {
    console.log(`[${o.createdAt.toISOString()}] ${o.orderCode} | status: ${o.status} | total: ${o.totalAmount} | items: ${o.items.map(i => `${i.productName} x${i.quantity}`).join(', ')}`);
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
