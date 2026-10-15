# SYSTEM_OVERVIEW.md

> What EventHub is, who uses it, and how its main workflows operate — written for
> new developers and technically informed non-developers. See `CODEBASE_SUMMARY.md`
> for the code map and `DESIGN.md` for the architecture.

## 1. Executive Summary

**EventHub** is a student-facing mobile app (also published as a website) for
discovering school events — seminars, workshops, sports, academic competitions,
organization activities — and managing personal registrations. A student signs
up, browses events, registers for upcoming ones, gets a phone reminder an hour
before each event, and later finds past events in a history list. Event records
themselves are entered by staff directly in Firebase; the app has no admin
interface by design. Registrations are private per student and survive
logout/login.

## 2. Purpose and Scope

**Included:** account signup/login/logout; event browsing with loading/empty
states; category filtering; event details with location; registration and
cancellation with confirmations; personal upcoming/history lists; local
reminders; per-student data privacy.

**Handled externally:** identity and data storage (Firebase Authentication +
Cloud Firestore); push-style timing (OS local notifications); maps rendering
(Google Maps app/website); image hosting (photos are bundled inside the app —
Firebase Storage is provisioned but unused); website hosting (GitHub Pages).

**Evidence limits:** this description is reconstructed from code and config;
live Firebase contents and on-device behavior (notification delivery, maps
handoff) were not observed.

## 3. Users and Roles

Only one user role is implemented: **student** (anyone with an email account).

| Capability | Student (signed in) | Signed out |
|---|---|---|
| Browse events | yes | no (login screen shown first) |
| Filter by category | yes | no |
| View event details + maps | yes | no |
| Register / cancel | yes | no |
| View own My Events / History | yes | no |
| Create/edit events | no (staff use Firebase console) | no |
| See another student's registrations | no (enforced by app queries + database rules) | no |

No organizer, admin, or guest roles exist in code (**Verified**: no role field,
no admin screens, `firestore.rules` denies all client event writes).

## 4. Core Features

1. **Account & login** — email/password signup, login, logout; clear error
   messages; session persists via Firebase Auth. Code: `lib/data/services/auth_service.dart`,
   `lib/ui/features/auth/`.
2. **Browse events** — scrollable cards (photo, category, name, date/time,
   location, 2-line description, Registered/Ended badges) with loading spinner,
   error retry, and empty message. Code: `lib/ui/features/discover/`,
   `lib/ui/core/widgets.dart` (`EventCard`).
3. **Filter by category** — All + Academic, Sports, Seminar, Organization,
   Entertainment chips. Code: `Event.categories`, `DiscoverViewModel.filtered`.
4. **Event details + location** — full info, hero image, register/cancel button
   (or "Registration closed" for past events), "Open location in Maps" button
   using coordinates when present, address search otherwise. Code:
   `lib/ui/features/detail/views/detail_view.dart`, `lib/data/services/maps_launcher.dart`.
5. **Registration** — one tap on an upcoming event; saved to Firestore linked to
   the student's ID; duplicates blocked; Snackbar confirmation; reminder
   scheduled. Code: `MyEventsViewModel.register`.
6. **My Events** — upcoming registrations (name/date/time/location), tap to
   details, swipe-to-delete to cancel. Code: `RegistrationsList(showPast:
   false)`.
7. **Event History** — same cards for events whose date/time passed; not
   swipeable. Code: `RegistrationsList(showPast: true)`.
8. **Reminders** — one local notification per registration, 1 hour before
   start; permission is requested but never blocks registration; cancelling
   removes the reminder. Code: `lib/data/services/notification_service.dart`.
   Limitation: reminders do not fire on the web build.

## 5. Business Concepts and Terminology

