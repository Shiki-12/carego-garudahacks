import { api } from "encore.dev/api";
import { getAuthData } from "~encore/auth";
import { db } from "../db/db";
import { logActivity } from "../utils/logger";

// Caller identity comes from the verified session (getAuthData), never the body (TD-05).
function currentUserId(): number {
    return Number(getAuthData()!.userID);
}

// --- Interfaces (SRS-08 response contract, camelCase) ---

export interface UserRequest {
}

export interface Notification {
    id: number;
    type: string;
    title: string;
    message: string;
    timestamp: string;
    isRead: boolean;
    data: Record<string, unknown> | null;
}

export interface NotificationsResponse {
    notifications: Notification[];
    unreadCount: number;
    total: number;
}

export interface UnreadCountResponse {
    count: number;
}

export interface Preferences {
    bookingUpdates: boolean;
    promotions: boolean;
    systemUpdates: boolean;
    chatMessages: boolean;
}

export interface PreferencesResponse {
    preferences: Preferences;
}

export interface ReadNotificationRequest {
    notificationId: number;
}

export interface ReadResponse {
    success: boolean;
    notification: { id: number; isRead: boolean };
    unreadCount: number;
}

export interface ReadAllResponse {
    success: boolean;
    updatedCount: number;
    unreadCount: number;
}

export interface UpdatePreferencesRequest {
    bookingUpdates: boolean;
    promotions: boolean;
    systemUpdates: boolean;
    chatMessages: boolean;
}

export interface UpdatePreferencesResponse {
    success: boolean;
    preferences: Preferences;
}

// --- Helpers ---

async function countUnread(userId: number): Promise<number> {
    const row = await db.queryRow`SELECT COUNT(*) as count FROM notifications WHERE user_id = ${userId} AND is_read = FALSE`;
    return parseInt(row?.count ?? "0");
}

function mapNotification(row: any): Notification {
    return {
        id: row.id,
        type: row.type,
        title: row.title,
        message: row.message,
        timestamp: row.created_at,
        isRead: row.is_read,
        data: row.data ?? null,
    };
}

// --- Endpoints ---

export const list = api(
    { expose: true, auth: true, method: "POST", path: "/notifications/list" },
    async (req: UserRequest & { limit?: number; offset?: number }): Promise<NotificationsResponse> => {
        const userId = currentUserId();
        const result = await db.query`
            SELECT id, type, title, message, is_read, data, created_at
            FROM notifications
            WHERE user_id = ${userId}
            ORDER BY created_at DESC
            LIMIT ${req.limit ?? 50} OFFSET ${req.offset ?? 0}
        `;
        const notifications: Notification[] = [];
        for await (const row of result) notifications.push(mapNotification(row));

        const unreadCount = await countUnread(userId);
        return { notifications, unreadCount, total: notifications.length };
    }
);

export const read = api(
    { expose: true, auth: true, method: "POST", path: "/notifications/read" },
    async (req: ReadNotificationRequest): Promise<ReadResponse> => {
        const userId = currentUserId();
        await db.exec`UPDATE notifications SET is_read = TRUE WHERE id = ${req.notificationId} AND user_id = ${userId}`;
        return {
            success: true,
            notification: { id: req.notificationId, isRead: true },
            unreadCount: await countUnread(userId),
        };
    }
);

export const readAll = api(
    { expose: true, auth: true, method: "POST", path: "/notifications/read-all" },
    async (): Promise<ReadAllResponse> => {
        const userId = currentUserId();
        const before = await countUnread(userId);
        await db.exec`UPDATE notifications SET is_read = TRUE WHERE user_id = ${userId}`;
        return { success: true, updatedCount: before, unreadCount: 0 };
    }
);

export const unreadCount = api(
    { expose: true, auth: true, method: "POST", path: "/notifications/unread-count" },
    async (): Promise<UnreadCountResponse> => {
        return { count: await countUnread(currentUserId()) };
    }
);

export const getPreferences = api(
    { expose: true, auth: true, method: "POST", path: "/notifications/preferences" },
    async (): Promise<PreferencesResponse> => {
        const userId = currentUserId();
        const row = await db.queryRow`
            SELECT booking_updates, promotions, system_updates, chat_messages
            FROM notification_preferences WHERE user_id = ${userId}
        `;
        if (row) {
            return {
                preferences: {
                    bookingUpdates: row.booking_updates,
                    promotions: row.promotions,
                    systemUpdates: row.system_updates,
                    chatMessages: row.chat_messages ?? true,
                },
            };
        }
        return { preferences: { bookingUpdates: true, promotions: true, systemUpdates: true, chatMessages: true } };
    }
);

export const updatePreferences = api(
    { expose: true, auth: true, method: "PUT", path: "/notifications/preferences" },
    async (req: UpdatePreferencesRequest): Promise<UpdatePreferencesResponse> => {
        const userId = currentUserId();
        await db.exec`
            INSERT INTO notification_preferences (user_id, booking_updates, promotions, system_updates, chat_messages)
            VALUES (${userId}, ${req.bookingUpdates}, ${req.promotions}, ${req.systemUpdates}, ${req.chatMessages})
            ON CONFLICT (user_id) DO UPDATE SET
                booking_updates = EXCLUDED.booking_updates,
                promotions = EXCLUDED.promotions,
                system_updates = EXCLUDED.system_updates,
                chat_messages = EXCLUDED.chat_messages
        `;
        await logActivity(userId, 'UPDATE_PREFERENCES', 'User updated notification preferences');
        return {
            success: true,
            preferences: {
                bookingUpdates: req.bookingUpdates,
                promotions: req.promotions,
                systemUpdates: req.systemUpdates,
                chatMessages: req.chatMessages,
            },
        };
    }
);
