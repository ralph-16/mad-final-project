# EventHub

Student-facing mobile app for discovering school events and managing
registrations. Seminars, workshops, sports, academic competitions, org
activities.

## Status

UI + data layer complete. Runs immediately in **mock mode** (sample events,
in-memory auth/registrations). Connect Firebase to go live.

Verified: `flutter analyze` clean, `flutter test` 6/6 pass,
`flutter build apk --debug` succeeds.

## Demo script (mock mode, ~5 min)

1. `flutter run`, sign up with any email (`student@school.edu`, 6+ chars).
2. Discover tab: scroll cards, filter chips (All + 5 categories).
3. Open an event → Register → snackbar confirms + reminder notice.
4. My Events tab: entry appears; swipe it away to cancel.
5. History tab: fills from your registrations once their date passes.
   (Mock samples are upcoming, so History starts empty — the
   upcoming/history split is covered by `flutter test`.)
6. Detail → Open location in Maps (falls back to address search).
7. Log out from the app bar; log back in — mock session resets
   (Firestore mode persists per-account).

## Run (mock mode, no setup)

```bash
flutter pub get
flutter run
```

Sign up with any email (e.g. `student@school.edu`, 6+ char password).
Register for events, check My Events / History, swipe a card to cancel.

## Go live with Firebase (~20 min)

1. Create a project at https://console.firebase.google.com/
2. Enable **Authentication → Email/Password**.
3. Create a **Cloud Firestore** database.
4. Install the CLI: `dart pub global activate flutterfire_cli`
5. Run `flutterfire configure` (generates `lib/firebase_options.dart`).
6. Wire it in `lib/main.dart`: pass `options:` to `Firebase.initializeApp`.
   The app auto-switches from mocks to Firestore/Auth when init succeeds.
7. Deploy rules: copy `firestore.rules` into the console **Rules** tab.
8. Upload images to **Storage**; create docs in `events` (see
   `tool/seed_events.json` for shapes, replace `STORAGE_URL_*` with real
   download URLs).

### Android notifications

`flutter_local_notifications` needs (see its README):

- `POST_NOTIFICATIONS` permission (requested at runtime by the app)
- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` entries if exact timing
  is required on Android 12+

## Tests

```bash
flutter analyze
flutter test
```

Covers: category filter, duplicate-registration guard, cancel flow,
upcoming/history split, per-student isolation, Discover widget smoke test.

## Structure

```text
lib/
├── main.dart                    # Firebase-or-mock bootstrap, tabs, routes
├── domain/models/               # Event, Registration (+ Firestore mappers)
├── data/services/               # Auth / Event / Registration / Notifications / Maps
│                                # each: abstract contract + Firestore + mock impl
└── ui/
    ├── core/                    # Theme tokens, EventCard, chips, states
    └── features/
        ├── auth/                # Login + signup
        ├── discover/            # Browse + category filter
        ├── detail/              # Details + register/cancel + maps button
        └── my_events/           # My Events (upcoming) + History (past)

test/eventhub_test.dart          # Unit tests (filter, register, cancel, split)
test/widget_test.dart            # Discover widget smoke test
tool/seed_events.json            # Sample events matching the Firestore shape
firestore.rules                  # Events read-only; registrations owner-only
```

## Notes

- Android desugaring for notifications is already enabled in
  `android/app/build.gradle.kts`; no Gradle setup needed.
- No custom fonts bundled: Material 3 default type ramp with the EventHub
  color tokens (event orange `#EA580C` + map blue `#2563EB`).

## Reminder rule

One local reminder per registration, 1 hour before start. Denied
permission never blocks registration; cancelling removes the reminder.
Past events are defined by scheduled date/time.
