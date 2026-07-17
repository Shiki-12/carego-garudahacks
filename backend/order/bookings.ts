import { api, Header } from "encore.dev/api";
import log from "encore.dev/log";
import { getAuthData } from "~encore/auth";
import { db } from "../db/db";
import { ok, validationError, forbidden, type Ok } from "../shared/response";
import {
  priceAmbulance,
  priceRental,
  priceCaregiver,
  type ServiceType,
  type FleetType,
} from "./pricing";
import { notifyUser, findCandidateMitraUserIds } from "./notify";

// --- Interfaces ---

interface CreateBookingReq {
  idempotencyKey: Header<"Idempotency-Key">;
  serviceType: ServiceType;
  providerId?: number; // specific mitra; otherwise broadcast
  // ambulance
  pickupLat?: number;
  pickupLng?: number;
  pickupAddress?: string;
  destLat?: number;
  destLng?: number;
  destAddress?: string;
  fleetType?: FleetType;
  // caregiver
  caregiverId?: number;
  durationHours?: number;
  // rental
  rentalItemId?: number;
  rentalDays?: number;
  // shared
  scheduledAt?: string; // ISO-8601
  patientName: string;
  notes?: string;
}

export interface CreatedBooking {
  id: number;
  serviceType: string;
  status: string;
  totalPrice: number;
  distanceKm: number | null;
  providerId: number | null;
  patientName: string;
  createdAt: string;
}

const VALID_SERVICE_TYPES: ServiceType[] = ["ambulance", "caregiver", "rental"];

// --- Endpoint ---

// POST /bookings (scope: patient). Server computes the price, persists a pending
// booking + status-history row atomically, then notifies candidate mitra.
// Idempotency-Key guards against double-booking on retry/double-tap (doc 01 §8).
export const createBooking = api(
  { expose: true, auth: true, method: "POST", path: "/bookings" },
  async (req: CreateBookingReq): Promise<Ok<CreatedBooking>> => {
    const auth = getAuthData()!;
    const userId = Number(auth.userID);

    // Scope: only patients create bookings for themselves (doc 02 §6).
    if (auth.role !== "patient") {
      throw forbidden("Hanya akun pasien yang dapat membuat pesanan");
    }

    // --- Input validation ---
    if (!VALID_SERVICE_TYPES.includes(req.serviceType)) {
      throw validationError("Jenis layanan tidak valid", { field: "serviceType" });
    }
    if (!req.patientName || req.patientName.trim().length === 0) {
      throw validationError("Nama pasien wajib diisi", { field: "patientName" });
    }

    const idemKey = (req.idempotencyKey ?? "").trim();
    if (!idemKey) {
      throw validationError("Idempotency-Key wajib disertakan", { field: "Idempotency-Key" });
    }

    // --- Idempotency short-circuit: return stored response on repeat ---
    const existing = await db.queryRow`
      SELECT response_json FROM idempotency_keys
      WHERE key = ${idemKey} AND endpoint = 'POST /bookings'
    `;
    if (existing) {
      return ok(existing.response_json as CreatedBooking);
    }

    // --- Server-side pricing (never trust client amounts) ---
    let totalPrice: number;
    let distanceKm: number | null = null;
    if (req.serviceType === "ambulance") {
      const p = priceAmbulance({
        fleetType: req.fleetType,
        pickupLat: req.pickupLat,
        pickupLng: req.pickupLng,
        destLat: req.destLat,
        destLng: req.destLng,
      });
      totalPrice = p.totalPrice;
      distanceKm = p.distanceKm;
    } else if (req.serviceType === "rental") {
      const p = await priceRental(req.rentalItemId, req.rentalDays);
      totalPrice = p.totalPrice;
    } else {
      const p = await priceCaregiver(req.caregiverId, req.durationHours);
      totalPrice = p.totalPrice;
    }

    // --- Persist booking + history + idempotency record atomically ---
    const tx = await db.begin();
    let created: CreatedBooking;
    try {
      const booking = await tx.queryRow`
        INSERT INTO bookings (
          user_id, provider_id, service_type, status,
          pickup_location, pickup_lat, pickup_lng,
          destination, dest_lat, dest_lng, distance_km, fleet_type,
          caregiver_id, duration_hours,
          equipment_id, duration, duration_unit,
          total_price, patient_name, notes, scheduled_at,
          created_at, updated_at
        ) VALUES (
          ${userId}, ${req.providerId ?? null}, ${req.serviceType}, 'pending',
          ${req.pickupAddress ?? null}, ${req.pickupLat ?? null}, ${req.pickupLng ?? null},
          ${req.destAddress ?? null}, ${req.destLat ?? null}, ${req.destLng ?? null},
          ${distanceKm}, ${req.fleetType ?? null},
          ${req.caregiverId ?? null}, ${req.durationHours ?? null},
          ${req.rentalItemId ?? null}, ${req.rentalDays ?? null},
          ${req.rentalDays != null ? "day" : null},
          ${totalPrice}, ${req.patientName}, ${req.notes ?? null}, ${req.scheduledAt ?? null},
          NOW(), NOW()
        )
        RETURNING id, service_type, status, provider_id, total_price, distance_km,
                  patient_name, created_at
      `;
      if (!booking) throw new Error("Gagal membuat pesanan");

      await tx.exec`
        INSERT INTO booking_status_history (booking_id, from_status, to_status, changed_by, reason)
        VALUES (${booking.id}, NULL, 'pending', ${userId}, 'Pesanan dibuat')
      `;

      const payload: CreatedBooking = {
        id: booking.id,
        serviceType: booking.service_type,
        status: booking.status,
        totalPrice: Number(booking.total_price),
        distanceKm: booking.distance_km != null ? Number(booking.distance_km) : null,
        providerId: booking.provider_id != null ? Number(booking.provider_id) : null,
        patientName: booking.patient_name,
        createdAt: booking.created_at,
      };

      await tx.exec`
        INSERT INTO idempotency_keys (key, user_id, endpoint, response_json)
        VALUES (${idemKey}, ${userId}, 'POST /bookings', ${payload})
      `;

      await tx.commit();
      created = payload;
    } catch (err) {
      await tx.rollback();
      throw err;
    }

    log.info("booking created", {
      bookingId: created.id,
      userId,
      serviceType: created.serviceType,
      totalPrice: created.totalPrice,
    });

    // --- Notify candidate mitra (best-effort, outside the transaction) ---
    const isEmergency = req.serviceType === "ambulance";
    const candidateUserIds = await findCandidateMitraUserIds(req.serviceType, req.providerId);
    for (const mitraUserId of candidateUserIds) {
      await notifyUser({
        userId: mitraUserId,
        type: isEmergency ? "emergency" : "order_new",
        title: isEmergency ? "Pesanan Darurat Baru" : "Pesanan Baru",
        message: `Ada pesanan ${req.serviceType} baru menunggu konfirmasi Anda.`,
        data: { bookingId: created.id, serviceType: created.serviceType },
      });
    }

    return ok(created);
  },
);
