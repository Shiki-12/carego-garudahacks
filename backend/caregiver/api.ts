import { api, APIError, Query } from "encore.dev/api";
import { getAuthData } from "~encore/auth";
import { db } from "../db/db";
import { logActivity } from "../utils/logger";

// Caller identity comes from the verified session (getAuthData), never the body (TD-05).
function currentUserId(): number {
    return Number(getAuthData()!.userID);
}

// --- Interfaces ---

export interface Caregiver {
    id: number;
    providerId: number | null;
    name: string;
    specialization: string;
    experienceYears: number;
    hourlyRate: number;
    rating: number;
    reviews: number;
    photoUrl: string | null;
    isAvailable: boolean;
    bio: string | null;
    certifications: string[];
}

export interface CaregiverListResponse {
    caregivers: Caregiver[];
    total: number;
}

export interface CaregiverDetailResponse {
    caregiver: Caregiver & { createdAt: string };
}

export interface BookingRequest {
    caregiverId?: number;
    providerId?: number;
    bookingDate: string;
    startTime: string;
    durationHours: number;
    hourlyRate?: number;
    totalPrice?: number;
    notes?: string;
}

export interface BookingResponse {
    bookingId: number;
    status: string;
    serviceType: string;
    caregiverId: number | null;
    providerId: number | null;
    bookingDate: string;
    startTime: string;
    durationHours: number;
    totalPrice: number;
    message: string;
}

function mapCaregiver(row: any): Caregiver {
    return {
        id: row.id,
        providerId: row.provider_id,
        name: row.name,
        specialization: row.specialization,
        experienceYears: row.experience_years,
        hourlyRate: row.hourly_rate,
        rating: Number(row.rating),
        reviews: row.reviews,
        photoUrl: row.photo_url,
        isAvailable: row.is_available,
        bio: row.bio,
        certifications: row.certifications ?? [],
    };
}

// --- Endpoints ---

export const list = api(
    { expose: true, method: "GET", path: "/caregiver/list" },
    async (req: {
        available?: Query<boolean>;
        search?: Query<string>;
        specialization?: Query<string>;
        limit?: Query<number>;
        offset?: Query<number>;
    }): Promise<CaregiverListResponse> => {
        const limit = req.limit ?? 50;
        const offset = req.offset ?? 0;
        const onlyAvailable = req.available ?? false;
        const search = req.search ? `%${req.search}%` : null;
        const specialization = req.specialization ?? null;

        const result = await db.query`
            SELECT id, provider_id, name, specialization, experience_years, hourly_rate,
                   rating, reviews, photo_url, is_available, bio, certifications
            FROM caregiver_profiles
            WHERE (${onlyAvailable} = FALSE OR is_available = TRUE)
              AND (${search}::text IS NULL OR name ILIKE ${search})
              AND (${specialization}::text IS NULL OR specialization = ${specialization})
            ORDER BY rating DESC
            LIMIT ${limit} OFFSET ${offset}
        `;

        const caregivers: Caregiver[] = [];
        for await (const row of result) caregivers.push(mapCaregiver(row));

        return { caregivers, total: caregivers.length };
    }
);

export const detail = api(
    { expose: true, method: "GET", path: "/caregiver/:id" },
    async ({ id }: { id: number }): Promise<CaregiverDetailResponse> => {
        const row = await db.queryRow`
            SELECT id, provider_id, name, specialization, experience_years, hourly_rate,
                   rating, reviews, photo_url, is_available, bio, certifications, created_at
            FROM caregiver_profiles WHERE id = ${id}
        `;
        if (!row) throw APIError.notFound("Caregiver tidak ditemukan");
        return { caregiver: { ...mapCaregiver(row), createdAt: row.created_at } };
    }
);

export const book = api(
    { expose: true, auth: true, method: "POST", path: "/caregiver/book" },
    async (req: BookingRequest): Promise<BookingResponse> => {
        const userId = currentUserId();
        // --- Validation ---
        if ((!req.caregiverId && !req.providerId) || !req.bookingDate || !req.startTime || !req.durationHours) {
            throw APIError.invalidArgument("Data pemesanan caregiver tidak lengkap");
        }
        if (req.durationHours <= 0) {
            throw APIError.invalidArgument("Durasi layanan harus lebih dari 0 jam");
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        if (new Date(req.bookingDate) < today) {
            throw APIError.invalidArgument("Tanggal pemesanan tidak boleh di masa lalu");
        }

        const user = await db.queryRow`SELECT id FROM users WHERE id = ${userId}`;
        if (!user) throw APIError.notFound("User tidak ditemukan");

        // --- Resolve caregiver + availability ---
        let caregiver: any = null;
        if (req.caregiverId) {
            caregiver = await db.queryRow`SELECT id, provider_id, hourly_rate, is_available FROM caregiver_profiles WHERE id = ${req.caregiverId}`;
            if (!caregiver) throw APIError.notFound("Caregiver tidak ditemukan");
            if (!caregiver.is_available) throw APIError.failedPrecondition("Caregiver tidak tersedia");
        }

        // --- Authoritative price (never trust client) ---
        const hourlyRate = caregiver?.hourly_rate ?? req.hourlyRate ?? 0;
        const totalPrice = hourlyRate * req.durationHours;
        const providerId = req.providerId ?? caregiver?.provider_id ?? null;

        // Postgres TIME requires HH:MM:SS; clients often send HH:MM. Normalize + validate.
        const timeMatch = /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/.exec(req.startTime.trim());
        if (!timeMatch) {
            throw APIError.invalidArgument("Format startTime tidak valid (harus HH:MM atau HH:MM:SS)");
        }
        const startTime = `${timeMatch[1].padStart(2, "0")}:${timeMatch[2]}:${timeMatch[3] ?? "00"}`;

        const booking = await db.queryRow`
            INSERT INTO bookings (user_id, provider_id, caregiver_id, service_type, status,
                                  booking_date, start_time, duration_hours, total_price, notes)
            VALUES (${userId}, ${providerId}, ${req.caregiverId ?? null}, 'caregiver', 'pending',
                    ${req.bookingDate}::date, ${startTime}::time, ${req.durationHours}, ${totalPrice}, ${req.notes ?? null})
            RETURNING id, status
        `;
        if (!booking) throw new Error("Gagal membuat booking caregiver");

        await logActivity(userId, 'CAREGIVER_BOOK', `User booked caregiver #${req.caregiverId ?? providerId}`);

        return {
            bookingId: booking.id,
            status: booking.status,
            serviceType: "caregiver",
            caregiverId: req.caregiverId ?? null,
            providerId,
            bookingDate: req.bookingDate,
            startTime: req.startTime,
            durationHours: req.durationHours,
            totalPrice,
            message: "Pemesanan caregiver berhasil dibuat",
        };
    }
);
