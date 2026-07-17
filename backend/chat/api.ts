import { api, APIError, StreamInOut } from "encore.dev/api";
import { getAuthData } from "~encore/auth";
import { db } from "../db/db";

// Caller identity comes from the verified session (getAuthData), never the body (TD-05).
function currentUserId(): number {
    return Number(getAuthData()!.userID);
}

// --- Interfaces ---

export interface Conversation {
    id: number;
    bookingId: number | null;
    participantId: number;
    participantName: string;
    participantRole: string;
    participantPhotoUrl: string | null;
    lastMessage: string | null;
    lastMessageTime: string | null;
    unreadCount: number;
}

export interface ConversationsResponse {
    conversations: Conversation[];
    total: number;
}

export interface Message {
    id: number;
    conversationId: number;
    senderId: number;
    text: string;
    type: string;
    imageUrl: string | null;
    isSentByMe: boolean;
    isRead: boolean;
    timestamp: string;
}

export interface MessagesResponse {
    messages: Message[];
    total: number;
}

export interface SendMessageRequest {
    conversationId: number;
    text: string;
    type?: string;
    imageUrl?: string;
}

export interface SendMessageResponse {
    message: {
        id: number;
        conversationId: number;
        senderId: number;
        text: string;
        type: string;
        imageUrl: string | null;
        isRead: boolean;
        timestamp: string;
    };
    success: boolean;
}

// --- Endpoints ---

// GET /chat/conversations
export const conversations = api(
    { expose: true, auth: true, method: "GET", path: "/chat/conversations" },
    async ({ limit, offset }: { limit?: number; offset?: number }): Promise<ConversationsResponse> => {
        const userId = currentUserId();
        const result = await db.query`
            SELECT
                c.id,
                c.booking_id,
                CASE WHEN c.participant_1 = ${userId} THEN c.participant_2 ELSE c.participant_1 END AS participant_id,
                u.name AS participant_name,
                u.role AS participant_role,
                u.photo_url AS participant_photo_url,
                (SELECT content FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1) AS last_message,
                c.last_message_at,
                (SELECT COUNT(*) FROM messages m WHERE m.conversation_id = c.id AND m.sender_id <> ${userId} AND m.is_read = FALSE) AS unread_count
            FROM conversations c
            JOIN users u ON u.id = (CASE WHEN c.participant_1 = ${userId} THEN c.participant_2 ELSE c.participant_1 END)
            WHERE c.participant_1 = ${userId} OR c.participant_2 = ${userId}
            ORDER BY c.last_message_at DESC NULLS LAST
            LIMIT ${limit ?? 50} OFFSET ${offset ?? 0}
        `;

        const list: Conversation[] = [];
        for await (const row of result) {
            list.push({
                id: row.id,
                bookingId: row.booking_id,
                participantId: row.participant_id,
                participantName: row.participant_name,
                participantRole: row.participant_role,
                participantPhotoUrl: row.participant_photo_url,
                lastMessage: row.last_message,
                lastMessageTime: row.last_message_at,
                unreadCount: parseInt(row.unread_count ?? "0"),
            });
        }

        return { conversations: list, total: list.length };
    }
);

// GET /chat/conversations/:id/messages
export const messages = api(
    { expose: true, auth: true, method: "GET", path: "/chat/conversations/:id/messages" },
    async ({ id, limit, offset }: { id: number; limit?: number; offset?: number }): Promise<MessagesResponse> => {
        const userId = currentUserId();
        const result = await db.query`
            SELECT id, conversation_id, sender_id, content, type, image_url, is_read, created_at
            FROM messages
            WHERE conversation_id = ${id}
            ORDER BY created_at ASC
            LIMIT ${limit ?? 100} OFFSET ${offset ?? 0}
        `;

        const list: Message[] = [];
        for await (const row of result) {
            list.push({
                id: row.id,
                conversationId: row.conversation_id,
                senderId: row.sender_id,
                text: row.content,
                type: row.type,
                imageUrl: row.image_url,
                isSentByMe: row.sender_id === userId,
                isRead: row.is_read,
                timestamp: row.created_at,
            });
        }

        return { messages: list, total: list.length };
    }
);

