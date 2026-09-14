import { prisma } from '../src/config/database.config.js';

async function main() {
  const products = await prisma.product.findMany({
    where: { name: { contains: 'pepaya', mode: 'insensitive' } },
    include: {
      recipes: {
        include: { stock: true }
      }
    }
  });
  console.log('PRODUCTS FOUND:', JSON.stringify(products, null, 2));

  const stocks = await prisma.stockItem.findMany({
    where: { name: { contains: 'pepaya', mode: 'insensitive' } }
  });
  console.log('STOCKS FOUND:', JSON.stringify(stocks, null, 2));
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
