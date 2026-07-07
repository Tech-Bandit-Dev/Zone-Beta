# Zone Frontend (Flutter)

Map-first UI for Zone. Runs standalone with a built-in placeholder map, and
talks to the NestJS backend for auth, signals, and matching.

## Run

```bash
flutter pub get
flutter run
```

The app launches on the landing page → sign up / log in → OTP → map.

> **Backend URL:** `ApiService` (`lib/services/api_service.dart`) picks a
> default automatically — Android emulator gets `http://10.0.2.2:3000/api`,
> everything else (iOS simulator, web, desktop) gets `http://localhost:3000/api`.
>
> A **physical device** (Android or iOS) can't reach either of those — it
> needs your machine's LAN IP, which can't be auto-detected. Pass it at
> launch, with your phone and machine on the same Wi-Fi:
> ```bash
> flutter run --dart-define=API_BASE_URL=http://<your-LAN-ip>:3000/api
> ```
> Find your LAN IP with `ipconfig getifaddr en0` (Mac) or `ipconfig` (Windows).

## Works offline / without backend

Every network call has a fallback, so the UI is fully clickable even if the
backend isn't running: OTP accepts any 6 digits, creating a signal drops a
local pin, and KYC upgrades locally. Start the backend to get real seeded
signals and persistence.

Google Sign-In is the one exception — it always needs the backend (to verify
the token) and always needs its OAuth client configured (see below), even in
dev.

## Structure

```
lib/
  main.dart                     # root; routes on auth state
  theme/app_theme.dart          # Shuttle Gray palette + ThemeData
  models/signal.dart            # Signal + UserProfile models
  services/api_service.dart     # HTTP client for the backend
  state/app_state.dart          # Riverpod providers (auth, signals)
  config/google_auth_config.dart # Google Sign-In serverClientId (dart-define)
  screens/
    landing_screen.dart         # pre-auth home
    auth_screen.dart            # phone entry (login + signup)
    otp_screen.dart             # 6-box OTP
    map_screen.dart             # THE core screen
    create_signal_screen.dart   # compose + broadcast
    chat_screen.dart            # post-accept coordination (mock)
    profile_screen.dart         # profile, KYC, logout
  widgets/
    map_placeholder.dart        # dependency-free map w/ rings + pins
    signal_bottom_sheet.dart    # tap-a-pin detail + Accept
```

## Switching to real Google Maps

The app ships with `MapPlaceholder` (a custom-painted map) so it runs with no
API key. To use real maps:

1. Get a Google Maps API key (Maps SDK for Android + iOS).
2. Android: add the key to `android/app/src/main/AndroidManifest.xml`.
   iOS: add it in `ios/Runner/AppDelegate.swift`.
3. In `lib/screens/map_screen.dart`, replace the `MapPlaceholder` widget with
   a `GoogleMap` widget. Feed the same `signals` list in as `Marker`s and draw
   `Circle`s for the radius rings. Everything else (chips, bottom sheet, create
   flow) stays unchanged.

## Design system

Warm off-white base (`#F4F2EC` paper, `#EDEBE4` map) with a single terracotta
accent `#D38A66` for primary actions. Blue `#5E8FD0` is reserved for the map's
"you are here" dot only — nothing else uses it. Change `ZoneColors.primary` /
`primaryDark` in `theme/app_theme.dart` to retheme the whole app. Signal
categories (sell, housing, event, community, help) each have an accent color
plus a matching pale background tint (`ZoneColors.<category>Tint`) used
behind icons on cards and chips.

## Google Sign-In setup

The "Continue with Google" button is fully wired (frontend `google_sign_in`
flow → backend verifies the ID token via `google-auth-library`) but needs
your own OAuth client — Google ties credentials to a Google account, so
these can't be pre-filled.

1. **Create/select a project** at [console.cloud.google.com](https://console.cloud.google.com).
2. **Configure the OAuth consent screen** (APIs & Services → OAuth consent
   screen): External, add an app name + support email, add the `email` and
   `profile` scopes.
3. **Create credentials** (APIs & Services → Credentials → Create Credentials
   → OAuth client ID) — you need two client IDs, both in the *same* project:
   - **Web application** — no redirect URIs needed. This is the one that
     matters: its client ID is the `serverClientId` that makes Google return
     an ID token the backend can verify. Copy it.
   - **Android** — package name `com.example.zone`, SHA-1 of your debug
     signing key:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore \
       -alias androiddebugkey -storepass android -keypass android
     ```
     (On macOS, if `keytool` isn't on your PATH, it ships inside Android
     Studio's bundled JDK, e.g.
     `/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool`.)
     You'll need a **separate** Android client ID + SHA-1 registered for your
     release keystore before shipping.
4. **Set the Web client ID in both places:**
   - Backend: `backend/.env` → `GOOGLE_CLIENT_ID=<web-client-id>.apps.googleusercontent.com`
   - Frontend: pass it at launch (never hardcode it in source):
     ```bash
     flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
     ```
5. **Emulator note:** Google Sign-In needs Google Play Services. Use an AVD
   with a **"Google Play"** system image (not the plain "Google APIs" image,
   and not one of the base AOSP images) — check under the AVD's target name
   in Android Studio's device manager.

Until this is configured, the button shows a clear inline error telling you
what's missing instead of failing silently — that's expected, not a bug.

## Next milestones

- Live updates via `socket_io_client` (connect to the realtime gateway, listen
  for `signal:created` / `signal:updated`).
- Real device geolocation (replace the fixed `_center` in `map_screen.dart`).
- KYC provider flow behind the profile "Verify" button.
