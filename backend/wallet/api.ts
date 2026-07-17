import { api, APIError } from "encore.dev/api";
import { getAuthData } from "~encore/auth";
import { db } from "../db/db";
import { logActivity } from "../utils/logger";

// Caller identity comes from the verified session (getAuthData), never the body (TD-05).
function currentUserId(): number {
    return Number(getAuthData()!.userID);
}

// --- Interfaces ---

export interface TopUpRequest {
    amount: number;
}

export interface Transaction {
    id: number;
    title: string;
    amount: number;
    isCredit: boolean;
    date: string;
}

export interface TopUpResponse {
    success: boolean;
    wallet: {
        userId: number;
        balance: number;
        updatedAt: string;
    };
    transaction: Transaction;
}

export interface TransactionsResponse {
    balance: number;
    transactions: Transaction[];
    total: number;
}

// --- Endpoints ---

export const topup = api(
    { expose: true, auth: true, method: "POST", path: "/wallet/topup" },
    async (req: TopUpRequest): Promise<TopUpResponse> => {
        const userId = currentUserId();
        if (req.amount === undefined) {
            throw APIError.invalidArgument("amount wajib diisi");
        }
        if (req.amount <= 0) {
            throw APIError.invalidArgument("Jumlah top up harus lebih dari 0");
        }

        const tx = await db.begin();
        let wallet: any;
        let transaction: any;
        try {
            wallet = await tx.queryRow`
                UPDATE wallets SET balance = balance + ${req.amount}, updated_at = NOW()
                WHERE user_id = ${userId}
                RETURNING id, user_id, balance, updated_at
            `;
            if (!wallet) throw APIError.notFound("Wallet tidak ditemukan");

            transaction = await tx.queryRow`
                INSERT INTO transactions (wallet_id, title, amount, is_credit, balance_after, reference_type)
                VALUES (${wallet.id}, 'Top Up Saldo', ${req.amount}, TRUE, ${wallet.balance}, 'topup')
                RETURNING id, title, amount, is_credit, created_at
            `;
            await tx.commit();
        } catch (err) {
            await tx.rollback();
            throw err;
        }

        await logActivity(userId, 'WALLET_TOPUP', `Top up Rp ${req.amount}`);

        return {
            success: true,
            wallet: {
                userId: wallet.user_id,
                balance: wallet.balance,
                updatedAt: wallet.updated_at,
            },
            transaction: {
                id: transaction.id,
                title: transaction.title,
                amount: transaction.amount,
                isCredit: transaction.is_credit,
                date: transaction.created_at,
            },
        };
    }
);

// GET /wallet/transactions
export const transactions = api(
    { expose: true, auth: true, method: "GET", path: "/wallet/transactions" },
    async ({ limit, offset }: { limit?: number; offset?: number }): Promise<TransactionsResponse> => {
        const userId = currentUserId();
        const wallet = await db.queryRow`SELECT id, balance FROM wallets WHERE user_id = ${userId}`;
        if (!wallet) throw APIError.notFound("Wallet tidak ditemukan");

        const result = await db.query`
            SELECT id, title, amount, is_credit, created_at
            FROM transactions
            WHERE wallet_id = ${wallet.id}
            ORDER BY created_at DESC
            LIMIT ${limit ?? 50} OFFSET ${offset ?? 0}
        `;
        const list: Transaction[] = [];
        for await (const row of result) {
            list.push({
                id: row.id,
                title: row.title,
                amount: row.amount,
                isCredit: row.is_credit,
                date: row.created_at,
            });
        }

        return { balance: wallet.balance, transactions: list, total: list.length };
    }
);
