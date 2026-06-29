const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

async function main() {
  const messages = await prisma.message.findMany({
    orderBy: { createdAt: "desc" },
    take: 50,
    select: {
      id: true,
      conversationId: true,
      senderUserId: true,
      senderRole: true,
      type: true,
      text: true,
      mediaUrl: true,
      deletedAt: true,
      createdAt: true,
    },
  });

  console.table(
    messages.map((m) => ({
      id: m.id,
      conversationId: m.conversationId,
      senderRole: m.senderRole,
      type: m.type,
      text: m.text ? m.text.slice(0, 70) : "",
      hasMedia: !!m.mediaUrl,
      deletedAt: m.deletedAt,
      createdAt: m.createdAt,
    }))
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });