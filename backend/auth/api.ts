import { api, APIError } from "encore.dev/api";
import { db } from "../db/db";
import { logActivity } from "../utils/logger";
import { dispatchOtp } from "./otp";
import bcrypt from "bcryptjs";
import crypto from "crypto";

// --- Interfaces ---

export interface User {
    id: number;
    name: string;
    email: string;
    role: string;
    phone: string | null;
    photo_url: string | null;
}

export interface AuthResponse {
    token: string;
    user: User;
}

export interface SuccessResponse {
    success: boolean;
    message?: string;
}

// --- Helpers ---

const generateToken = (): string => crypto.randomBytes(32).toString('hex');
const generateOTP = (): string => Math.floor(100000 + Math.random() * 900000).toString();

async function createSession(userId: number): Promise<string> {
    const token = generateToken();
    await db.exec`
        INSERT INTO sessions (user_id, token, created_at, expires_at)
        VALUES (${userId}, ${token}, NOW(), NOW() + INTERVAL '7 days')
    `;
    return token;
}

// --- Endpoints ---

export const register = api(
    { expose: true, method: "POST", path: "/auth/register" },
    async (req: { name: string; email: string; password?: string }): Promise<AuthResponse> => {
        const existing = await db.queryRow`SELECT id FROM users WHERE email = ${req.email}`;
        if (existing) {
            throw new Error("Email sudah terdaftar");
        }

        const hash = req.password ? await bcrypt.hash(req.password, 10) : "";
        const user = await db.queryRow`
            INSERT INTO users (name, email, password_hash, role)
            VALUES (${req.name}, ${req.email}, ${hash}, 'patient')
            RETURNING id, name, email, role, phone, photo_url
        `;

        if (!user) throw new Error("Gagal membuat akun");

        // Initialize wallet
        await db.exec`INSERT INTO wallets (user_id, balance) VALUES (${user.id}, 0)`;

        const token = await createSession(user.id);
        await logActivity(user.id, 'REGISTER', 'Direct registration');

        return {
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                phone: user.phone,
                photo_url: user.photo_url
            }
        };
    }
);

export const registerSendOtp = api(
    { expose: true, method: "POST", path: "/auth/register-send-otp" },
    async (req: { email: string; phone: string; method: string }): Promise<SuccessResponse> => {
        const existingEmail = await db.queryRow`SELECT id FROM users WHERE email = ${req.email}`;
        if (existingEmail) throw APIError.alreadyExists("Email sudah terdaftar");

        if (req.phone) {
            const existingPhone = await db.queryRow`SELECT id FROM users WHERE phone = ${req.phone}`;
            if (existingPhone) throw APIError.alreadyExists("Nomor WhatsApp sudah terdaftar");
        }

        const otp = generateOTP();
        await db.exec`
            INSERT INTO otp_codes (identifier, code, method, created_at, expires_at)
            VALUES (${req.phone || req.email}, ${otp}, ${req.method}, NOW(), NOW() + INTERVAL '5 minutes')
        `;
        // Dispatch OTP via Email or WAHA
        await dispatchOtp(req.phone || req.email, req.method, otp);

        return { success: true, message: `OTP pendaftaran telah dikirim via ${req.method}` };
    }
);

export const registerVerifyOtp = api(
    { expose: true, method: "POST", path: "/auth/register-verify-otp" },
    async (req: { name: string; email: string; phone: string; password?: string; code: string }): Promise<AuthResponse> => {
        const otpRecord = await db.queryRow`
            SELECT id FROM otp_codes 
            WHERE identifier = ${req.phone || req.email} AND code = ${req.code} AND expires_at > NOW()
        `;
        if (!otpRecord) throw APIError.invalidArgument("Kode OTP salah atau sudah kedaluwarsa");

        await db.exec`DELETE FROM otp_codes WHERE id = ${otpRecord.id}`;

        const existing = await db.queryRow`SELECT id FROM users WHERE email = ${req.email}`;
        if (existing) throw APIError.alreadyExists("Email sudah terdaftar");

        const hash = req.password ? await bcrypt.hash(req.password, 10) : "";
        const user = await db.queryRow`
            INSERT INTO users (name, email, phone, password_hash, role)
            VALUES (${req.name}, ${req.email}, ${req.phone}, ${hash}, 'patient')
            RETURNING id, name, email, role, phone, photo_url
        `;

        if (!user) throw new Error("Gagal membuat akun");

        await db.exec`INSERT INTO wallets (user_id, balance) VALUES (${user.id}, 0)`;
        const token = await createSession(user.id);
        await logActivity(user.id, 'REGISTER', 'OTP registration');

        return {
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                phone: user.phone,
                photo_url: user.photo_url
            }
        };
    }
);

