# TechExpo

A conference companion app for the (fictional) MunichTech EXPO, built with Flutter. It shows the session schedule, lets you open a session's details and bookmark it, and keeps your bookmarks on the device across restarts.

- **Sessions:** a list loaded from a REST endpoint, with search (title, speaker or category) and filters (Today, Tomorrow, per hall). It handles loading, error, empty and "refresh failed" states, and supports pull to refresh.
- **Session detail:** description, speaker, time, location and a bookmark button.
- **Bookmarks:** only the bookmarked sessions, filterable by Upcoming / Live / Completed. You can remove a bookmark with Undo, and the list works offline.
- **Two flavors:** `dev` and `prod`, each with its own app name and app id, plus a DEV ribbon in the dev build.

## Running the app

Requires Flutter 3.47 (Dart 3.13) or newer.

```bash
flutter pub get

flutter run --flavor dev      # "TechExpo Dev", with a DEV ribbon
flutter run --flavor prod     # "MunichTech EXPO"
flutter run                   # same as --flavor dev (default-flavor in pubspec.yaml)

flutter build apk --flavor prod --release
```

Run the tests and the analyzer:

```bash
flutter test
flutter analyze
```

## Tested platforms

| Platform | Status |
|---|---|
| Android | Tested on the **Android emulator, "Medium Phone" device profile, API 37.1**. Debug APKs build for both flavors, and I checked the app id and name in each APK. |
| iOS | **Not tested.** I don't have a Mac, so the iOS build has never been compiled. The iOS flavors were set up by editing the Xcode project file directly; see [Flavors](#flavors). |

## Data source

Sessions come from a JSON file in this repository, [`mock/sessions.json`](mock/sessions.json), served by GitHub at:

```
https://raw.githubusercontent.com/YASHRAJSIH/TechExpo/master/mock/sessions.json
```

I chose this over a public mock API because:

- it's free and needs no account;
- the data sits next to the code, so reviewers can see it;
- GitHub's raw file hosting is very stable.

The trade-off is that it's read-only. That's fine here: the app only reads sessions, and bookmarks are stored on the phone.

Times are stored without a timezone (`2026-10-14T10:30:00`), so a 10:30 talk shows as 10:30 in Munich local time on every phone, wherever it is.

## State management: Cubit

I used **Cubit** from `flutter_bloc`:

- **Little boilerplate.** The app has two small pieces of state, the sessions list and the bookmarks. Cubit keeps that small (a method calls `emit`) without the action and reducer layers Redux would add.
- **Explicit UI states.** `SessionsState` is a sealed class (`Loading`, `Loaded`, `Empty`, `Error`), so the page `switch`es over it and the compiler makes sure every state is handled.
- **Easy to test.** Cubits are plain Dart classes. The tests create them with a fake repository or fake storage and check `state`, with no widgets involved.

There are two Cubits, both created once in `main.dart`:

| Cubit | Responsibility |
|---|---|
| `SessionsCubit` | Loads sessions from the repository and exposes Loading / Loaded / Empty / Error. If a refresh fails while data is already on screen, it keeps that data and sets `refreshError`, and the page shows a snackbar with Retry. |
| `BookmarksCubit` | Adds and removes bookmarks, keeps them sorted, saves them after every change and loads them at startup. Whenever fresh sessions arrive, it updates the saved copies. |

## Project structure

```
lib/
├── main.dart              App setup only: error handlers, providers, routes, bottom navigation
├── config/
│   └── app_config.dart    dev / prod settings (app name, endpoint, DEV ribbon)
├── models/
│   └── session.dart       Session model + defensive fromJson / toJson
├── data/
│   ├── sessions_api.dart         HTTP GET with a 10 s timeout
│   ├── sessions_repository.dart  Parses JSON, maps failures to SessionsException
│   ├── sessions_exception.dart   Sealed error types with user-friendly messages
│   └── bookmarks_storage.dart    Saves bookmarks with shared_preferences
├── cubits/                Sessions + Bookmarks Cubits and their states
├── pages/                 One file per screen: sessions, session detail, bookmarks
├── widgets/               Shared UI pieces (header, tag, pill, message view)
├── theme/                 Colours
└── utils/                 Date / time formatting
```

Each layer only talks to the one below it: pages → Cubits → repository / storage → API. Raw exceptions never get past the repository.

## Error handling and edge cases

**Network** (`SessionsRepository`):

| What goes wrong | Error type | What the user sees |
|---|---|---|
| No internet (`SocketException`, `ClientException`) | `NoInternetException` | "No internet connection…" + Retry |
| Slow server (more than 10 s) | `RequestTimeoutException` | "The server is taking too long…" + Retry |
| Status other than 200 | `ServerException(statusCode)` | "The server returned an error (500)…" + Retry |
| Invalid JSON, or the wrong shape (e.g. an object instead of a list) | `InvalidDataException` | "We received data we couldn't read…" + Retry |
| Anything else | `UnknownSessionsException` | "Something went wrong…" + Retry |

**Parsing** (`Session.fromJson`): the JSON isn't trusted.

