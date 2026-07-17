import { db } from "../db/db";

export async function logActivity(userId: number, action: string, detail: string) {
    try {
        await db.exec`
            INSERT INTO activity_logs (user_id, user_name, user_role, action, detail)
            SELECT id, name, role, ${action}, ${detail} FROM users WHERE id = ${userId}
        `;
    } catch (error) {
        console.error("Failed to log activity:", error);
    }
}
