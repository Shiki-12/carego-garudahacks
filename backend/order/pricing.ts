import { db } from "../db/db";
import { validationError, notFound } from "../shared/response";

// Server-side pricing (docs/production/07 §4.2). The backend is the sole source of
// truth for the final price; any client-supplied amount is ignored.

export type ServiceType = "ambulance" | "caregiver" | "rental";
export type FleetType = "ALS" | "BLS" | "Jenazah";

// Ambulance tariff table (doc 03 §6): base fare + per-km, in integer Rupiah.
const AMBULANCE_TARIFF: Record<FleetType, { baseFare: number; perKm: number }> = {
  ALS: { baseFare: 150000, perKm: 15000 },
  BLS: { baseFare: 100000, perKm: 10000 },
  Jenazah: { baseFare: 200000, perKm: 12000 },
};

// Haversine distance in km. Used as the OSRM fallback (×1.3 road factor per doc 07 §4.2).
function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export interface PriceResult {
  totalPrice: number; // integer Rupiah
  distanceKm: number | null;
}

interface AmbulanceInput {
  fleetType?: FleetType;
  pickupLat?: number;
  pickupLng?: number;
  destLat?: number;
  destLng?: number;
}

export function priceAmbulance(input: AmbulanceInput): PriceResult {
  const fleetType = input.fleetType;
  if (!fleetType || !(fleetType in AMBULANCE_TARIFF)) {
    throw validationError("Tipe armada tidak valid", { field: "fleetType" });
  }
  if (
    input.pickupLat == null ||
    input.pickupLng == null ||
    input.destLat == null ||
    input.destLng == null
  ) {
    throw validationError("Lokasi jemput dan tujuan wajib diisi", { field: "pickup/dest" });
  }

  const rawKm = haversineKm(input.pickupLat, input.pickupLng, input.destLat, input.destLng);
  const distanceKm = Math.round(rawKm * 1.3 * 100) / 100; // road-factor fallback
  const tariff = AMBULANCE_TARIFF[fleetType];
  const totalPrice = tariff.baseFare + tariff.perKm * Math.ceil(distanceKm);
  return { totalPrice, distanceKm };
}

// Rental price = daily_rate × days, or weekly_rate when the span is ≥ 7 days and a
// weekly rate exists. Reads the authoritative rate from the equipment catalog.
export async function priceRental(rentalItemId?: number, rentalDays?: number): Promise<PriceResult> {
  if (!rentalItemId) throw validationError("Item rental wajib dipilih", { field: "rentalItemId" });
  if (!rentalDays || rentalDays < 1) {
    throw validationError("Durasi sewa minimal 1 hari", { field: "rentalDays" });
  }
  const item = await db.queryRow`
    SELECT daily_rate, weekly_rate FROM equipment WHERE id = ${rentalItemId}
  `;
  if (!item) throw notFound("Item rental tidak ditemukan");

  const daily = Number(item.daily_rate);
  const weekly = item.weekly_rate != null ? Number(item.weekly_rate) : null;
  let totalPrice: number;
  if (rentalDays >= 7 && weekly != null) {
    const weeks = Math.floor(rentalDays / 7);
    const remDays = rentalDays % 7;
    totalPrice = weeks * weekly + remDays * daily;
  } else {
    totalPrice = rentalDays * daily;
  }
  return { totalPrice, distanceKm: null };
}

// Caregiver price = hourly_rate × duration_hours from the caregiver profile.
export async function priceCaregiver(caregiverId?: number, durationHours?: number): Promise<PriceResult> {
  if (!caregiverId) throw validationError("Caregiver wajib dipilih", { field: "caregiverId" });
  if (!durationHours || durationHours < 1) {
    throw validationError("Durasi layanan minimal 1 jam", { field: "durationHours" });
  }
  const cg = await db.queryRow`
    SELECT hourly_rate FROM caregiver_profiles WHERE id = ${caregiverId}
  `;
  if (!cg) throw notFound("Caregiver tidak ditemukan");
  const totalPrice = Number(cg.hourly_rate) * durationHours;
  return { totalPrice, distanceKm: null };
}
