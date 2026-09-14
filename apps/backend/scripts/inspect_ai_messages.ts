import { prisma } from '../src/config/database.config.js';

async function main() {
  const msgs = await prisma.aiMessage.findMany({
    orderBy: { timestamp: 'desc' },
    take: 10,
  });
  console.log(`AI MESSAGES IN DB: ${msgs.length}`);
  msgs.forEach(m => console.log(`[${m.sender}] (${m.type}) - ${m.text}`));
}

main().catch(console.error).finally(() => prisma.$disconnect());
