import { describe, it } from "vitest";
import assert from "node:assert";
import { register, login } from "./api";

describe("Auth Service", () => {
    it("should successfully register and login a new user via email", async () => {
        const testEmail = `test.auth.${Date.now()}@example.com`;
        
        // 1. Register
        const regRes = await register({
            name: "Auth Test User",
            email: testEmail,
            password: "password123"
        });
        
        assert.ok(regRes.token, "Registration should return a token");
        assert.strictEqual(regRes.user.email, testEmail);
        assert.strictEqual(regRes.user.role, "patient");

        // 2. Login
        const loginRes = await login({
            email: testEmail,
            password: "password123"
        });

        assert.ok(loginRes.token, "Login should return a token");
        assert.strictEqual(loginRes.user.email, testEmail);
    });

    it("should reject login with wrong password", async () => {
        const testEmail = `test.wrongpass.${Date.now()}@example.com`;
        
        await register({
            name: "Wrong Pass User",
            email: testEmail,
            password: "password123"
        });

        try {
            await login({
                email: testEmail,
                password: "wrongpassword"
            });
            assert.fail("Should have thrown an error for wrong password");
        } catch (error: any) {
            assert.ok(error.message.includes("Password salah"), "Error should indicate wrong password");
        }
    });
});
