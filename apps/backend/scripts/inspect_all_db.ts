import { prisma } from '../src/config/database.config.js';

async function main() {
  const products = await prisma.product.findMany({
    select: { id: true, name: true, price: true, category: true, isActive: true }
  });
  console.log(`TOTAL PRODUCTS IN DB: ${products.length}`);
  products.forEach(p => console.log(` - [${p.id}] ${p.name} | ${p.category} | Rp ${p.price} | active: ${p.isActive}`));

  const orders = await prisma.order.findMany({
    take: 5,
    orderBy: { createdAt: 'desc' },
    select: { id: true, orderNumber: true, total: true, paymentMethod: true, createdAt: true }
  });
  console.log(`\nRECENT ORDERS: ${orders.length}`);
  orders.forEach(o => console.log(` - ${o.orderNumber} | ${o.paymentMethod} | Rp ${o.total} | ${o.createdAt}`));
}

main().catch(console.error).finally(() => prisma.$disconnect());
