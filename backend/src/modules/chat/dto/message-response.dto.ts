import { MessageType, Role } from '@prisma/client';

export class MessageResponseDto {
  id: string;
  conversationId: string;
  senderUserId: string;
  senderRole: Role;
  type: MessageType;
  text: string | null;
  mediaUrl: string | null;
  storageKey: string | null;
  thumbnailUrl: string | null;
  mimeType: string | null;
  fileName: string | null;
  sizeBytes: number | null;
  durationSeconds: number | null;
  latitude: number | null;
  longitude: number | null;
  bookingId: string | null;
  replyToMessageId: string | null;
  editedAt: string | null;
  deletedAt: string | null;
  seenAt: string | null;
  createdAt: string;
  updatedAt: string;
}