async function persistMessage(req: SendMessageRequest, senderId: number) {
    // Authorize sender is a participant.
    const conv = await db.queryRow`
        SELECT id FROM conversations
        WHERE id = ${req.conversationId} AND (participant_1 = ${senderId} OR participant_2 = ${senderId})
    `;
    if (!conv) throw APIError.permissionDenied("Anda bukan peserta percakapan ini");

    const row = await db.queryRow`
        INSERT INTO messages (conversation_id, sender_id, content, type, image_url, is_read)
        VALUES (${req.conversationId}, ${senderId}, ${req.text}, ${req.type ?? 'text'}, ${req.imageUrl ?? null}, FALSE)
        RETURNING id, conversation_id, sender_id, content, type, image_url, is_read, created_at
    `;
    if (!row) throw new Error("Gagal mengirim pesan");

    await db.exec`UPDATE conversations SET last_message_at = NOW() WHERE id = ${req.conversationId}`;
    return row;
}

// POST /chat/messages/send
export const send = api(
    { expose: true, auth: true, method: "POST", path: "/chat/messages/send" },
    async (req: SendMessageRequest): Promise<SendMessageResponse> => {
        const row = await persistMessage(req, currentUserId());
        const message = {
            id: row.id,
            conversationId: row.conversation_id,
            senderId: row.sender_id,
            text: row.content,
            type: row.type,
            imageUrl: row.image_url,
            isRead: row.is_read,
            timestamp: row.created_at,
        };
        // Fan out to any connected sockets in this conversation.
        broadcast(row.conversation_id, { event: "message.created", message });
        return { message, success: true };
    }
);

// --- WebSocket: /chat/ws ---

interface WsInbound {
    event: string; // 'message.send' | 'message.read'
    conversationId: number;
    senderId?: number;
    text?: string;
    type?: string;
    imageUrl?: string;
    messageId?: number;
    readerId?: number;
    clientMessageId?: string;
}

interface WsOutbound {
    event: string;
    message?: unknown;
    conversationId?: number;
    messageId?: number;
    readerId?: number;
    readAt?: string;
}

// Track connected streams per conversation for broadcast.
const rooms = new Map<number, Set<StreamInOut<WsInbound, WsOutbound>>>();

function join(conversationId: number, stream: StreamInOut<WsInbound, WsOutbound>) {
    if (!rooms.has(conversationId)) rooms.set(conversationId, new Set());
    rooms.get(conversationId)!.add(stream);
}

function leave(conversationId: number, stream: StreamInOut<WsInbound, WsOutbound>) {
    rooms.get(conversationId)?.delete(stream);
}

function broadcast(conversationId: number, payload: WsOutbound) {
    const room = rooms.get(conversationId);
    if (!room) return;
    for (const s of room) {
        s.send(payload).catch(() => leave(conversationId, s));
    }
}

export const ws = api.streamInOut<{ conversationId: number }, WsInbound, WsOutbound>(
    { expose: true, path: "/chat/ws" },
    async (handshake, stream) => {
        const conversationId = handshake.conversationId;
        join(conversationId, stream);
        try {
            for await (const msg of stream) {
                if (msg.event === "message.send" && msg.senderId && msg.text) {
                    const row = await persistMessage({
                        conversationId: msg.conversationId,
                        text: msg.text,
                        type: msg.type,
                        imageUrl: msg.imageUrl,
                    }, msg.senderId);
                    broadcast(msg.conversationId, {
                        event: "message.created",
                        message: {
                            id: row.id,
                            conversationId: row.conversation_id,
                            senderId: row.sender_id,
                            text: row.content,
                            type: row.type,
                            imageUrl: row.image_url,
                            isRead: row.is_read,
                            timestamp: row.created_at,
                        },
                    });
                } else if (msg.event === "message.read" && msg.messageId && msg.readerId) {
                    await db.exec`UPDATE messages SET is_read = TRUE WHERE id = ${msg.messageId}`;
                    broadcast(msg.conversationId, {
                        event: "message.read",
                        conversationId: msg.conversationId,
                        messageId: msg.messageId,
                        readerId: msg.readerId,
                        readAt: new Date().toISOString(),
                    });
                }
            }
        } finally {
            leave(conversationId, stream);
        }
    }
);
