# Backend — Encore.ts Microservice API

> **Owner: Dev A**  
> This entire directory is owned by the backend developer.

## Setup

```bash
cd backend
npm install
encore run
```

## Structure (current)

```
backend/
├── encore.app              # Encore app config (id: garudahacks-wtk2, CORS *)
├── package.json            # Node dependencies (encore.dev, bcryptjs, @emailjs/nodejs)
├── tsconfig.json           # TypeScript config (strict, ES2022)
├── docker-compose.yml      # Local dev reference: Postgres + Redis + WAHA
├── shared/response.ts      # Uniform ok()/error envelope + HTTP mapping (doc 01)
├── db/
│   ├── db.ts               # SQLDatabase("carego") instance
│   └── migrations/         # Sequential up-only SQL migrations (1..12)
├── auth/                   # Auth service + auth.ts (authHandler + Gateway) + otp.ts (WAHA/EmailJS)
├── user/                   # User profile & balance
├── ambulance/              # Ambulance recommendations + legacy /ambulance/book
├── caregiver/              # Caregiver catalog + booking
├── rental/                 # Equipment catalog + booking
├── order/                  # Bookings: POST /bookings (authed), list, cancel, state machine, pricing
├── chat/                   # Conversations + messages
├── notification/           # In-app notifications + preferences
├── wallet/                 # Top-up + transactions
├── admin/                  # Admin users, activity logs, recommendations
├── app/                    # App version endpoint
└── utils/logger.ts         # activity_logs helper
```

> Note: only `POST /bookings` currently uses the auth handler (`auth: true` +
> `getAuthData()`). Other endpoints still accept `userId` in the body (TD-05) and
> are pending migration.

## Adding a New Service

1. Create directory: `backend/my_service/`
2. Create `encore.service.ts`:
   ```typescript
   import { Service } from "encore.dev/service";
   export default new Service("my_service");
   ```
3. Create `api.ts` with endpoints using `api()` wrapper
4. Run `encore run` to test locally
5. Update `docs/API_CONTRACT.md`
6. Regenerate `client.ts`: `encore gen client --target leap`
7. Push to feature branch → create PR

## Adding a New Migration

1. Create file: `backend/db/migrations/N_description.up.sql`
2. Update `docs/MIGRATION_LOG.md`
3. Restart `encore run` — migration runs automatically
4. **Never modify existing migration files**