- **Required fields:** `id`, `title` and `startTime`. A session missing any of them is rejected, because it can't be shown, sorted or given a status without them.
- **Optional fields** fall back to safe values (`"TBA"`, empty text, no end time), and the UI hides empty fields.
- **No crashing casts:** it uses `tryParse` instead of `parse`, and nullable casts.
- **Ids:** both `"id": 1` and `"id": "1"` are accepted.
- **Bad values are dropped:** non-string tags are removed, and an end time before the start time is ignored.
- **One bad record doesn't break the list.** Each item is parsed separately; invalid items and duplicate ids are logged and skipped, and the rest still show.

**Bookmarks:**

- **Corrupted storage** loads as an empty list instead of crashing, and unreadable entries are skipped.
- **A failed save** keeps the bookmark in memory, and the next change tries to save again.
- **Bookmarking during startup** (before saved bookmarks have loaded) doesn't lose anything.
- **A session removed from the API** stays bookmarked, so it doesn't silently disappear.

**App-wide:**

- `FlutterError.onError` and `PlatformDispatcher.instance.onError` log any error that nothing else caught. This is where Crashlytics would plug in.
- **Back button:** on the Bookmarks or Info tab, back goes to Sessions; on Sessions it exits. Android's predictive back is turned off (`enableOnBackInvokedCallback="false"`) so every back press reaches Flutter.

## Tests

47 tests, all in `test/`:

| File | What it covers |
|---|---|
| `models/session_test.dart` | Valid parsing, numeric ids, missing required fields, blank title, invalid dates, wrong types, fallbacks, bad tags, end time before start, Upcoming / Live / Completed |
| `data/sessions_repository_test.dart` | Sorting, `{"sessions": [...]}` vs a bare list, skipping broken items and duplicates, empty list, broken JSON, wrong shape, 500 response, no internet, timeout |
| `cubits/sessions_cubit_test.dart` | Loading → Loaded / Empty / Error, refresh failure keeps old data, retry after an error |
| `cubits/bookmarks_cubit_test.dart` | Add, remove, sorting, survives a restart, bookmarking during startup, updating saved copies from fresh data, failed save |
| `data/bookmarks_storage_test.dart` | Save and load keep every field, nothing saved, corrupted data, unreadable entries |
| `config/app_config_test.dart` | Flavor selection, unknown flavor falls back to dev, DEV ribbon |
| `widgets/back_navigation_test.dart` | Detail → Bookmarks → Sessions → exit, and Info → Sessions → exit |

The network tests use `MockClient` from `package:http/testing.dart`, so no real requests are made.

## Flavors

| | dev | prod |
|---|---|---|
| App name | TechExpo Dev | MunichTech EXPO |
| Android app id | `com.example.flutter_trial.dev` | `com.example.flutter_trial` |
| iOS bundle id | `com.example.flutterTrial.dev` | `com.example.flutterTrial` |
| In the app | orange DEV ribbon | none |

Because the ids differ, both builds can be installed side by side.

- **Dart:** `AppConfig.fromFlavorName(appFlavor)` uses Flutter's built-in `appFlavor`, so there is only one `main.dart`. An unknown flavor falls back to dev, so a misconfigured build never looks like prod.
- **Android:** `productFlavors` in `android/app/build.gradle.kts`. The app name is set with `manifestPlaceholders`, because the current Android Gradle Plugin turns `resValue` off by default.
- **iOS:**
  - `Debug-dev`, `Release-dev`, `Profile-dev` and the matching `-prod` build configurations, plus `dev` and `prod` schemes.
  - The home-screen name comes from an `APP_DISPLAY_NAME` build setting.
  - **Not compiled yet** (see [Tested platforms](#tested-platforms)). If CocoaPods is used in the future, the Podfile will need these configurations mapped.

Both flavors currently use the same endpoint. `AppConfig` is where a separate dev endpoint would go.

## What I left out, and why

| Left out | Why |
|---|---|
| **Firebase Crashlytics / Analytics** | Optional in the brief. Firebase setup for two flavors on two platforms (two Firebase apps, config files per flavor) would have taken time away from the required features. The global error handlers in `main.dart` are ready to forward to Crashlytics. |
| **Info tab** | Not part of the brief. It's in the bottom navigation to match the design, but it only shows placeholder text. |
| **Share, email and floor-plan buttons** on the detail page | They're in the design but not in the brief, and each needs extra packages and decisions (share sheet, mail client, a real floor plan). They're visible but do nothing yet. The map on the detail page is a drawn placeholder, not a real map. |
| **Real app ids** | Still `com.example.*`. Changing them means picking a final id and moving the Android `MainActivity` package; app stores require it, but a take-home doesn't. |
| **iOS testing** | No Mac available. |
| **Plus Jakarta Sans font** | It would need the `google_fonts` package or bundled font files. The app uses the system font. |
| **Live-updating status badges** | Upcoming / Live / Completed on the Bookmarks page are worked out when the page redraws, not on a timer. |
| **Navy and gold branding** | Optional. I followed my own design system instead (primary `#0066FF`, navy `#0B132B`, green `#10B981`). |
| **Offline cache for the sessions list** | Bookmarked sessions work offline, but the full schedule needs a connection. Caching the last response would be the next step. |
