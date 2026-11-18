# Gym Forza Access — Flutter

Android access-control app migrated from Kotlin/Jetpack Compose.

## Features
- Supabase administrator sign-in and persisted-session recovery.
- Backend role validation through GET /auth/me.
- QR scanning with the device camera using mobile_scanner.
- QR validation through POST /qr/validate.
- Authorized/denied result with member name, plan and expiration date.
- Logout and expired-session handling.

API: https://gymforza.onrender.com/

## Run locally (PowerShell)
```powershell
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```
Use only the Supabase Publishable Key. Never commit service_role or secret keys.

## Build APK
```powershell
flutter build apk --release --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```
Output: build/app/outputs/flutter-apk/app-release.apk

The Android application id remains com.gymforza.access. Updating an installed Kotlin app also requires its original signing key. The current release block uses debug signing for development only; configure production signing before distribution.

Run flutter analyze and test on a physical Android device with real Supabase credentials and valid, expired, reused and unknown QR examples.
