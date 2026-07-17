import { describe, it, vi } from "vitest";
import assert from "node:assert";
import { db } from "../db/db";

// The endpoints now resolve identity from the verified session (getAuthData),
// so we stub it per-test instead of trusting a body userId (TD-05).
let testUserId = 0;
vi.mock("~encore/auth", () => ({
    getAuthData: () => ({ userID: String(testUserId), role: "patient", scopes: ["patient"] }),
}));

const { balance, updateProfile } = await import("./api");

describe("User Service", () => {
    it("should fetch user balance and update profile", async () => {
        // Create a test user with a wallet
        const user = await db.queryRow`
            INSERT INTO users (name, email, password_hash, role)
            VALUES ('Test User', 'test.user@example.com', 'hash', 'patient')
            RETURNING id
        `;
        assert.ok(user, "User should be created");
        const userId = user.id;
        testUserId = userId;

        await db.exec`INSERT INTO wallets (user_id, balance) VALUES (${userId}, 500000)`;

        // Test balance
        const balanceRes = await balance({});
        assert.strictEqual(balanceRes.balance, 500000);

        // Test updateProfile
        const updateRes = await updateProfile({
            phone: "08123456789",
            photoBase64: "base64data"
        });
        assert.strictEqual(updateRes.success, true);

        // Verify database state
        const updatedUser = await db.queryRow`SELECT phone, photo_url FROM users WHERE id = ${userId}`;
        assert.strictEqual(updatedUser?.phone, "08123456789");
        assert.strictEqual(updatedUser?.photo_url, "base64data");
    });
});
