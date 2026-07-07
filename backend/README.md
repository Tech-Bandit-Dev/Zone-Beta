# Zone Backend (NestJS)

Modular monolith. Each folder under `src/` is a feature module that can later
be extracted into its own microservice:

| Module      | Responsibility                                    |
|-------------|---------------------------------------------------|
| `auth`      | Phone OTP login/signup, JWT issue + guard         |
| `identity`  | User profile, KYC verification tier               |
| `signal`    | Create/list signals (the core primitive), seeds   |
| `geo`       | Radius / proximity queries (haversine for now)    |
| `realtime`  | WebSocket gateway, live signal fan-out            |
| `matching`  | Accept flow                                       |
| `common`    | Shared types + in-memory store (swap for DB)      |

## Run

```bash
cp .env.example .env
npm install
npm run start:dev
```

API is served at `http://localhost:3000/api`. WebSocket on the same port.

## Mock mode

`OTP_MOCK_MODE=true` (default): OTP request returns a `devCode`, and **any
6-digit code** verifies. No SMS provider needed to test the full flow.

## Google Sign-In

`POST /api/auth/google` verifies the ID token from the frontend against
Google (via `google-auth-library`) using `GOOGLE_CLIENT_ID` (the **Web**
OAuth client ID — see `frontend/README.md` "Google Sign-In setup" for how to
get one). Unset `GOOGLE_CLIENT_ID` → the endpoint returns 401 with a message
saying so, rather than a confusing crash. Matches an existing account by
`googleId`, then by `email`, so a phone-signup user linking Google later
merges into the same account instead of creating a duplicate.

## Endpoints

| Method | Path                     | Auth | Purpose                        |
|--------|--------------------------|------|--------------------------------|
| POST   | `/api/auth/request-otp`  | no   | Start signup/login             |
| POST   | `/api/auth/verify-otp`   | no   | Verify → `{ token, user }`     |
| POST   | `/api/auth/google`       | no   | Verify Google ID token → `{ token, user }` |
| GET    | `/api/me`                | yes  | Current profile                |
| PATCH  | `/api/me/name`           | yes  | Update name                    |
| POST   | `/api/me/kyc`            | yes  | Mock KYC upgrade               |
| GET    | `/api/signals/nearby`    | no   | `?lat=&lng=&range=`            |
| POST   | `/api/signals`           | yes  | Create a signal                |
| POST   | `/api/signals/:id/accept`| yes  | Accept a signal                |

## WebSocket events

- client → `locate` `{ lat, lng, range }` → server → `signals:snapshot`
- server → `signal:created`, `signal:updated`

## Next steps (production)

- Replace `common/in-memory.store.ts` with PostgreSQL + PostGIS (signals,
  users) and Redis (hot geo-index + pub/sub for realtime fan-out).
- Real SMS OTP (Twilio / MSG91) in `auth.service.ts`.
- Real KYC provider (Signzy / HyperVerge / DigiLocker) in `identity.service.ts`.
- Per-socket geo-scoped fan-out in `realtime.gateway.ts`.
