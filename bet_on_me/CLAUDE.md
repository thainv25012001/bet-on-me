# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**BetOnMe** is a Flutter productivity app that combines AI goal planning, financial accountability (loss-aversion stakes), and streak gamification to help users execute on their goals consistently.

Core concept: Users define a goal → AI breaks it into daily tasks → users stake money daily → completing tasks keeps the stake, failing loses it.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app (choose platform)
flutter run
flutter run -d chrome       # web
flutter run -d windows      # Windows desktop

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build
flutter build apk           # Android
flutter build ios           # iOS
flutter build web           # Web
flutter build windows       # Windows
```

## Architecture

Currently at the Flutter starter template stage (`lib/main.dart` only). The planned architecture based on the product description should grow into:

- **Goal management** – user-defined goals with timeframes
- **AI planning** – breaking goals into structured daily tasks
- **Stake/payment system** – daily financial commitments with loss-aversion mechanics
- **Progress tracking** – streaks, milestones, gamification

`lib/main.dart` is the entry point. As features are added, organize under `lib/` with feature-based or layer-based directories (e.g., `lib/features/`, `lib/services/`, `lib/models/`).

## Tech Stack

- Flutter (Dart SDK `^3.11.1`)
- `flutter_lints` for static analysis (`flutter_lints/flutter.yaml` ruleset)
- Targets: Android, iOS, Web, Windows, macOS, Linux
