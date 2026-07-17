import { api } from "encore.dev/api";
import { getAuthData } from "~encore/auth";
import { db } from "../db/db";
import { logActivity } from "../utils/logger";

// Caller identity comes from the verified session (getAuthData), never the body (TD-05).
function currentUserId(): number {
    return Number(getAuthData()!.userID);
}

export interface BalanceRequest {
}

export interface BalanceResponse {
    balance: number;
}

export interface UpdateProfileRequest {
    phone?: string;
    photoBase64?: string;
}

export interface SuccessResponse {
    success: boolean;
    message?: string;
}

export const balance = api(
    { expose: true, auth: true, method: "POST", path: "/user/balance" },
    async (_req: BalanceRequest): Promise<BalanceResponse> => {
        const userId = currentUserId();
        const wallet = await db.queryRow`SELECT balance FROM wallets WHERE user_id = ${userId}`;
        if (!wallet) throw new Error("Wallet tidak ditemukan");
        return { balance: wallet.balance };
    }
);

export const updateProfile = api(
    { expose: true, auth: true, method: "POST", path: "/user/profile/update" },
    async (req: UpdateProfileRequest): Promise<SuccessResponse> => {
        const userId = currentUserId();
        const userExists = await db.queryRow`SELECT id FROM users WHERE id = ${userId}`;
        if (!userExists) throw new Error("User tidak ditemukan");

        if (req.phone && req.photoBase64) {
            await db.exec`UPDATE users SET phone = ${req.phone}, photo_url = ${req.photoBase64} WHERE id = ${userId}`;
        } else if (req.phone) {
            await db.exec`UPDATE users SET phone = ${req.phone} WHERE id = ${userId}`;
        } else if (req.photoBase64) {
            await db.exec`UPDATE users SET photo_url = ${req.photoBase64} WHERE id = ${userId}`;
        }
        
        await logActivity(userId, 'UPDATE_PROFILE', 'User updated profile');
        
        return { success: true };
    }
);
