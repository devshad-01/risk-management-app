# RiskFlow FX

RiskFlow FX is a Flutter-based forex risk manager and lot size calculator.

## Live Price Providers

- Default provider: `TwelveData`
- Automatic fallback: `Yahoo Finance`
- `Yahoo Finance` does not require an API key in this app.
- `TwelveData` requires a key and can be set in app: Menu > API Configuration.

## Running Locally

```bash
flutter pub get
flutter run
```

## Play Store Release (Android)

1. Create upload keystore:

```bash
keytool -genkey -v -keystore ~/riskflow-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties` from `android/key.properties.example` and fill real values.

3. Build release app bundle:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

4. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

## Security Note

Do not ship your personal `TwelveData` key inside release builds. Prefer user-provided keys or move price requests to your backend.