| Term | Meaning | Where defined |
|---|---|---|
| Event | A school activity with name, category, scheduled date/time, venue, description, photo | `lib/domain/models/event.dart` |
| Category | One of Academic, Sports, Seminar, Organization, Entertainment (+ All = no filter) | `event.dart:32-39` |
| Registration | A link between one student ID and one event ID, `status: 'registered'` | `lib/domain/models/registration.dart` |
| Doc ID `studentId_eventId` | The registration's database key; its uniqueness *is* the duplicate guard | `registration.dart:23-24` |
| Upcoming / History | Upcoming = event date/time is in the future; History = in the past — decided by the event clock, not by attendance tracking | `event.dart:41`, `my_events_view_model.dart:36-47` |
| Reminder | Local phone notification scheduled 1h before start, ID derived from event ID | `notification_service.dart:20-24` |
| Mock mode | In-memory fake backend used when Firebase can't initialize (e.g., fresh clone without config) | `lib/main.dart:23-57` |

## 6. End-to-End Workflows

### W1. Signup → browse → register → reminded (primary journey)

1. **Trigger:** student opens the app signed out → `AuthGate`
   (`lib/main.dart:95-104`) shows `AuthView`.
2. Student signs up/logs in → `AuthViewModel` calls `AuthService`, UID is
   stored from the auth-state stream; inline validation plus friendly server
   error strings on failure. Fields stay explicitly enabled outside loading
   and stale errors clear as the user retypes. "Forgot password?" opens a
   dialog that sends a reset link without leaving login.
3. `HomeShell` shows Discover under a persistent "EventHub" app bar; `DiscoverViewModel.load()` subscribes to the
   `events` collection ordered by date (`lib/data/services/event_repository.dart:18-28`);
   the search field filters name/category/venue/address/description and the
   Category dropdown shows live counts; combined filters narrow together, and "Clear filters"
   resets both. A zero-result combination shows "No events found." (kept
   distinct from load errors).
4. Student taps a card → `/detail` route with event ID → `DetailView` looks the
   event up across loaded lists, shows past-vs-register state and the Maps button.
5. Student taps Register → `MyEventsViewModel.register`
   (`my_events_view_model.dart:70-104`): rejects past events; writes doc
   `{studentId_eventId}` (`registration_repository.dart:41-58`); on duplicate
   reports "already registered"; requests notification permission and schedules
   the 1-hour reminder; reloads lists; Snackbar confirms.
6. **Outputs:** Firestore `registrations` doc; scheduled OS notification; entry
   in My Events. **Errors:** past/duplicate/failed notices; denial-tolerant
   reminder ("Enable notifications to get reminders").

### W2. Cancel a registration (confirmed)

Swipe in My Events (or Cancel on the detail screen) first shows a
"Cancel Registration?" dialog (`confirmCancelRegistration`). Dismissal/Keep
changes nothing. Only explicit confirmation reaches
`MyEventsViewModel.cancel`, which deletes the Firestore doc and cancels the
reminder → lists reload → "Registration cancelled." Snackbar. History is
date-derived, unaffected by cancellation records.

### W3. History fills automatically

No user action: once an event's `dateTime` passes, its joined entry moves from
`upcoming` to `history` on the next `load()` (`_joined`, `my_events_view_model.dart:36-47`).
Registrations for deleted/missing events are silently skipped
(`my_events_view_model.dart:39-40`).

### W4. Offline / misconfigured backend

If Firebase init throws, the app silently uses mock services with sample data
(`lib/main.dart:29-32,47-55`) — the UI works but accounts/registrations are
device-local and reset on restart. If Firestore reads fail mid-session, each
list shows its error state with retry affordance.

### W5. Forgot password

Login → "Forgot password?" → dialog prefilled with the typed email → "Send
reset link" → `AuthViewModel.sendPasswordReset` calls Firebase
`sendPasswordResetEmail`; success shows "Password reset email sent. Check your
inbox." with Done; failures (bad format, rate limit, offline) show mapped
messages. Unknown addresses get the generic sent-message (no enumeration).

## 7. System Inputs and Outputs

