# CODEBASE_SUMMARY.md

> Practical technical map of the EventHub repository for developers and AI assistants.
> All claims below were verified against the source files listed in §15. Statements that
> go beyond what the code shows are marked **Inferred**; things that could not be
> confirmed are marked **Unknown**.

## 1. Document Purpose and Scope

- **Covers:** the `mad_final_project` Flutter repository (app codename **EventHub**)
  as it exists on branch `master` after the UI-polish commit (`fac3119`).
- **Repository analyzed:** `mad_final_project/` — a student-facing school-event
  discovery and registration app with a Firebase backend (Auth + Firestore) and
  local (bundled) event images.
- **Limitations:** analysis is static (source + config only). Firestore console
  contents, live Firebase behavior, and on-device runs were not inspected. The
  `gh-pages` branch contains only built web output and was not analyzed beyond
  confirming its purpose. Platform folders (`android/`, `ios/`, `web/`, `linux/`,
  `macos/`, `windows/`) were sampled, not fully audited.

## 2. Project at a Glance

- **What it is:** a cross-platform mobile app (Flutter) where students create an
  account, browse school events, filter by category, view details + location,
  register/cancel, see upcoming vs. past registrations, and get a local reminder
  1 hour before each event.
- **Maturity (evidence-based):** working MVP. `flutter analyze` is clean,
  `flutter test` passes 6/6, `flutter build web --release` succeeds (verified
  during this session's history), and the app is deployed to GitHub Pages from
  the `gh-pages` branch. Admin/event-creation UI is intentionally out of scope;
  events are seeded directly in Firestore.
- **Architecture in one line:** layered Flutter app — `ui/` (Provider
  view-models + views) → `data/services/` (abstract contracts with Firestore and
  in-memory mock implementations) → `domain/models/` → Firebase (Auth,
  Firestore) + device APIs (notifications, maps, image assets).

## 3. Technology Stack

| Layer | Technology | Evidence |
|---|---|---|
| Language | Dart (SDK `^3.12.2`) | `pubspec.yaml:21-22` |
| UI framework | Flutter 3.x, Material 3 (`useMaterial3: true`) | `pubspec.yaml:30-32`, `lib/ui/core/theme.dart:29,64` |
| State management | `provider` `^6.1.5+1` (`ChangeNotifier` view-models) | `pubspec.yaml:43`, `lib/main.dart:59-72` |
| Auth | `firebase_auth` `^6.7.0` (email/password) | `pubspec.yaml:38`, `lib/data/services/auth_service.dart:37-62` |
| Database | `cloud_firestore` `^6.10.0` | `pubspec.yaml:39`, `firestore.rules` |
| (Unused dep) | `firebase_storage` `^13.6.0` — declared but no code imports it | `pubspec.yaml:40`; verified: no `firebase_storage` import under `lib/` |
| Notifications | `flutter_local_notifications` `^22.3.1` + `timezone` `^0.11.1` | `pubspec.yaml:41,44`, `lib/data/services/notification_service.dart` |
| Maps | `url_launcher` `^6.3.3` (opens Google Maps URL externally) | `pubspec.yaml:42`, `lib/data/services/maps_launcher.dart:22` |
| Lint | `flutter_lints` `^6.0.0` | `pubspec.yaml:55`, `analysis_options.yaml` |
| Test | `flutter_test` (SDK) | `pubspec.yaml:47-48`, `test/` |
| Backend | Firebase project `mad-project-83ad2` (Auth + Firestore; Storage provisioned but unused) | `lib/firebase_options.dart`, `firebase.json` |
| Deploy | GitHub Pages via `gh-pages` branch (manual: `flutter build web` output pushed to branch) | git branches `master` + `gh-pages` |

## 4. Repository Structure

```text
mad_final_project/
├── lib/
│   ├── main.dart                  # bootstrap, DI, routing, tab shell
│   ├── firebase_options.dart      # generated Firebase config (all platforms)
│   ├── domain/models/             # Event, Registration (+ Firestore mappers)
│   ├── data/services/             # contracts + Firestore impls + mock impls
│   └── ui/
│       ├── core/                  # theme tokens, shared widgets (cards, chips)
│       └── features/
│           ├── auth/              # login/signup view + view-model
│           ├── discover/          # browse + filter view + view-model
│           ├── detail/            # event detail view
│           └── my_events/         # upcoming/history list + view-model
├── test/                          # unit + widget tests (mock-backed)
├── tool/seed_events.json          # sample events (legacy date shape)
├── assets/images/                 # 6 bundled event photos (.jpg)
├── firestore.rules                # security rules (events + registrations)
├── firebase.json                  # FlutterFire project mapping
├── android/ios/web/linux/macos/windows/  # platform shells (sampled only)
├── pubspec.yaml / analysis_options.yaml
└── CODEBASE_SUMMARY.md / SYSTEM_OVERVIEW.md / DESIGN.md (this documentation)
```

Excluded as noise: `build/`, `.dart_tool/`, `.idea/`, `.vscode/`, `.agents/`
(skills used during development, not app code), platform boilerplate.

| Directory | Responsibility |
|---|---|
| `lib/domain/models/` | Pure data: `Event` (event.dart), `Registration` (registration.dart); Firestore `fromMap`/`toMap`; date formatting; `isAssetImage()` asset-vs-URL discriminator |
| `lib/data/services/` | Five contracts, each with a real and a fake implementation: `auth_service.dart`, `event_repository.dart`, `registration_repository.dart`, `notification_service.dart`, `maps_launcher.dart` |
| `lib/ui/core/` | `theme.dart` (light/dark tokens), `widgets.dart` (`EventCard`, `CategoryChips`, loading/empty states) |
| `lib/ui/features/*/` | One folder per feature, each split into `views/` (widgets) and `view_models/` (state); `detail/` has a view only and reuses the other VMs |
| `test/` | `eventhub_test.dart` (5 unit tests), `widget_test.dart` (1 widget test) |
| `tool/` | `seed_events.json` — 5 sample events in the legacy `{date, startTime}` shape |
| `assets/images/` | 6 local `.jpg` event photos referenced by Firestore `imageUrl` asset paths |

## 5. Application Entry Points

- **Start:** `main()` in `lib/main.dart:35-39` — ensures widget binding, calls
  `_initFirebase()`, then runs `EventHubApp`.
- **Init:** `_initFirebase()` (`main.dart:23-33`) initializes Firebase with
  `DefaultFirebaseOptions.currentPlatform`; on failure it returns `false` and
  the app runs on in-memory mocks instead of crashing.
- **Dependency injection:** `EventHubApp.build` (`main.dart:46-57`) picks
  Firebase vs. mock implementations from the `firebaseReady` flag and exposes
  three view-models via `MultiProvider` (`main.dart:59-72`).
- **Routing:** single named route `/detail` with a `String` event-ID argument
  (`main.dart:78-87`); home is `AuthGate` (`main.dart:95-104`), which shows
  `AuthView` when signed out and the 3-tab `HomeShell` when signed in
  (Discover / My Events / History, `main.dart:119-127`).

## 6. Major Modules and Components

| Module | Responsibility | Key files | Depends on |
|---|---|---|---|
| Auth | sign-up/in/out, UID stream, friendly error strings, password reset | `data/services/auth_service.dart`; `ui/features/auth/view_models/auth_view_model.dart`, `ui/features/auth/views/auth_view.dart` | `firebase_auth` / in-memory mock |
| Discover | event stream, category filter, text search, counts | `data/services/event_repository.dart`; `ui/features/discover/view_models/discover_view_model.dart`, `ui/features/discover/views/discover_view.dart` | `Event` model |
| Theme mode | light/dark/system + persisted toggle | `ui/core/theme_controller.dart` (`shared_preferences`) | `main.dart`, HomeShell + AuthView |
| Detail | full event display, register/cancel buttons, maps + calendar buttons | `ui/features/detail/views/detail_view.dart` | Discover + MyEvents VMs, `MapsLauncher`, `CalendarLauncher` |
| My Events / History | registrations joined with events, upcoming-vs-past split, register/cancel + reminders | `data/services/registration_repository.dart`, `data/services/notification_service.dart`; `ui/features/my_events/view_models/my_events_view_model.dart`, `ui/features/my_events/views/registrations_list.dart` | both repositories, notifications |
| Shared UI | theme tokens, event card, filter chips, loading/empty states | `ui/core/theme.dart`, `ui/core/widgets.dart` | `Event` model |
| Maps | open event location in external Maps | `data/services/maps_launcher.dart` | `url_launcher`, `Event.hasCoordinates` |
| Calendar | Google Calendar template URL (2h fallback end) | `data/services/calendar_launcher.dart` | `url_launcher` (no new deps; Apple .ics out of scope) |

## 7. Core Business Logic

- **Past vs. upcoming:** `Event.isPast` (`domain/models/event.dart:41`) compares
  `dateTime` to `DateTime.now()`; `MyEventsViewModel._joined`
  (`ui/features/my_events/view_models/my_events_view_model.dart:36-47`) splits
  joined registrations and sorts upcoming ascending / history descending.
- **Duplicate-registration guard (two layers):** deterministic Firestore doc ID
  `` `${studentId}_${eventId}` `` (`domain/models/registration.dart:23-24`);
  pre-write existence check throwing `DuplicateRegistration`
  (`data/services/registration_repository.dart:41-58`), mirrored in
  `firestore.rules:22-25` (`registrationId == studentId_eventId`).
- **Registration flow rules** (`my_events_view_model.dart:70-104`): past events
  rejected with notice; duplicates reported; other failures reported; on success
  notification permission is requested (best-effort — denial still registers)
  and a reminder is scheduled 1 hour before start
  (`notification_service.dart:22-24`); cancellation also cancels the reminder
  (`my_events_view_model.dart:106-118`).
- **Category filter:** fixed enum + `All`
  (`domain/models/event.dart:32-39`); filtering is in-memory exact match
  (`discover_view_model.dart`), combined with case-insensitive search over
  name/category/venue/address/description; `counts`/`countFor` derive live
  per-category totals; `clearFilters()` resets both.
- **Cancellation confirmation:** shared `confirmCancelRegistration` dialog
  (`ui/core/widgets.dart`) gates both swipe-cancel and detail-cancel; only an
  explicit confirm reaches `MyEventsViewModel.cancel`.
- **Password reset:** `AuthService.sendPasswordReset` (Firebase
  `sendPasswordResetEmail` / mock recorder) with `friendlyResetError`
  mapping; unknown addresses get a generic message (no enumeration).
- **Auth errors:** Firebase codes mapped to user strings
  (`auth_service.dart:15-35`); mock `FormatException` codes mapped separately
  (`auth_view_model.dart:54-65`).

## 8. Data Layer

- **Technology:** Cloud Firestore, accessed via `cloud_firestore`; two
  top-level collections, no subcollections, no transactions, no composite
  indexes required (single-field `orderBy('dateTime')` and equality filter on
  `studentId` only).
- **`events/{eventId}`:** `name, category, dateTime (Timestamp), locationName,
  address, latitude?, longitude?, description, imageUrl` — see
  `Event.toMap` (`domain/models/event.dart:68-78`). Reads are
  `orderBy('dateTime')` snapshots or one-shot gets
  (`data/services/event_repository.dart:18-28`).
- **`registrations/{studentId_eventId}`:** `studentId, eventId, registeredAt
  (Timestamp), status ('registered')` — see `Registration.toMap`
  (`domain/models/registration.dart:38-43`). Reads are `where('studentId' == uid)`
  queries; writes are single-doc `set`/`delete`
  (`data/services/registration_repository.dart:28-70`).
- **Seed data:** `tool/seed_events.json` holds 5 samples in a legacy
  `{date, startTime}` shape still parseable via `Event._fromLegacy`
  (`domain/models/event.dart:80-84`), but it is **not** the live shape — live
  docs must carry `dateTime: Timestamp` for ordering to work.
- **Mocks:** `MockEventRepository` (6 relative-date events incl. 1 past,
  `data/services/event_repository.dart:33-122`),
  `MockRegistrationRepository` (in-memory map keyed by doc ID),
  `MockAuthService` (in-memory email/password store).

## 9. API and Integration Inventory

No app-owned HTTP API exists. All integrations are outbound client SDK calls:

| Integration | Purpose | Auth | Failure handling |
|---|---|---|---|
| Firebase Auth (email/password) | identity; UID scopes all data | user credentials | friendly strings (`auth_service.dart:15-35`) |
| Firestore `events` | event catalog (read-only for clients) | signed-in (rules) | loading/error/empty states in views |
| Firestore `registrations` | per-student registrations | owner-only rules + deterministic IDs | notices via Snackbar; pre-read tolerates legacy `permission-denied` (`registration_repository.dart:43-50`) |
| `flutter_local_notifications` + `timezone` | 1-hour-before reminders | OS runtime permission (best-effort) | denial never blocks registration; past times skipped (`notification_service.dart:76`) |
| Google Maps URL via `url_launcher` | open location externally | none | returns `false` → Snackbar (`detail_view.dart` maps handler) |
| Bundled `assets/images/` | event photos (offline, no Storage) | none | placeholder / broken-image fallback (`ui/core/widgets.dart`) |

## 10. Configuration and Environment

- `pubspec.yaml` — SDK, dependencies, version `1.0.0+1`, `assets/images/` bundle.
- `lib/firebase_options.dart` — generated per-platform Firebase config
  (**Verified**: contains client API keys by Firebase design; no admin secrets
  present — do not add service-account JSON here).
- `firebase.json` — FlutterFire project mapping (`mad-project-83ad2`).
- `firestore.rules` — deployed separately via console Rules tab.
- `android/app/google-services.json` — gitignored Android Firebase config; a
  fresh clone lacks it (mock mode still runs; Android Firebase builds need it
  re-added). No `GoogleService-Info.plist` was found in the repo.
- **No `.env` files, no feature flags, no flavors** (single build for all
  environments). `firebase_storage` is declared but unused — Storage setup is
  unnecessary since images are bundled.

## 11. Testing and Quality

- **Framework:** `flutter_test`; tests live in `test/`, all mock-backed (no
  Firebase emulator).
- **Coverage (inspected):** category filter, counts, search + combined filters
  + clear (`test/eventhub_features_test.dart`); duplicate-registration guard,
  cancel flow, upcoming/history split, per-student isolation
  (`test/eventhub_test.dart`); Discover widget smoke test
  (`test/widget_test.dart`); password-editable-after-error + validation +
  reset dialog (`test/auth_regression_test.dart`); cancel-dialog
  confirm/dismiss (`test/confirm_dialog_test.dart`); calendar URL encoding
  (`test/eventhub_features_test.dart`). Last verified run: 21/21 pass.
- **Lint:** `flutter_lints` via `analysis_options.yaml`; last verified run:
  no issues.
- **Gaps:** no tests for detail view, maps launcher, notification
  scheduling, Firestore rules, or `Event.fromMap` legacy-shape parsing.

## 12. Build and Execution

Prerequisites: Flutter stable SDK + Dart; Android Studio (or VS Code) with
Flutter plugin; a device/emulator or Chrome for web.

```bash
flutter pub get                        # fetch deps (also auto-runs when needed)
flutter analyze                        # lint — verified clean
flutter test                           # 6/6 — verified passing
flutter run                            # mock mode works with no Firebase setup
flutter build web --release --base-href /mad-final-project/  # verified; output in build/web/
```

Deployment (verified history): `build/web/` contents are pushed to the
`gh-pages` branch; GitHub Pages serves `ralph-16.github.io/mad-final-project/`;
Firebase console needs `ralph-16.github.io` in Auth authorized domains.
Assumptions: Firestore `events` docs use `dateTime: Timestamp` and asset-path
`imageUrl`; `firestore.rules` is published in console; web notifications do not
fire (registration still succeeds).

## 13. Important Findings

1. **`firebase_storage` is dead weight** (declared, never imported) — removal
   would shrink the dependency surface; kept so far for zero-risk.
2. **Two repository APIs are unused:** `RegistrationRepository.watchForStudent`
   and repo-level `isRegistered(studentId, eventId)` have no callers under
   `lib/` (verified by search) — the VMs use `fetchForStudent` + in-memory
   membership instead. Candidates for removal or for a future realtime
   My-Events refresh.
3. **Mock fallback can mask backend outages:** any `initializeApp` failure
   silently switches to mocks (`main.dart:29-32`) with only a debug log — a
   misconfigured Firebase looks like "empty app", not an error.
4. **`tool/seed_events.json` shape ≠ live shape** (legacy `date/startTime` +
   `STORAGE_URL_*` placeholders) — seeding from it verbatim breaks
   `orderBy('dateTime')`.
5. **Docs gap (now closed by these files):** prior to this task the only design
   doc was `README.md`; architecture, data model, and rules rationale were
  only in code comments.

## 14. Developer Quick Reference

| I want to… | Look at |
|---|---|
| Change registration rules | `MyEventsViewModel.register/cancel` + `Registration.docId` + `firestore.rules` |
| Change upcoming/history split | `Event.isPast`, `MyEventsViewModel._joined` |
| Change event fields/shape | `Event.fromMap/toMap`, Firestore docs, `tool/seed_events.json` |
| Change event card/list look | `ui/core/widgets.dart`, `ui/core/theme.dart` |
| Change filter categories / search | `Event.categories`, `DiscoverViewModel` (filter + `searchQuery` + `counts`) |
| Change auth behavior/errors/reset | `data/services/auth_service.dart`, `auth_view_model.dart` |
| Change reminders / calendar | `notification_service.dart`, `data/services/calendar_launcher.dart` |
| Change maps behavior | `data/services/maps_launcher.dart` |
| Change DB access control | `firestore.rules` (then republish in console) |
| Add/adjust tests | `test/eventhub_test.dart`, `test/widget_test.dart` |

## 15. Evidence and References

Primary sources inspected (paths are repo-relative): `lib/main.dart`,
`lib/firebase_options.dart`, `lib/domain/models/event.dart`,
`lib/domain/models/registration.dart`,
`lib/data/services/{auth_service,event_repository,registration_repository,notification_service,maps_launcher}.dart`,
`lib/ui/core/{theme,widgets}.dart`,
`lib/ui/features/discover/{views/discover_view,view_models/discover_view_model}.dart`,
`lib/ui/features/detail/views/detail_view.dart`,
`lib/ui/features/my_events/{views/registrations_list,view_models/my_events_view_model}.dart`,
`lib/ui/features/auth/{views/auth_view,view_models/auth_view_model}.dart`,
`test/eventhub_test.dart`, `test/widget_test.dart`, `pubspec.yaml`,
`analysis_options.yaml`, `firestore.rules`, `firebase.json`,
`tool/seed_events.json`, `assets/images/`, `.gitignore`, `README.md`
(supplementary), git history/branches. Platform folders sampled only
(`android/app/build.gradle.kts`, `google-services.json` presence,
`web/index.html`).
