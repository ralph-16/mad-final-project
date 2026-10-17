# DEMO_SETUP.md

> Presentation-day setup for the EventHub final demo. One demo account, one
> pre-registered past event (History tab), live registration of an upcoming
> event, all persisted in Firebase. No passwords, keys, or tokens are stored
> here — or anywhere in this repo.

## 1. Purpose

Reach this state before presenting: sign in once as the demo student, show a
previously registered event in **History**, then register live for a separate
upcoming event and watch it appear in **My Events**. Both records persist in
Firestore under the app's real Firebase project.

## 2. Firebase project and environment

- **App project (verified in code):** `mad-project-83ad2` — see
  `lib/firebase_options.dart` and `firebase.json`. There is **no**
  staging/dev project configured; the demo runs against this same project.
- **Console check (owner):** open Firebase Console and confirm the selected
  project is `mad-project-83ad2` before touching any data.
- **Rules:** must be the published `firestore.rules` from this repo
  (events auth-read-only; registrations owner-only with `studentId_eventId`
  IDs). If registration fails live, re-check this first.
- Do not edit data in any other project. Never delete unrelated events or
  registrations.

## 3. Demo account (manual — console)

I cannot create Firebase users from here, so do this once in console:

1. Firebase Console → **Authentication → Users → Add user**.
2. Email/password of your choice (e.g. a `demo@school.edu` address). **Keep
   the password private — it is never committed.**
3. Open the new user row and **copy its UID** — you need it in §5. Paste it
   into a private note, not into any repo file.

Verify: the account signs in through the app (see §7).

## 4. Event schema (verified against `lib/domain/models/event.dart`)

| field | type in console | notes |
|---|---|---|
| `name` | string | card title |
| `category` | string | exact: Academic, Sports, Seminar, Organization, Entertainment |
| `dateTime` | **timestamp** | required for ordering + past/upcoming split |
| `locationName` | string | venue |
| `address` | string | Maps fallback when no coords |
| `latitude` / `longitude` | number (`double`) | omit both rows when none |
| `description` | string | 2-line card preview + full detail text |
| `imageUrl` | string | local asset path, e.g. `assets/images/quiz-bee.jpg` |

`tool/seed_events.json` now mirrors this shape (ISO strings stand in for
Timestamps — pick **timestamp** type when entering `dateTime` in console).

## 5. Historical event + registration (manual — console)

The app blocks registering for past events, so this record is created by
hand — never through the app, never by weakening rules.

**Event** (reuse the existing doc if present; otherwise create it):
`events/evt-past-robotics` — Robotics Workshop (Past), Academic,
`dateTime` = timestamp **Oct 1 2026 10:00** (past relative to today Oct 15
2026), Engineering Lab 3, `imageUrl` = `assets/images/robotics-past.jpg`.

**Registration** (Firestore → `registrations` → **Add document**):
- Document ID: `<PASTE-YOUR-UID-HERE>_evt-past-robotics`
- `studentId` (string) = the UID from §3
- `eventId` (string) = `evt-past-robotics`
- `registeredAt` (timestamp) = any past time, e.g. Sep 28 2026 09:00
- `status` (string) = `registered`

The ID format and `status` value are enforced by `firestore.rules`
(`registrationId == studentId_eventId`, `status == 'registered'`) and mirror
`Registration.docId` / `toMap` — any deviation fails silently at read time.

## 6. Upcoming events (manual — verify, create only if missing)

These should already exist from setup (all November 2026, i.e. upcoming):

| doc ID | name | category |
|---|---|---|
| `evt-org-fair` | Student Organization Fair | Organization |
| `evt-academic-quiz` | Inter-School Quiz Bee | Academic |
| `evt-seminar-web` | Web Development Seminar | Seminar |
| `evt-sports-fest` | Intramurals Basketball Finals | Sports |
| `evt-music-night` | Acoustic Night | Entertainment |

Requirements for demo day: ≥2 upcoming events visible in Discover; **at
least one with NO registration for the demo UID** (check: Firestore →
`registrations` → filter `studentId == <UID>` — confirm an upcoming
`eventId` is absent). Suggested live target: `evt-academic-quiz`. Do not
pre-register it. Do not delete anything to "clean up" — only add missing docs.

## 7. Verify in console, then in app

Console: `events` shows 6 docs with `dateTime` type = timestamp;
`registrations` shows exactly one doc for the demo UID (the history one).

App (physical device or emulator recommended for the reminder):
1. Sign in as the demo account.
2. **Mock-mode check:** Discover must show YOUR console events (Nov dates,
   real photos). Relative "X days from now" sample events with no photos =
   mock mode = Firebase init failed — stop and see §9.
3. Open **History** → the past event appears with Registered badge.
4. Discover → open `evt-academic-quiz` → Register → success Snackbar →
   green Registered row → **My Events** shows it.
5. Sign out, sign back in → both lists intact (persistence proven).

## 8. Presentation sequence (~5 min)

1. Sign in as demo student (mention one account for everything).
2. Discover: scroll cards, dropdown counts, search "quiz", Clear filters.
3. **History tab**: pre-registered past event — "registered before today".
4. Detail of `evt-academic-quiz` → Register live → Snackbar + green status.
5. **My Events**: new entry present; swipe → confirmation dialog → Keep
   (do NOT cancel live on stage).
6. Log out/in quickly only if time permits (already verified in §7).

## 9. Troubleshooting

| Symptom | Cause → fix |
|---|---|
| Sample events / no photos | mock mode: no network, wrong project, or missing config → check connection + `mad-project-83ad2` selection |
| History empty | registration UID ≠ signed-in UID, or `eventId` typo, or event `dateTime` not actually past → re-check §5 fields character by character |
| "Registration failed" live | stale `firestore.rules` in console → republish from repo; or event doc missing `dateTime` timestamp |
| "Already registered" on stage | someone pre-registered the target → pick a different upcoming event per §6 |
| Login blocked on website | add the site domain under Auth → Authorized domains |
| Reminder never fires | permission denied (registration still valid — say so) or web build (no web reminders by design) |

## 10. Remaining manual steps (owner)

- [ ] Create demo Auth user, record UID privately (§3).
- [ ] Verify/publish `firestore.rules` in console.
- [ ] Verify or create `evt-past-robotics` (§5).
- [ ] Create the `<UID>_evt-past-robotics` registration doc (§5).
- [ ] Confirm ≥1 upcoming event has no registration for the UID (§6).
- [ ] Run the §7 app verification on the presentation device/network.
