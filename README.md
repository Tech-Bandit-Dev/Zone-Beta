# Zone — The Last Minute

Hyperlocal, real-time "post &amp; match" app. Users broadcast time-boxed
**Signals** (a cab to share, an errand, a handoff) scoped to a **radius**. Only
people physically within that radius see the signal on a live, Google-Maps-style
home screen.

```
zone/
  frontend/   Flutter app (map-first UI, Shuttle Gray theme)
  backend/    NestJS API (modular, microservice-ready) + WebSocket
```

## Quick start

Two terminals.

**1. Backend**
```bash
cd backend
cp .env.example .env
npm install
npm run start:dev        # http://localhost:3000/api
```

**2. Frontend**
```bash
cd frontend
flutter pub get
flutter run
```

Set the backend URL for your target in `frontend/lib/services/api_service.dart`
(Android emulator uses `10.0.2.2`, everything else `localhost`).

## The core primitive

Everything is a **Signal**: a geo-tagged, time-boxed, radius-scoped post.
Ride / errand / handoff are just a `type` field. This keeps both the API and
the UI simple — one create flow, one pin type, many use cases.

## How the two sides map

| Screen (frontend)      | Talks to (backend module)          |
|------------------------|------------------------------------|
| Landing / Auth / OTP   | `auth` (OTP + JWT)                 |
| Map (home)             | `signal` + `geo` (nearby query)   |
| Create signal          | `signal`                          |
| Accept + chat          | `matching` (+ realtime)           |
| Profile / KYC          | `identity`                        |

## Mock-first

Both sides run without real infra:
- Backend uses an in-memory store and mock OTP (any 6 digits) + mock KYC, and
  seeds a few demo signals near a Delhi metro station.
- Frontend has offline fallbacks so the UI is fully clickable even if the
  backend is down.

This lets you build and demo the whole flow now, then swap in real pieces
(Postgres + PostGIS, Redis, SMS OTP, KYC provider, Google Maps key) one at a
time. See each side's README for the exact swap points.

## Working in Claude Code (VS Code)

Open the `zone/` folder as your workspace. Suggested next tasks:
1. Run both sides and confirm the login → map → create → accept loop.
2. Add a Google Maps API key and swap `MapPlaceholder` for `GoogleMap`.
3. Wire `socket_io_client` to the realtime gateway for live pins.
4. Replace the in-memory store with Postgres + PostGIS.
