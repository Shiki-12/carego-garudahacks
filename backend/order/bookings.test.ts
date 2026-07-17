import { describe, it } from "vitest";
import assert from "node:assert";
import { assertTransition } from "./state";
import { priceAmbulance } from "./pricing";

describe("Booking state machine", () => {
  it("allows pending → accepted", () => {
    assert.doesNotThrow(() => assertTransition("pending", "accepted"));
  });

  it("rejects completed → cancelled", () => {
    assert.throws(() => assertTransition("completed", "cancelled"), /Transisi status tidak valid/);
  });

  it("rejects pending → completed (skipping states)", () => {
    assert.throws(() => assertTransition("pending", "completed"));
  });
});

describe("Ambulance pricing", () => {
  const jakarta = { pickupLat: -6.2, pickupLng: 106.816, destLat: -6.3, destLng: 106.9 };

  it("computes ALS = baseFare + perKm × ceil(distance)", () => {
    const res = priceAmbulance({ fleetType: "ALS", ...jakarta });
    assert.ok(res.distanceKm !== null && res.distanceKm > 0);
    // total must equal 150000 + 15000 × ceil(distanceKm)
    const expected = 150000 + 15000 * Math.ceil(res.distanceKm!);
    assert.strictEqual(res.totalPrice, expected);
  });

  it("prices BLS cheaper than ALS for the same trip", () => {
    const als = priceAmbulance({ fleetType: "ALS", ...jakarta });
    const bls = priceAmbulance({ fleetType: "BLS", ...jakarta });
    assert.ok(bls.totalPrice < als.totalPrice);
  });

  it("rejects missing fleetType", () => {
    assert.throws(() => priceAmbulance({ ...jakarta } as never), /Tipe armada tidak valid/);
  });

  it("rejects missing coordinates", () => {
    assert.throws(() => priceAmbulance({ fleetType: "ALS" }), /Lokasi jemput dan tujuan/);
  });
});
