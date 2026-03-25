# RiskFlow FX - Production Requirements Document (PRD)

## 1. Product Overview

RiskFlow FX is a lightning-fast, production-grade position sizing and risk management calculator for retail Forex and Prop Firm traders. It bypasses the clunky interfaces of traditional calculators, allowing traders to input their entry/stop-loss, get an accurate lot size, and copy it to their clipboard in under 5 seconds.

## 2. Core Features (MVP for Play Store)

- **Instant Lot Size Calculation**: Formula-driven calculations supporting Forex, Indices, and spot metals (XAUUSD).
- **Smart Exit & Partials**: Pre-calculated R:R configurations (e.g., 50% close at 1R, trailing sl to BE, runner to 1.5R).
- **Live Price Integration**: TwelveData / AlphaVantage fallback architecture.
- **1-Tap MT5 Copy**: One-tap clipboard feature to instantly paste the lot size into MT5.
- **Trade Presets**: Save typical risk setups (e.g., 0.5% scalping, 1% swing).

## 3. Production & State Management (GetX Architecture)

- **GetX Core**: Used for reactive state management (`TradeController`), extremely low-latency UI updates, and dependency injection.
- **Local Storage**: `SharedPreferences` to cache presets, instrument data, and API keys.
- **Services layer**: `PriceService` interface with `TwelveDataPriceService` implementation and `CachedPriceService` proxy.

## 4. Play Store Release Requirements

- **App Icon & Branding**: Configured via `flutter_launcher_icons`.
- **Offline Resiliency**: Calculator must work entirely offline with manual entry if the WebSocket/REST API fails.
- **Performance**: 60fps (120fps on supported devices) UI using standard Flutter Material 3 widgets avoiding deep widget trees.
- **Analytics / Crashlytics**: (V1.1) Firebase integrated for bug tracking.

## 5. UI/UX Flow

1. **Home Screen**: Dropdown for Instrument.
2. **Inputs**: Account Balance, Risk %, Entry Price, Stop Loss Price.
3. **Outputs**: Giant, bold LOT SIZE text.
4. **Action**: "Copy to Clipboard" button.
5. **Expandable Panel**: "Smart Exits" showing TP1 and TP2 outputs.
