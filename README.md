# RiskFlow FX

<p align="left">
	<img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
	<img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" />
	<img src="https://img.shields.io/badge/State%20Management-GetX-6A1B9A" alt="GetX" />
	<img src="https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-2E7D32" alt="Platforms" />
	<img src="https://img.shields.io/badge/Status-Production--Ready%20MVP-1E8E3E" alt="Status" />
</p>

RiskFlow FX is a professional mobile risk-management application for FX/CFD traders.
It helps traders calculate position size, risk exposure, and target planning quickly with a clean mobile workflow.

## Product Overview

RiskFlow FX focuses on practical pre-trade execution:

- Position sizing from account balance, risk %, entry, and stop-loss
- Simple mode and partial take-profit mode
- Live price fetch with provider selection and fallback strategy
- Instrument catalog across Forex, Metals, Indices, and Crypto
- Favorites, draft persistence, and API configuration in-app

## Core Features

### Risk & Trade Planning

- Lot size calculation using configurable risk percentage
- SL distance and TP price calculation
- Partial exits with TP1/TP2 planning and blended profit estimate
- One-tap copy actions for lot values

### Market Data

- Primary provider: TwelveData (API key required)
- Secondary provider: Yahoo Finance (no key required)
- Automatic fallback when primary quote fetch fails
- Local cache support through service wrapper

### Mobile UX

- Responsive layout tuned for full-screen, split-screen, and compact windows
- Keyboard-safe interaction model for form inputs
- Flat, consistent visual system and custom branding
- Persisted user state across app restarts

## Architecture

The project uses a feature-driven Flutter structure with clear separation between UI, controller logic, domain calculation, and services.

```text
lib/
	core/
		constants/
		theme/
	features/
		risk/
			controllers/
			domain/
			models/
			services/
			ui/pages/
	main.dart
```

### Design Decisions

- GetX for reactive state and dependency injection
- Service abstraction for quote providers
- SharedPreferences-based local persistence for settings/drafts
- Domain calculator isolated from UI widgets

## Technology Stack

<p align="left">
	<img src="https://skillicons.dev/icons?i=flutter,dart,androidstudio,vscode,git,github" alt="Tech stack" />
</p>

- Flutter, Dart
- GetX
- Dio
- Shared Preferences
- Google Fonts
- package_info_plus

## Getting Started

### Prerequisites

- Flutter SDK (3.x)
- Dart SDK (bundled with Flutter)
- Android Studio / Xcode toolchains
- Connected emulator or physical device

### Install & Run

```bash
flutter pub get
flutter run
```

### Build Release APK

```bash
flutter build apk --release
```

Generated artifact:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## API Configuration

Open Menu > API Configuration inside the app:

- Select quote provider (TwelveData or Yahoo Finance)
- Add or clear TwelveData API key
- Save and refresh quote

## Android Release & Play Store Workflow

1. Create an upload keystore

```bash
keytool -genkey -v \
	-keystore ~/riskflow-upload-keystore.jks \
	-keyalg RSA -keysize 2048 -validity 10000 \
	-alias upload
```

2. Create `android/key.properties` from `android/key.properties.example`

3. Build App Bundle for Play Console

```bash
flutter build appbundle --release
```

4. Upload:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Branding & Icons

Launcher icons are generated from a single source:

- `assets/branding/app_icon.png`
- `assets/branding/app_icon_foreground.png`

Regenerate icons:

```bash
flutter pub run flutter_launcher_icons
```

Play listing icon output:

- `assets/branding/play_store_icon_512.png`

## Disclaimer

RiskFlow FX is an educational and decision-support tool.
It does not provide financial advice.