- **Inputs:** email + password (validated: email shape, ≥6 chars); category
  selection; taps/swipes; notification permission grant/deny; staff-entered
  Firestore `events` docs (console).
- **Outputs:** Firestore `registrations` creates/deletes; scheduled/cancelled
  local notifications; external Maps URL launch; Snackbar confirmations;
  filtered/joined event lists on screen.
- **No reports, files, emails, or server events** are produced.

## 8. External Integrations

| Service | Why | Data exchanged | On failure |
|---|---|---|---|
| Firebase Auth | identity | email/password ↔ UID + session | user-facing error strings |
| Cloud Firestore | catalog + registrations | event docs read; registration docs read/write/delete | error states; mock fallback only at startup |
| OS notifications | reminders | title/body/time, cancel by ID | skipped silently; registration unaffected |
| Google Maps (URL) | venue directions | lat/lng or address query | `false` → "Could not open maps." |
| GitHub Pages | website hosting | static build output | N/A (outside app) |

Firebase Storage is **not** integrated (dependency declared, never imported;
images are bundled in `assets/images/`).

## 9. Important Business Rules

1. Only signed-in students can see or touch any data (app gate + `request.auth
   != null` rules).
2. One registration per student per event (deterministic doc ID, checked in app
   and enforced in rules).
3. Past events cannot be registered for (client check + disabled button).
4. History is date-derived; there is no attendance verification.
5. One reminder per registration, 1 hour before; denial never blocks
   registration; cancel removes the reminder.
6. A student can only read/delete their own registrations (query filter +
   per-doc rules); events are read-only for all clients.
7. Categories are a closed set; unknown categories simply never match a filter.

## 10. Current Implementation Status

- **Implemented (verified in code + tests):** all 8 MVP user stories — auth
  (+ password reset), browse (+ search, counted dropdown filter,
  clear-filters), filter, details + maps + Google Calendar link, register
  without duplicates, My Events, confirmed cancel + reminder cancel, history,
  permission-tolerant reminders, per-student privacy. Sunny Day theme (with
  persisted light/dark toggle) + green registered indicators throughout.
- **Partially implemented:** realtime updates — Discover streams events live,
  but My Events reloads by fetch-after-mutate (unused `watchForStudent` stream
  exists but is unwired); web build has no reminders.
- **Planned (repo evidence only):** nothing — no TODOs, roadmap, or unfinished
  branches found in code.
- **Unknown (needs live verification):** notification delivery on real devices;
  exact Firestore console contents; `gh-pages` serving state.

## 11. Known Limitations and Open Questions

1. Fresh clones lack `android/app/google-services.json` (gitignored) — Android
   Firebase builds need it re-added; mock mode covers development.
2. `tool/seed_events.json` does not match the live Firestore shape (legacy
   dates, placeholder image URLs) — do not seed from it verbatim.
3. A Firebase outage at startup is invisible (silent mock fallback) — operators
   get no error signal.
4. Web reminders unsupported by design (no system notification path on web).
5. Calendar export is Google-URL only; Apple `.ics` needs file-sharing
   dependencies not yet added. Event end time is a documented 2-hour fallback
   (`CalendarLauncher.defaultEventDuration`), not database data.
5. **Open questions for stakeholders:** event photo update process now that
   images are app-bundled (requires app release, not just a console edit);
   whether an in-app event-creation flow will ever be wanted; target regions
   for Firestore/notification timezone correctness.

## 12. System Glossary and Reference Map

Event, Category, Registration, Upcoming/History, Reminder, Mock mode — defined
in §5. Implementation pointers: auth → `lib/data/services/auth_service.dart`
+ `lib/ui/features/auth/`; catalog → `event_repository.dart` +
`lib/ui/features/discover/`; registration lifecycle → `registration_repository.dart`
+ `MyEventsViewModel` + `firestore.rules`; presentation → `lib/ui/core/`;
app shell/routing → `lib/main.dart`.
