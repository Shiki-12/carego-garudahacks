import { Header, Gateway } from "encore.dev/api";
import { authHandler } from "encore.dev/auth";
import { db } from "../db/db";
import { unauthenticated } from "../shared/response";

// Verified caller identity resolved from the session token (docs/production/01 §5,
// doc 02 §6). Endpoints read this via getAuthData() and must NEVER trust a userId
// or role supplied in the request body (TD-05).

interface AuthParams {
  authorization: Header<"Authorization">; // "Bearer <token>"
}

export interface AuthData {
  userID: string; // Encore requires userID to be a string
  role: string; // 'patient' | 'provider' | 'admin'
  providerId?: number; // set when the user is a mitra/provider
  providerType?: string; // 'ambulance' | 'caregiver' | 'rental'
  scopes: string[]; // e.g. ['patient'] or ['provider:ambulance']
}

export const auth = authHandler<AuthParams, AuthData>(async (params) => {
  const token = (params.authorization ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!token) throw unauthenticated("Sesi tidak valid atau sudah kedaluwarsa");

  const row = await db.queryRow`
    SELECT u.id, u.role, p.id AS provider_id, p.service_type
    FROM sessions s
    JOIN users u ON u.id = s.user_id
    LEFT JOIN providers p ON p.user_id = u.id
    WHERE s.token = ${token} AND s.expires_at > NOW()
  `;
  if (!row) throw unauthenticated("Sesi tidak valid atau sudah kedaluwarsa");

  const providerType = row.service_type ? String(row.service_type) : undefined;
  const scopes = providerType ? [`provider:${providerType}`] : [String(row.role)];

  return {
    userID: String(row.id),
    role: String(row.role),
    providerId: row.provider_id ? Number(row.provider_id) : undefined,
    providerType,
    scopes,
  };
});

// Registers the auth handler so endpoints declared with `auth: true` are gated.
export const gateway = new Gateway({ authHandler: auth });
