import { api, APIError } from "encore.dev/api";
import { getAuthData } from "~encore/auth";
import { db } from "../db/db";
import { logActivity } from "../utils/logger";

// Caller identity comes from the verified session (getAuthData), never the body (TD-05).
function currentUserId(): number {
    return Number(getAuthData()!.userID);
}

export interface Recommendation {
    id: number;
    serviceType: string;
    title: string;
    tagLabel: string;
    tagColor: string;
    rating: number;
    reviews: number;
    price: string;
    image: string;
}

export interface RecommendationsResponse {
    recommendations: Recommendation[];
}

export interface BookingRequest {
    providerId?: number;
}

export interface BookingResponse {
    bookingId: number;
    status: string;
}

export interface WsResponse {
    success: boolean;
    message: string;
}

export const recommendations = api(
    { expose: true, method: "GET", path: "/ambulance/recommendations" },
    async (): Promise<RecommendationsResponse> => {
        const result = await db.query`
            SELECT id, service_type, title, tag_label, tag_color, rating, reviews, price, image
            FROM recommendations 
            WHERE is_active = TRUE
            ORDER BY created_at DESC
        `;
        
        const recs: Recommendation[] = [];
        for await (const row of result) {
            recs.push({
                id: row.id,
                serviceType: row.service_type,
                title: row.title,
                tagLabel: row.tag_label,
                tagColor: row.tag_color,
                rating: Number(row.rating),
                reviews: row.reviews,
                price: row.price,
                image: row.image
            });
        }
        
        return { recommendations: recs };
    }
);

export const book = api(
    { expose: true, auth: true, method: "POST", path: "/ambulance/book" },
    async (req: BookingRequest): Promise<BookingResponse> => {
        const userId = currentUserId();
        const user = await db.queryRow`SELECT id FROM users WHERE id = ${userId}`;
        if (!user) throw APIError.notFound("User tidak ditemukan");

        // providerId is optional: when omitted the booking is broadcast (unassigned).
        // When supplied it must reference a real provider, else the FK would throw a 500.
        const providerId = req.providerId ?? null;
        if (providerId !== null) {
            const provider = await db.queryRow`SELECT id FROM providers WHERE id = ${providerId}`;
            if (!provider) throw APIError.notFound("Provider tidak ditemukan");
        }

        const booking = await db.queryRow`
            INSERT INTO bookings (user_id, provider_id, service_type, status)
            VALUES (${userId}, ${providerId}, 'ambulance', 'pending')
            RETURNING id, status
        `;

        if (!booking) throw new Error("Gagal membuat booking");
        
        await logActivity(userId, 'AMBULANCE_BOOK', 'User booked ambulance');

        return {
            bookingId: booking.id,
            status: booking.status
        };
    }
);

export const ws = api(
    { expose: true, method: "GET", path: "/ambulance/ws" },
    async (): Promise<WsResponse> => {
        return { success: true, message: "WebSocket stub for live tracking" };
    }
);
