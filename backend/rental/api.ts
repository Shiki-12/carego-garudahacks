import { api, APIError, Query } from "encore.dev/api";
import { getAuthData } from "~encore/auth";
import { db } from "../db/db";
import { logActivity } from "../utils/logger";

// Caller identity comes from the verified session (getAuthData), never the body (TD-05).
function currentUserId(): number {
    return Number(getAuthData()!.userID);
}

// --- Interfaces ---

export interface Equipment {
    id: number;
    providerId: number | null;
    name: string;
    category: string;
    description: string | null;
    specifications: Record<string, string> | null;
    dailyRate: number;
    weeklyRate: number | null;
    deposit: number;
    stock: number;
    images: string[];
    isAvailable: boolean;
}

export interface EquipmentListResponse {
    equipment: Equipment[];
    total: number;
}

export interface EquipmentDetailResponse {
    equipment: Equipment & { createdAt: string };
}

export interface BookingRequest {
    equipmentId: number;
    providerId?: number;
    rentalStartDate: string;
    rentalEndDate?: string;
    duration: number;
    durationUnit: string; // 'day' | 'week'
    deliveryAddress: string;
    rate?: number;
    depositAmount?: number;
    totalPrice?: number;
    notes?: string;
}

export interface BookingResponse {
    bookingId: number;
    status: string;
    serviceType: string;
    equipmentId: number;
    providerId: number | null;
    rentalStartDate: string;
    rentalEndDate: string;
    duration: number;
    durationUnit: string;
    deliveryAddress: string;
    depositAmount: number;
    totalPrice: number;
    message: string;
}

function mapEquipment(row: any): Equipment {
    return {
        id: row.id,
        providerId: row.provider_id,
        name: row.name,
        category: row.category,
        description: row.description,
        specifications: row.specifications,
        dailyRate: row.daily_rate,
        weeklyRate: row.weekly_rate,
        deposit: row.deposit,
        stock: row.stock,
        images: row.images ?? [],
        isAvailable: row.is_available,
    };
}

function addDuration(start: string, duration: number, unit: string): string {
    const d = new Date(start);
    d.setDate(d.getDate() + duration * (unit === "week" ? 7 : 1));
    return d.toISOString().slice(0, 10);
}

// --- Endpoints ---

export const listEquipment = api(
    { expose: true, method: "GET", path: "/rental/equipment" },
    async (req: {
        available?: Query<boolean>;
        inStock?: Query<boolean>;
        category?: Query<string>;
        search?: Query<string>;
        limit?: Query<number>;
        offset?: Query<number>;
    }): Promise<EquipmentListResponse> => {
        const limit = req.limit ?? 50;
        const offset = req.offset ?? 0;
        const onlyAvailable = req.available ?? false;
        const onlyInStock = req.inStock ?? false;
        const category = req.category ?? null;
        const search = req.search ? `%${req.search}%` : null;

        const result = await db.query`
            SELECT id, provider_id, name, category, description, specifications,
                   daily_rate, weekly_rate, deposit, stock, images, is_available
            FROM equipment
            WHERE (${onlyAvailable} = FALSE OR is_available = TRUE)
              AND (${onlyInStock} = FALSE OR stock > 0)
              AND (${category}::text IS NULL OR category = ${category})
              AND (${search}::text IS NULL OR name ILIKE ${search})
            ORDER BY name ASC
            LIMIT ${limit} OFFSET ${offset}
        `;

        const equipment: Equipment[] = [];
        for await (const row of result) equipment.push(mapEquipment(row));

        return { equipment, total: equipment.length };
    }
);

export const equipmentDetail = api(
    { expose: true, method: "GET", path: "/rental/equipment/:id" },
    async ({ id }: { id: number }): Promise<EquipmentDetailResponse> => {
        const row = await db.queryRow`
            SELECT id, provider_id, name, category, description, specifications,
                   daily_rate, weekly_rate, deposit, stock, images, is_available, created_at
            FROM equipment WHERE id = ${id}
        `;
        if (!row) throw APIError.notFound("Alat kesehatan tidak ditemukan");
        return { equipment: { ...mapEquipment(row), createdAt: row.created_at } };
    }
);

