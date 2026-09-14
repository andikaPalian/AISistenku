import { prisma } from '../src/config/database.config.js';

async function main() {
  console.log('=== AUDITING PRODUCTS AND RECIPES ===');
  const products = await prisma.product.findMany({
    include: {
      recipes: {
        include: { stock: true }
      }
    }
  });

  for (const p of products) {
    console.log(`Product: ${p.name} (id: ${p.id}, price: ${p.price})`);
    for (const r of p.recipes) {
      console.log(`  -> Recipe: stockId: ${r.stockId} (${r.stock?.name}), qtyRequired: ${r.quantityRequired} ${r.stock?.unit}`);
    }
  }

  // Find pepaya stock
  const pepayaStock = await prisma.stockItem.findFirst({
    where: { name: { equals: 'pepaya', mode: 'insensitive' } }
  });

  const pepayaProduct = await prisma.product.findFirst({
    where: { name: { equals: 'pepaya', mode: 'insensitive' } },
    include: { recipes: true }
  });

  if (pepayaProduct && pepayaStock) {
    console.log('\nFixing pepaya recipe...');
    // Delete old wrong recipes
    await prisma.productRecipe.deleteMany({
      where: { productId: pepayaProduct.id }
    });

    // Create correct recipe linking to pepaya stock with qtyRequired = 1
    const newRecipe = await prisma.productRecipe.create({
      data: {
        productId: pepayaProduct.id,
        stockId: pepayaStock.id,
        quantityRequired: 1
      }
    });

    console.log('Created correct recipe for pepaya:', newRecipe);
  } else {
    console.log('Pepaya product or stock not found!');
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
