import { prisma } from '../src/config/database.config.js';
import { handleChat } from '../src/modules/ai/ai.service.js';

async function main() {
  const business = await prisma.business.findFirst();
  if (!business) {
    console.log('No business found');
    return;
  }
  console.log('Testing handleChat for business:', business.name, business.id);
  const result = await handleChat(business.id, null, 'sisa berapa stok kopi susu');
  console.log('RESULT TYPE:', result.type);
  console.log('RESULT MESSAGE:\n', result.message);
}

main().catch(console.error).finally(() => prisma.$disconnect());