export const book = api(
    { expose: true, auth: true, method: "POST", path: "/rental/book" },
    async (req: BookingRequest): Promise<BookingResponse> => {
        const userId = currentUserId();
        // --- Validation ---
        if (!req.equipmentId || !req.rentalStartDate || !req.duration ||
            !req.durationUnit || !req.deliveryAddress) {
            throw APIError.invalidArgument("Data pemesanan sewa alat tidak lengkap");
        }
        if (req.duration <= 0) {
            throw APIError.invalidArgument("Durasi sewa harus lebih dari 0");
        }
        if (req.durationUnit !== "day" && req.durationUnit !== "week") {
            throw APIError.invalidArgument("Satuan durasi harus 'day' atau 'week'");
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        if (new Date(req.rentalStartDate) < today) {
            throw APIError.invalidArgument("Tanggal mulai sewa tidak boleh di masa lalu");
        }

        const user = await db.queryRow`SELECT id FROM users WHERE id = ${userId}`;
        if (!user) throw APIError.notFound("User tidak ditemukan");

        const equipment = await db.queryRow`
            SELECT id, provider_id, daily_rate, weekly_rate, deposit, stock, is_available
            FROM equipment WHERE id = ${req.equipmentId}
        `;
        if (!equipment) throw APIError.notFound("Alat kesehatan tidak ditemukan");
        if (!equipment.is_available || equipment.stock <= 0) {
            throw APIError.failedPrecondition("Stok alat tidak tersedia");
        }

        // --- Authoritative pricing (never trust client) ---
        const rate = req.durationUnit === "week"
            ? (equipment.weekly_rate ?? equipment.daily_rate * 7)
            : equipment.daily_rate;
        const deposit = equipment.deposit ?? 0;
        const totalPrice = rate * req.duration + deposit;
        const rentalEndDate = req.rentalEndDate ?? addDuration(req.rentalStartDate, req.duration, req.durationUnit);
        const providerId = req.providerId ?? equipment.provider_id ?? null;

        // --- Create booking + decrement stock atomically ---
        const tx = await db.begin();
        let booking: any;
        try {
            booking = await tx.queryRow`
                INSERT INTO bookings (user_id, provider_id, equipment_id, service_type, status,
                                      rental_start_date, rental_end_date, duration, duration_unit,
                                      delivery_address, deposit_amount, total_price, notes)
                VALUES (${userId}, ${providerId}, ${req.equipmentId}, 'rental', 'pending',
                        ${req.rentalStartDate}, ${rentalEndDate}, ${req.duration}, ${req.durationUnit},
                        ${req.deliveryAddress}, ${deposit}, ${totalPrice}, ${req.notes ?? null})
                RETURNING id, status
            `;
            await tx.exec`UPDATE equipment SET stock = stock - 1 WHERE id = ${req.equipmentId} AND stock > 0`;
            await tx.commit();
        } catch (err) {
            await tx.rollback();
            throw err;
        }

        if (!booking) throw new Error("Gagal membuat booking rental alat medis");

        await logActivity(userId, 'RENTAL_BOOK', `User rented equipment #${req.equipmentId}`);

        return {
            bookingId: booking.id,
            status: booking.status,
            serviceType: "rental",
            equipmentId: req.equipmentId,
            providerId,
            rentalStartDate: req.rentalStartDate,
            rentalEndDate,
            duration: req.duration,
            durationUnit: req.durationUnit,
            deliveryAddress: req.deliveryAddress,
            depositAmount: deposit,
            totalPrice,
            message: "Pemesanan sewa alat berhasil dibuat",
        };
    }
);
