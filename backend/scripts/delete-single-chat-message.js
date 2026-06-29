const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();
const messageId = process.argv[2];

async function main() {
  if (!messageId) {
    throw new Error("Usage: node scripts/delete-single-chat-message.js MESSAGE_ID");
  }

  const message = await prisma.message.findUnique({
    where: { id: messageId },
  });

  if (!message) {
    console.log("Message not found:", messageId);
    return;
  }

  console.log("Found message:");
  console.log({
    id: message.id,
    conversationId: message.conversationId,
    senderRole: message.senderRole,
    type: message.type,
    text: message.text,
    createdAt: message.createdAt,
    deletedAt: message.deletedAt,
  });

  const updated = await prisma.message.update({
    where: { id: messageId },
    data: {
      deletedAt: new Date(),
      text: "This message was deleted",
      mediaUrl: null,
      thumbnailUrl: null,
      mimeType: null,
      fileName: null,
      sizeBytes: null,
      durationSeconds: null,
      latitude: null,
      longitude: null,
    },
  });

  const latestVisible = await prisma.message.findFirst({
    where: {
      conversationId: message.conversationId,
      deletedAt: null,
    },
    orderBy: {
      createdAt: "desc",
    },
  });

  await prisma.conversation.update({
    where: { id: message.conversationId },
    data: {
      lastMessageAt: latestVisible?.createdAt ?? null,
      lastMessagePreview: latestVisible
        ? latestVisible.type === "TEXT"
          ? latestVisible.text
          : latestVisible.type
        : null,
    },
  });

  console.log("Soft deleted message:");
  console.log({
    id: updated.id,
    deletedAt: updated.deletedAt,
    text: updated.text,
  });

  console.log("Conversation preview updated.");
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });