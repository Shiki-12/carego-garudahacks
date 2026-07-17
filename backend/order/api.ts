import { api, APIError } from "encore.dev/api";
import { getAuthData } from "~encore/auth";
import { db } from "../db/db";
import { logActivity } from "../utils/logger";

// Caller identity comes from the verified session (getAuthData), never the body (TD-05).
function currentUserId(): number {
    return Number(getAuthData()!.userID);
}

// --- Interfaces ---

export interface Booking {
    id: number;
    serviceType: string | null;
    providerName: string | null;
    status: string;
    totalPrice: number | null;
    date: string;
    pickupAddress: string | null;
    destinationAddress: string | null;
    notes: string | null;
}

export interface ListRequest {
    status?: string; // 'active' | 'completed' | 'cancelled' | 'all'
    limit?: number;
    offset?: number;
}

export interface ListResponse {
    bookings: Booking[];
    total: number;
}

export interface CancelRequest {
    reason?: string;
}

export interface CancelResponse {
    success: boolean;
    booking: {
        id: number;
        status: string;
        cancelledAt: string;
        cancelReason: string | null;
    };
    message: string;
}

// --- Endpoints ---

export const list = api(
    { expose: true, auth: true, method: "POST", path: "/bookings/list" },
    async (req: ListRequest): Promise<ListResponse> => {
        const userId = currentUserId();
        const limit = req.limit ?? 20;
        const offset = req.offset ?? 0;
        const status = req.status ?? "all";

        // Map the status group to a concrete SQL filter.
        let statuses: string[] | null;
        switch (status) {
            case "active": statuses = ["pending", "confirmed"]; break;
            case "completed": statuses = ["completed"]; break;
            case "cancelled": statuses = ["cancelled"]; break;
            default: statuses = null; // all
        }

        const result = await db.query`
            SELECT id, service_type, provider_name, status, total_price, created_at,
                   pickup_location, destination, notes
            FROM bookings
            WHERE user_id = ${userId}
              AND (${statuses}::text[] IS NULL OR status = ANY(${statuses}))
            ORDER BY created_at DESC
            LIMIT ${limit} OFFSET ${offset}
        `;

        const bookings: Booking[] = [];
        for await (const row of result) {
            bookings.push({
                id: row.id,
                serviceType: row.service_type,
                providerName: row.provider_name,
                status: row.status,
                totalPrice: row.total_price,
                date: row.created_at,
                pickupAddress: row.pickup_location,
                destinationAddress: row.destination,
                notes: row.notes,
            });
        }

        return { bookings, total: bookings.length };
    }
);

export const cancel = api(
    { expose: true, auth: true, method: "POST", path: "/bookings/:id/cancel" },
    async ({ id, ...req }: { id: number } & CancelRequest): Promise<CancelResponse> => {
        const userId = currentUserId();
        const booking = await db.queryRow`
            SELECT id, status FROM bookings WHERE id = ${id} AND user_id = ${userId}
        `;
        if (!booking) throw APIError.notFound("Pesanan tidak ditemukan");

        if (booking.status === "completed") {
            throw APIError.failedPrecondition("Pesanan sudah selesai dan tidak dapat dibatalkan");
        }
        if (booking.status === "cancelled") {
            throw APIError.failedPrecondition("Pesanan sudah dibatalkan sebelumnya");
        }

        const reason = req.reason ?? "Dibatalkan oleh pengguna";
        const fromStatus = booking.status;

        const tx = await db.begin();
        let updated: any;
        try {
            updated = await tx.queryRow`
                UPDATE bookings
                SET status = 'cancelled', cancelled_at = NOW(), cancel_reason = ${reason}, updated_at = NOW()
                WHERE id = ${id}
                RETURNING id, status, cancelled_at, cancel_reason
            `;
            await tx.exec`
                INSERT INTO booking_status_history (booking_id, from_status, to_status, changed_by, reason)
                VALUES (${id}, ${fromStatus}, 'cancelled', ${userId}, ${reason})
            `;
            await tx.commit();
        } catch (err) {
            await tx.rollback();
            throw err;
        }

        await logActivity(userId, 'BOOKING_CANCEL', `Cancelled booking #${id}`);

        return {
            success: true,
            booking: {
                id: updated.id,
                status: updated.status,
                cancelledAt: updated.cancelled_at,
                cancelReason: updated.cancel_reason,
            },
            message: "Pesanan berhasil dibatalkan",
        };
    }
);
