# TechExpo

A Flutter conference app: browse sessions, open details, bookmark sessions. Bookmarks are kept after the app restarts.
Apk Link : https://drive.google.com/drive/folders/1wuPycGm2jXvW_RDMCDgBi7owRR1hrc2P?usp=drive_link

## Run

```bash
flutter pub get
flutter run --flavor dev     # "TechExpo Dev" with a DEV ribbon
flutter run --flavor prod    # "MunichTech EXPO"
flutter test
```

## Tested on

- **Android:** emulator, Medium Phone, API 37.1 ✅
- **iOS:** not tested (no Mac available)

## Data source

https://raw.githubusercontent.com/YASHRAJSIH/TechExpo/master/mock/sessions.json

## State management: Cubit

- Less boilerplate than Redux for this small app.
- Sealed states (`Loading`, `Loaded`, `Empty`, `Error`) make sure every case is handled in the UI.
- Easy to unit test with fake data.

Two Cubits: `SessionsCubit` (loads sessions) and `BookmarksCubit` (adds, removes and saves bookmarks).

## Structure

```
lib/
├── main.dart     app setup and navigation
├── config/       dev / prod settings
├── models/       Session model
├── data/         API call, repository, bookmark storage
├── cubits/       state management
├── pages/        Sessions, Session detail, Bookmarks
└── widgets/      shared UI pieces
```

## Error handling

- No internet, timeout (10 s), server error and bad JSON each show a clear message with a **Retry** button.
- Bad items in the JSON are skipped; the rest still show.
- If a refresh fails, the old list stays on screen.
- Missing optional fields fall back to "TBA" instead of crashing.

## Tests

47 tests covering JSON parsing, network errors, both Cubits, bookmark saving, flavors and back navigation.

## Flavors

| | dev | prod |
|---|---|---|
| App name | TechExpo Dev | MunichTech EXPO |
| App id | `...flutter_trial.dev` | `...flutter_trial` |
| DEV ribbon | yes | no |

## Left out

- **Crashlytics:** skipped to focus on the required features.
- **Info tab:** placeholder only, not part of the brief.
- **Share, email and floor-plan buttons:** shown but not working yet.
- **App ids:** still `com.example.*`; fine for a demo.
- **iOS testing:** no Mac available.
