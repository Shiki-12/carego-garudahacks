import { api } from "encore.dev/api";
import { db } from "../db/db";
import { logActivity } from "../utils/logger";
import bcrypt from "bcryptjs";

export interface AdminUser {
    id: number;
    name: string;
    email: string;
    role: string;
    phone: string | null;
    photo_url: string | null;
    created_at: string;
}

export interface AdminUserResponse {
    users: AdminUser[];
}

export interface ActivityLog {
    id: number;
    user_id: number;
    user_name: string;
    user_role: string;
    action: string;
    detail: string;
    created_at: string;
}

export interface LogsResponse {
    logs: ActivityLog[];
}

export interface CreateUserRequest {
    name: string;
    email: string;
    role: string;
    password?: string;
    phone?: string;
    adminUserId?: number;
}

export interface CreatedUser {
    id: number;
    name: string;
    email: string;
    role: string;
    createdAt: string;
}

export interface CreateRecRequest {
    serviceType: string;
    title: string;
    tagLabel: string;
    tagColor: string;
    price: string;
    image: string;
    rating?: number;
    reviews?: number;
    adminUserId?: number;
}

export interface SuccessResponse {
    success: boolean;
}

export const getUsers = api(
    { expose: true, method: "GET", path: "/admin/users" },
    async (): Promise<AdminUserResponse> => {
        const result = await db.query`
            SELECT id, name, email, role, phone, photo_url, created_at 
            FROM users 
            ORDER BY created_at DESC
        `;
        const users: AdminUser[] = [];
        for await (const row of result) users.push(row as any);
        return { users };
    }
);

export const createUser = api(
    { expose: true, method: "POST", path: "/admin/users" },
    async (req: CreateUserRequest): Promise<CreatedUser> => {
        const hash = req.password ? await bcrypt.hash(req.password, 10) : "";
        const user = await db.queryRow`
            INSERT INTO users (name, email, phone, role, password_hash)
            VALUES (${req.name}, ${req.email}, ${req.phone}, ${req.role}, ${hash})
            RETURNING id, name, email, role, created_at
        `;
        if (!user) throw new Error("Gagal membuat user");

        await db.exec`INSERT INTO wallets (user_id, balance) VALUES (${user.id}, 0)`;

        if (req.adminUserId) {
            await logActivity(req.adminUserId, 'CREATE_USER', `Admin created ${req.role}: ${req.email}`);
        }

        return {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            createdAt: user.created_at
        };
    }
);

export const getLogs = api(
    { expose: true, method: "GET", path: "/admin/activity-logs" },
    async (): Promise<LogsResponse> => {
        const result = await db.query`
            SELECT id, user_id, user_name, user_role, action, detail, created_at 
            FROM activity_logs 
            ORDER BY created_at DESC 
            LIMIT 100
        `;
        const logs: ActivityLog[] = [];
        for await (const row of result) logs.push(row as any);
        return { logs };
    }
);

export const createRecommendation = api(
    { expose: true, method: "POST", path: "/admin/recommendations" },
    async (req: CreateRecRequest): Promise<SuccessResponse> => {
        await db.exec`
            INSERT INTO recommendations (service_type, title, tag_label, tag_color, rating, reviews, price, image, is_active)
            VALUES (${req.serviceType}, ${req.title}, ${req.tagLabel}, ${req.tagColor}, ${req.rating ?? 0}, ${req.reviews ?? 0}, ${req.price}, ${req.image}, TRUE)
        `;
        if (req.adminUserId) {
            await logActivity(req.adminUserId, 'CREATE_RECOMMENDATION', `Admin created recommendation: ${req.title}`);
        }
        return { success: true };
    }
);

export const deleteRecommendation = api(
    { expose: true, method: "DELETE", path: "/admin/recommendations/:id" },
    async (req: { id: number }): Promise<SuccessResponse> => {
        await db.exec`DELETE FROM recommendations WHERE id = ${req.id}`;
        return { success: true };
    }
);