export const login = api(
    { expose: true, method: "POST", path: "/auth/login" },
    async (req: { email: string; password?: string }): Promise<AuthResponse> => {
        const user = await db.queryRow`SELECT * FROM users WHERE email = ${req.email}`;
        if (!user) throw new Error("Email tidak ditemukan");

        if (req.password) {
            const isValid = await bcrypt.compare(req.password, user.password_hash);
            if (!isValid) throw new Error("Password salah");
        } else if (user.password_hash) {
           throw new Error("Password dibutuhkan");
        }

        const token = await createSession(user.id);
        await logActivity(user.id, 'LOGIN', 'Email login');

        return {
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                phone: user.phone,
                photo_url: user.photo_url
            }
        };
    }
);

export const sendOtp = api(
    { expose: true, method: "POST", path: "/auth/send-otp" },
    async (req: { identifier: string; method: string }): Promise<SuccessResponse> => {
        const otp = generateOTP();
        await db.exec`
            INSERT INTO otp_codes (identifier, code, method, created_at, expires_at)
            VALUES (${req.identifier}, ${otp}, ${req.method}, NOW(), NOW() + INTERVAL '5 minutes')
        `;
        await dispatchOtp(req.identifier, req.method, otp);
        return { success: true, message: `OTP telah dikirim via ${req.method}` };
    }
);

export const verifyOtp = api(
    { expose: true, method: "POST", path: "/auth/verify-otp" },
    async (req: { identifier: string; code: string }): Promise<AuthResponse> => {
        const otpRecord = await db.queryRow`
            SELECT id FROM otp_codes 
            WHERE identifier = ${req.identifier} AND code = ${req.code} AND expires_at > NOW()
        `;
        if (!otpRecord) throw new Error("Kode OTP salah atau sudah kedaluwarsa");
        await db.exec`DELETE FROM otp_codes WHERE id = ${otpRecord.id}`;

        let user = await db.queryRow`SELECT * FROM users WHERE email = ${req.identifier} OR phone = ${req.identifier}`;
        
        if (!user) {
            // Auto create if not exists
            user = await db.queryRow`
                INSERT INTO users (name, email, phone, role)
                VALUES ('User', ${req.identifier}, ${req.identifier}, 'patient')
                RETURNING id, name, email, role, phone, photo_url
            `;
            if (user) {
                await db.exec`INSERT INTO wallets (user_id, balance) VALUES (${user.id}, 0)`;
                await logActivity(user.id, 'REGISTER', 'Auto-created via OTP');
            }
        }

        if (!user) throw new Error("Gagal verifikasi pengguna");

        const token = await createSession(user.id);
        await logActivity(user.id, 'LOGIN', 'OTP login');

        return {
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                phone: user.phone,
                photo_url: user.photo_url
            }
        };
    }
);

export const google = api(
    { expose: true, method: "POST", path: "/auth/google" },
    async (req: { googleId: string; email: string; name: string }): Promise<AuthResponse> => {
        let user = await db.queryRow`SELECT * FROM users WHERE google_id = ${req.googleId} OR email = ${req.email}`;
        
        if (!user) {
            user = await db.queryRow`
                INSERT INTO users (name, email, google_id, role)
                VALUES (${req.name}, ${req.email}, ${req.googleId}, 'patient')
                RETURNING id, name, email, role, phone, photo_url
            `;
            if (user) {
                await db.exec`INSERT INTO wallets (user_id, balance) VALUES (${user.id}, 0)`;
                await logActivity(user.id, 'REGISTER', 'Google OAuth');
            }
        } else if (!user.google_id) {
            // Link google account to existing email account
            await db.exec`UPDATE users SET google_id = ${req.googleId} WHERE id = ${user.id}`;
        }

        if (!user) throw new Error("Gagal login dengan Google");

        const token = await createSession(user.id);
        await logActivity(user.id, 'LOGIN', 'Google login');

        return {
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                phone: user.phone,
                photo_url: user.photo_url
            }
        };
    }
);

export const me = api(
    { expose: true, method: "POST", path: "/auth/me" },
    async (req: { token: string }): Promise<User> => {
        const session = await db.queryRow`
            SELECT user_id FROM sessions 
            WHERE token = ${req.token} AND expires_at > NOW()
        `;
        if (!session) throw new Error("Session tidak valid atau sudah expired");

        const user = await db.queryRow`SELECT id, name, email, role, phone, photo_url FROM users WHERE id = ${session.user_id}`;
        if (!user) throw new Error("Pengguna tidak ditemukan");

        return {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            phone: user.phone,
            photo_url: user.photo_url
        };
    }
);

export const logout = api(
    { expose: true, method: "POST", path: "/auth/logout" },
    async (req: { token: string }): Promise<SuccessResponse> => {
        const session = await db.queryRow`SELECT user_id FROM sessions WHERE token = ${req.token}`;
        if (session) {
            const user = await db.queryRow`SELECT name, role FROM users WHERE id = ${session.user_id}`;
            if (user) {
                await logActivity(session.user_id, 'LOGOUT', '');
            }
            await db.exec`DELETE FROM sessions WHERE token = ${req.token}`;
        }
        return { success: true };
    }
);
