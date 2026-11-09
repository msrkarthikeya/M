# AI Hub (Flutter) - review build
Run:
1. `flutter create --org com.yourname --project-name ai_hub .`  (generates android/)
2. Keep this folder's `lib/` and `pubspec.yaml` (overwrite the generated ones)
3. `flutter pub get && flutter run`
Release builds: add `<uses-permission android:name="android.permission.INTERNET"/>` to android/app/src/main/AndroidManifest.xml.
Later: bundle the Outfit font as an asset (google_fonts downloads it at runtime now).

Not connected yet (by design): billing, real API. Everything goes through `lib/api.dart`:
`gateway` (MockGateway -> swap for MeshGateway behind your backend) and `wallet` (credits).
Tips: long-press the "AI Hub" logo = lite effects (for slow phones). Tap the credit ring = demo refill.
