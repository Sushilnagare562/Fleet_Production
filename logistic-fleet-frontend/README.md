# Logistic Fleet Driver — Flutter App (Android, iOS, Web)

Multi-platform driver app: trips, routes, dock-in/out, expenses, earnings.
Talks to the Logistic Fleet Java backend (separate project) over REST + JWT.

## Prerequisites

- Flutter SDK 3.22+ (`flutter --version` to check)
- For Android: Android Studio + an emulator or device
- For iOS: a Mac with Xcode 15+ and CocoaPods (`sudo gem install cocoapods`)
- For Web: any modern browser (Chrome recommended for `flutter run -d chrome`)

## First-time setup

```bash
cd frontend
flutter pub get
```

### Android

`android/local.properties` ships with placeholder paths. Either:
- open the `android/` folder once in Android Studio and let it regenerate the file, or
- edit it yourself:
  ```
  sdk.dir=/Users/you/Library/Android/sdk
  flutter.sdk=/Users/you/flutter
  ```
Then:
```bash
flutter run -d android
```

### iOS (macOS only)

This project ships the iOS source files (`AppDelegate.swift`, `Info.plist`, `Podfile`,
`Flutter/*.xcconfig`) but **not** a hand-built `Runner.xcodeproj/project.pbxproj` — that
file is a complex, tooling-generated Xcode project descriptor that's version-specific and
unsafe to hand-craft. Generate it once with Flutter itself:

```bash
cd frontend
flutter create --platforms=ios .
cd ios && pod install
cd ..
flutter run -d ios
```

`flutter create --platforms=ios .` will notice the existing `ios/Runner/*` source files
and regenerate only the missing Xcode project scaffolding around them — it won't overwrite
your `lib/` code or `pubspec.yaml`.

### Web

```bash
flutter run -d chrome
# or, for a production build:
flutter build web
```

## Connecting to the backend

`lib/core/constants.dart` picks the right backend URL automatically per platform for local
development:

| Platform          | Default base URL                  |
|-------------------|-------------------------------------|
| Android emulator  | `http://10.0.2.2:8080/api`          |
| iOS simulator     | `http://localhost:8080/api`         |
| Web               | `http://localhost:8080/api`         |

For a **physical device**, replace `10.0.2.2`/`localhost` with your machine's LAN IP
(e.g. `http://192.168.1.20:8080/api`), since the device can't resolve `localhost` as your
computer.

For **production**, set `useProductionUrl = true` and fill in `_productionBaseUrl` in
`lib/core/constants.dart`.

Make sure the backend's `logisticfleet.cors.allowed-origins` (in `application.properties`)
includes your Flutter web app's origin, and that the backend is running before you launch
the app — see `../backend/README.md`.

## What's implemented

- JWT auth (register/login), with role-based UI: DRIVER accounts see the trip/expense/earnings
  experience; ADMIN accounts land on a fleet-management dashboard instead — same app, same login
  screen, the role on the account decides what's shown.
- **Driver experience:** trip list (active/history), trip detail with route stops, dock-in/out with
  GPS capture, expense logging, earnings history + summary, profile/logout.
- **Admin experience:** dashboard with live trip-status counts, assign trips to drivers, driver
  management (add drivers, activate/deactivate), vehicle/fleet management (add vehicles, assign to
  drivers, change status), expense approval queue, earnings payout marking.

To test the admin experience: register a normal account, then promote it to `ADMIN` in the
database (see `../logisticfleet-backend/README.md`), and log back in.

## Project structure

```
frontend/
├── android/     Native Android project (Gradle, manifest, Kotlin MainActivity)
├── ios/          Native iOS source (AppDelegate, Info.plist, Podfile)
├── web/           index.html, manifest.json, icons
├── lib/
│   ├── core/       theme, constants, API client (Dio + JWT interceptor)
│   ├── models/      Trip, RouteStop, DockEvent, Expense, Earning, Vehicle, Driver, User
│   ├── services/     one class per REST resource (+ admin variants)
│   ├── providers/     ChangeNotifier state (auth, trips, expenses, earnings, admin)
│   └── screens/        auth, home, trips, expenses, earnings, profile, admin/
└── pubspec.yaml
```
