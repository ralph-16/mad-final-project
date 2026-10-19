# EventHub — Easy Code Summary

> **Who this is for:** every member of the team.
> **Read time:** about 20 minutes.
> **Why it exists:** so nobody gets asked *"how does this part actually work?"* and
> has to guess. Every important file and every important function is explained in
> plain English, step by step.
>
> **📎 Companion doc:** [`easy_widget_guide.md`](./easy_widget_guide.md) — every
> **widget** (visual component) in the project, with ASCII mockups of what it looks
> like on screen and its exact location. Read this one if you need to explain or edit
> the UI.
>
> If a question is not answered here, say so and we will add it.

---

## Table of contents

1. [What the app does (10-second version)](#1-what-the-app-does-10-second-version)
2. [The whole app in one picture](#2-the-whole-app-in-one-picture)
3. [Words you need to know](#3-words-you-need-to-know)
4. [Folder map — what lives where](#4-folder-map--what-lives-where)
5. [The 4 layers (the big rule)](#5-the-4-layers-the-big-rule)
6. [The Real-vs-Fake trick](#6-the-real-vs-fake-trick-why-two-implementations)
7. [File-by-file guide](#7-file-by-file-guide)
8. ["Walk me through it" — every user action step by step](#8-walk-me-through-it--every-user-action-step-by-step)
9. [What is stored in the database](#9-what-is-stored-in-the-database)
10. [Security rules, explained](#10-security-rules-explained)
11. [Notifications and reminders](#11-notifications-and-reminders)
12. [Tests — what they prove](#12-tests--what-they-prove)
13. [The demo seed script](#13-the-demo-seed-script)
14. [Design decisions and the "why" behind them](#14-design-decisions-and-the-why-behind-them)
15. [Known quirks (be honest, not perfect)](#15-known-quirks-be-honest-not-perfect)
16. ["I want to change X — edit which file?"](#16-i-want-to-change-x--edit-which-file)
17. [Q&A cheat sheet for demos and viva](#17-qa-cheat-sheet-for-demos-and-viva)

---

## 1. What the app does (10-second version)

**EventHub** is a Flutter app where a student can:

1. Create an account / log in with email + password.
2. Browse school events (seminar, sports, academic, org fair, entertainment).
3. Filter by category and search by name, venue or description.
4. Open an event to see full details, and **register** for it.
5. Get a phone notification right away + a reminder **1 hour before** the event starts.
6. Cancel a registration (with a confirmation popup first).
7. See registered events in **My Events** and old events in **History**.
8. Open the venue in **Google Maps** and add the event to **Google Calendar**.
9. Switch between **light and dark mode** (the choice is remembered).
10. Forget their password and get a reset email.

**Events themselves are added by staff directly in the Firebase console.** There is
no "create event" button in the app — this was a deliberate decision (see
[§14](#14-design-decisions-and-the-why-behind-them)).

---

## 2. The whole app in one picture

### 2.1 What happens the second you open the app

```
App starts
   │
   ├─► main.dart tries to start Firebase
   │      ├─ Works?  → use the REAL Firebase services
   │      └─ Fails?  → use the MOCK (fake, in-memory) services
   │                   (app still runs, data is not saved)
   │
   ├─► ThemeController loads your saved light/dark choice
   │
   └─► AuthGate asks one question: "Is anyone logged in?"
          │
          ├─ NO  → AuthView (login / sign up screen)
          └─ YES → HomeShell (the 3-tab app)
```

### 2.2 The 3 tabs

```
┌──────────────────────────────────────────────┐
│  [logo] EventHub        [theme]  [log out]   │  ← AppBar
├──────────────────────────────────────────────┤
│                                              │
│            content of the active tab         │
│                                              │
├──────────────────────────────────────────────┤
│  🔍 Discover   🔖 My Events   🕘 History      │  ← NavigationBar
└──────────────────────────────────────────────┘
```

| Tab | Shows | File |
|---|---|---|
| Discover | All events, search bar, category dropdown | `discover_view.dart` |
| My Events | Events you registered for that **haven't happened yet** | `registrations_list.dart` (`showPast: false`) |
| History | Events you registered for that **already happened** | `registrations_list.dart` (`showPast: true`) |

Tapping any event card anywhere opens the **detail screen**.

### 2.3 How data flows (the single most important idea)

```
   UI (screens)  ──calls──►  ViewModel (logic + memory)  ──calls──►  Repository
   discover_view.dart          discover_view_model.dart              event_repository.dart
   detail_view.dart            my_events_view_model.dart             registration_repository.dart
   auth_view.dart              auth_view_model.dart                  auth_service.dart
                                                                        │
                                                                        ▼
                                                              Firebase Firestore
                                                              (the real database)
```

**Rule:** screens never talk to Firebase directly. They call a ViewModel.
ViewModels never talk to Firebase directly. They call a Repository.
Only repositories touch Firebase.

Why? So you can swap the database without rewriting the UI, and so you can test
the logic without a real database. See [§6](#6-the-real-vs-fake-trick-why-two-implementations).

---

## 3. Words you need to know

You will hear these in any Flutter project. Plain definitions:

| Word | What it actually means |
|---|---|
| **Widget** | A piece of screen. A button is a widget, a text label is a widget, the whole page is a widget. Everything in Flutter is a widget. |
| **StatelessWidget** | A screen that never changes on its own. It just draws what you give it. Example: `DetailView`, `EventCard`. |
| **StatefulWidget** | A screen that *does* remember things (like "is the password hidden?", "which tab is selected?"). Example: `AuthView`, `HomeShell`. |
| **State** | The memory of a StatefulWidget. Lives in `createState()`. |
| **`initState()`** | Runs **once**, the first time the widget appears. Used to kick off data loading. |
| **`dispose()`** | Runs when the widget goes away. Used to clean up (cancel subscriptions, dispose text controllers) so we don't leak memory. |
| **`build()`** | The function that says *"what does this screen look like?"*. Flutter calls it again whenever something changes. |
| **`setState()`** | The command inside a StatefulWidget that says *"I changed, redraw me"*. |
| **Provider** | The library we use to share state between screens. A ViewModel is put in Provider once, and any screen can `watch` or `read` it. |
| **`context.watch<T>()`** | *"Give me T and rebuild me whenever T changes."* Use for display. |
| **`context.read<T>()`** | *"Give me T so I can call a method on it."* Use for button presses. It does NOT rebuild. |
| **ChangeNotifier** | The simple class Provider uses to say *"I changed, update the screens."* You call `notifyListeners()` after changing anything. |
| **ViewModel** | Our name for the middle layer. It holds the screen's data and does the thinking. |
| **Repository** | Our name for the class that reads/writes the database. |
| **Stream** | A "live feed" of values. Like a YouTube live chat: it keeps sending you new values whenever something changes, instead of you asking once. |
| **`Future`** | A "value that arrives later" — like a promise. `await` means *"wait for this to finish before continuing"*. |
| **`async` / `await`** | Marks code that has to wait for the internet. |
| **Firestore** | Google's cloud database. Think of it as folders → documents → fields. |
| **Firestore rules** | Security rules written in a special language that the database enforces. Even if the app tried to cheat, the database would refuse. |
| **Mock / Fake service** | A stand-in that keeps data in memory instead of the cloud. Used for tests and for running the app without Firebase setup. |
| **Material 3** | The design style Flutter uses. We turned it on with `useMaterial3: true`. |
| **Slash route** | A named screen address like `'/detail'`. You push it with `Navigator.pushNamed('/detail', arguments: eventId)`. |

---

## 4. Folder map — what lives where

```
mad_final_project/
│
├── lib/                         ← ALL the Dart/Flutter code lives here
│   │
│   ├── main.dart                ← Entry point. Starts Firebase, sets up Provider, shows the app.
│   ├── firebase_options.dart    ← Auto-generated Firebase keys. Do not hand-edit.
│   │
│   ├── domain/models/           ← LAYER 3: what an "Event" and a "Registration" ARE
│   │   ├── event.dart
│   │   └── registration.dart
│   │
│   ├── data/services/           ← LAYER 2: the code that talks to the outside world
│   │   ├── auth_service.dart              (login / register / reset password)
│   │   ├── event_repository.dart          (read events)
│   │   ├── registration_repository.dart   (read / write registrations)
│   │   ├── notification_service.dart      (reminders)
│   │   ├── maps_launcher.dart             (open Google Maps)
│   │   └── calendar_launcher.dart         (add to Google Calendar)
│   │
│   └── ui/                      ← LAYER 4 + 1: everything you see
│       ├── core/
│       │   ├── theme.dart              (all colours, both light and dark)
│       │   ├── theme_controller.dart   (remembering light/dark choice)
│       │   └── widgets.dart            (shared UI pieces: EventCard, EmptyState…)
│       │
│       └── features/            ← one folder per feature
│           ├── auth/
│           │   ├── view_models/auth_view_model.dart
│           │   └── views/auth_view.dart
│           ├── discover/
│           │   ├── view_models/discover_view_model.dart
│           │   └── views/discover_view.dart
│           ├── my_events/
│           │   ├── view_models/my_events_view_model.dart
│           │   └── views/registrations_list.dart
│           └── detail/
│               └── views/detail_view.dart     (no ViewModel — reuses others)
│
├── test/                        ← 27 automated tests (see §12)
├── scripts/
│   ├── seed_demo.py             ← Fills the History tab with demo data (see §13)
│   └── service_account.json     ← Firebase admin key (NEVER commit this)
│
├── assets/images/               ← Logo (SVG) + 5 event photos (JPG)
│
├── firestore.rules              ← Database security rules (see §10)
├── pubspec.yaml                 ← List of packages we installed
├── android/ ios/ web/ linux/ macos/ windows/   ← Generated per-platform folders
│
└── CODEBASE_SUMMARY.md, SYSTEM_OVERVIEW.md, DESIGN.md, DEMO_SETUP.md, README.md
                                  ← Other docs (longer, more technical than this one)
```

### The naming convention inside `features/`

Every feature folder has the same two sub-folders:

- `views/` = the **screens** (what you look at)
- `view_models/` = the **logic** (what it does)

`detail/` only has a `views/` folder because the detail screen doesn't need its own
ViewModel — it borrows `DiscoverViewModel` (to find the event) and
`MyEventsViewModel` (to register/cancel). That's intentional, not an oversight.

---

## 5. The 4 layers (the big rule)

Think of it like a restaurant: **customers → waiter → kitchen → supplier**.

| Layer | Folder | May talk to | May NOT talk to |
|---|---|---|---|
| **1. UI (screens)** | `lib/ui/features/*/views/` | ViewModels (via Provider) | Firebase, repositories |
| **2. ViewModels** | `lib/ui/features/*/view_models/` | Repositories + services | Widgets are fine to *notify*, but ViewModels never import a screen |
| **3. Repositories / Services** | `lib/data/services/` | Firebase, device plugins | Screens, ViewModels |
| **4. Models** | `lib/domain/models/` | Nothing (pure data) | Everything |

Plus `lib/ui/core/` = shared building blocks used by any screen.

**If a member asks "why is this in this folder?" — the answer is always this table.**

---

## 6. The Real-vs-Fake trick (why two implementations)

This is the single most likely question you'll be asked, so read it twice.

Every "service" file has this shape:

```dart
abstract class EventRepository {          // ← the CONTRACT: what must be possible
  Stream<List<Event>> watchEvents();
  Future<List<Event>> fetchEvents();
}

class FirestoreEventRepository implements EventRepository { ... }  // ← the REAL one
class MockEventRepository       implements EventRepository { ... }  // ← the FAKE one
```

`abstract class` + `implements` = "these two classes promise to do the same
things". The app only ever talks to the *contract*, so it does not care which one
it got.

Then in `main.dart`:

```dart
final bool firebaseReady = await _initFirebase();   // did Firebase start?

final events = firebaseReady
    ? FirestoreEventRepository(FirebaseFirestore.instance)   // real database
    : MockEventRepository();                                // fake in-memory data
```

### Why bother? Three very good reasons:

1. **The app runs before Firebase is set up.** If Firebase is missing or broken,
   the app still opens with 6 sample events so you can demo the UI immediately.
   `_initFirebase()` wraps `Firebase.initializeApp()` in a `try/catch` and just
   prints a message instead of crashing.
2. **Tests are instant and free.** No internet, no Firebase project, no waiting.
   `test/eventhub_test.dart` creates a `MockEventRepository` in 1 line.
3. **Your logic is provable.** We can prove "registering twice is blocked"
   without a database, because the rule lives in code, not in the cloud.

### What the Fake versions do

| Fake class | Stores data in | Notes |
|---|---|---|
| `MockAuthService` | two `Map`s in memory: email→password, email→uid | Throws `FormatException` with codes like `'weak-password'`, `'invalid-credential'` — the same strings Firebase uses |
| `MockEventRepository` | a hard-coded `List` of 6 events, dates recalculated every call so they're always "future" (one deliberately in the past for History) | |
| `MockRegistrationRepository` | a `Map` keyed by `studentId_eventId` | Same duplicate rule as the real one |
| `NoopNotificationService` | nowhere — every method does nothing and returns immediately | Used by tests |

### How the Fake error codes reach the user

`MockAuthService` throws `FormatException('weak-password')`.
`AuthViewModel._run()` catches `FormatException` and calls `_mockMessage(code)`,
which maps it to *"Password must be at least 6 characters."*
Real Firebase throws `FirebaseAuthException`, which goes through `friendlyAuthError()`.
**Both end up showing the same friendly sentence to the user.** That's why the
login screen looks identical in mock mode and real mode.

---

## 7. File-by-file guide

Every single Dart file in `lib/`, with its size and what it does.

### 7.1 `lib/main.dart` (206 lines) — the entry point

The file the phone runs first. Five things happen here.

**a) `_initFirebase()`** — tries `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
Returns `true` if Firebase started, `false` if it threw. `currentPlatform` picks the
right set of keys for Android / iOS / web automatically.

**b) `main()`** —
```dart
WidgetsFlutterBinding.ensureInitialized();   // let us use async stuff before runApp
final firebaseReady = await _initFirebase(); // start Firebase (or catch failure)
final theme = ThemeController();
await theme.load();                         // restore saved light/dark choice
runApp(EventHubApp(...));                   // show the UI
```

**c) `EventHubApp.build()`** — picks Real vs Fake for each of the 3 services, then
wraps the app in `MultiProvider` so every screen can reach them:

| Provided object | Real (Firebase on) | Fake (Firebase off) |
|---|---|---|
| `ThemeController` | same both ways | same |
| `AuthViewModel` | `FirebaseAuthService` | `MockAuthService` |
| `DiscoverViewModel` | `FirestoreEventRepository` | `MockEventRepository` |
| `MyEventsViewModel` | `FirestoreRegistrationRepository` + real repos | `MockRegistrationRepository` + mock repos |

Below the providers sits `MaterialApp` with:
- `theme: EventHubTheme.light()`, `darkTheme: EventHubTheme.dark()`,
  `themeMode: context.watch<ThemeController>().mode`
- `home: const AuthGate()`
- `onGenerateRoute:` — the only named route in the app. `'/detail'` with a `String`
  argument becomes `DetailView(eventId: …)`. Anything else returns `null`.

**Why the `Builder`?** Because `context.watch<ThemeController>()` is used for the
`themeMode`, and `MaterialApp` sits *below* the providers. A plain `context` from
`build()` would be above them. `Builder` creates a fresh `context` underneath the
providers. (Same trick is used in `discover_view.dart` and `detail_view.dart`.)

**d) `AuthGate`** — a 10-line widget whose entire job is:
```dart
final signedIn = context.watch<AuthViewModel>().signedIn;
if (!signedIn) return const AuthView();
return const HomeShell();
```
Because it `watch`es, the moment Firebase reports a login it rebuilds and swaps the
whole screen automatically. **You never navigate to the home screen manually.**

**e) `HomeShell`** — the 3-tab shell. Contains:
- `initState()` → `addPostFrameCallback` → if a user is signed in, calls
  `MyEventsViewModel.load(userId)`. This is why the "Registered" badge shows up on
  Discover cards immediately, even before you visit the My Events tab.
  (`addPostFrameCallback` = "run this after the first screen is drawn", because
  `context.read` is not safe before that.)
- `AppBar` with the SVG logo, a **theme toggle** button and a **log out** button.
- `body: SafeArea(child: pages[_tab])` — only the selected tab is drawn.
- `NavigationBar` with the 3 destinations.
- `_openDetail(eventId)` → `Navigator.pushNamed('/detail', arguments: eventId)`.

### 7.2 `lib/domain/models/event.dart` (105 lines) — what an Event IS

```dart
class Event {
  final String id, name, category, locationName, address, description, imageUrl;
  final DateTime dateTime;
  final double? latitude, longitude;   // nullable = may not exist
}
```

**Two computed getters** (values calculated on demand, not stored):
- `bool get isPast => dateTime.isBefore(DateTime.now());` — the single source of
  truth for "has this happened?". Used for the History tab, the "Ended" badge and
  closing registration.
- `bool get hasCoordinates => latitude != null && longitude != null;` — decides
  whether Maps opens by pin or by text search.

**`Event.fromMap(id, map)`** — turns a raw database document into an `Event`.
It accepts **three** date shapes so old documents keep working:
1. `dateTime` as a Firestore `Timestamp` (the current format)
2. `dateTime` as a `String`
3. legacy `{date: '2026-11-15', startTime: '09:00'}` — combined by `_fromLegacy()`

If all three fail it falls back to `DateTime.now()` so the app never crashes on a
bad row. **Every field is read with `?? ''` for the same reason.**

**`Event.toMap()`** — the reverse, used when writing.

**Three free helper functions at the bottom of the file:**
- `bool isAssetImage(String path) => path.startsWith('assets/')` — decides
  `Image.asset` vs `Image.network`. This is how local photos and web links both work.
- `String formatEventDate(DateTime)` → `"Nov 15, 2026"` (a hand-written month list
  so we don't need the `intl` package).
- `String formatEventTime(DateTime)` → `"9:00 AM"`.

### 7.3 `lib/domain/models/registration.dart` (44 lines) — what a Registration IS

Tiny file. Links **a student to an event**.

```dart
class Registration {
  final String id, studentId, eventId, status;
  final DateTime registeredAt;
  static const statusRegistered = 'registered';

  static String docId(String studentId, String eventId) => '${studentId}_$eventId';
}
```

**`docId()` is the most important line in the whole file.** Because the document
name is *derived* from the student and the event, a student can physically only have
one document per event. Registering twice writes to the *same* document — the
database itself makes duplicates impossible. This is checked in **two** places:

1. **In the app** — `FirestoreRegistrationRepository.register()` does a `.get()`
   first and throws `DuplicateRegistration` if the doc already exists.
2. **In the database** — `firestore.rules` has
   `registrationId == request.resource.data.studentId + '_' + request.resource.data.eventId`.
   Even a hacked app cannot create a duplicate.

### 7.4 `lib/data/services/auth_service.dart` (155 lines) — logging in

| Class / function | Role |
|---|---|
| `abstract class AuthService` | The contract: `userIdChanges` (stream), `currentUserId`, `signUp`, `signIn`, `signOut`, `sendPasswordReset` |
| `FirebaseAuthService` | Real implementation, ~30 lines, each method a one-liner delegating to `FirebaseAuth` |
| `MockAuthService` | In-memory fake. Throws `FormatException` with Firebase-style codes |
| `String friendlyAuthError(Object e)` | Turns `FirebaseAuthException` into a human sentence |
| `String friendlyResetError(Object e)` | Same, for reset emails |

**The two error mappers are a security feature.** `friendlyResetError` deliberately
returns *"If an account exists for this email, a reset link has been sent."* for the
`user-not-found` case — **not** *"No account found."* That way an attacker can't type
random emails and discover which ones are registered. Same for login:
`user-not-found` and `wrong-password` both become *"Incorrect email or password."*
so it never reveals which half was wrong.

Full mapping table:

| Firebase code | What the student sees |
|---|---|
| `invalid-email` | Enter a valid email address. |
| `user-not-found` / `wrong-password` / `invalid-credential` | Incorrect email or password. |
| `email-already-in-use` | An account with this email already exists. Try logging in. |
| `weak-password` | Password must be at least 6 characters. |
| `network-request-failed` | No network connection. Check and try again. |
| anything else | Authentication failed (code). Try again. |

### 7.5 `lib/data/services/event_repository.dart` (122 lines) — reading events

`watchEvents()` returns a **Stream** — Firestore pushes a fresh list every time
anything in the `events` collection changes, so if staff add an event in the console,
the student's phone updates by itself. **No pull-to-refresh needed** (we have one
anyway as a safety net).

`.orderBy('dateTime')` sorts by date automatically at the database level, so the
cheapest possible list comes back.

`MockEventRepository` returns 6 hard-coded events. Note the helper:
```dart
DateTime days(int d, int h) {           // d = days from now (can be negative)
  final base = now.add(Duration(days: d));
  return DateTime(base.year, base.month, base.day, h);
}
```
Because dates are recomputed **on every call**, the sample events are always in the
future no matter when you run the app. One uses `days(-4, 10)` — deliberately in the
past — so the History tab is never empty in mock mode.

### 7.6 `lib/data/services/registration_repository.dart` (120 lines) — the core of the app

`register(studentId, eventId)` in ~12 lines, and every line matters:

```dart
final ref = _col.doc(Registration.docId(studentId, eventId));  // 1. where it goes
try {
  final existing = await ref.get();                            // 2. already there?
  if (existing.exists) throw const DuplicateRegistration();     // 3. block it
} on FirebaseException catch (e) {
  if (e.code != 'permission-denied') rethrow;                  // 4. tolerate old rules
}
await ref.set(Registration(...).toMap());                       // 5. write it
```

Line 4 is defensive: an *older published* version of our security rules denied `get`
on documents that don't exist yet. Rather than crashing, we treat `permission-denied`
as "not registered" and let the `create` rule do the real check. The current rules
(`get` allows `resource == null`) already permit it, but the guard keeps old
deployments working.

`cancel()` is just `.delete()` on the same computed document ID.
`isRegistered()` is a `.get()` returning `exists`.

**Notice what is NOT here:** no sign-in check, no student-id check. That's not an
oversight — the database refuses those requests itself (see [§10](#10-security-rules-explained)).

### 7.7 `lib/data/services/notification_service.dart` (220 lines) — reminders

**Contract:** `requestPermission()`, `showNow()`, `scheduleReminder()`, `cancelReminder()`.

**Four free functions, all unit-tested or trivially inspectable:**

```dart
int reminderIdFor(String eventId)      => eventId.hashCode & 0x7fffffff;
int confirmationIdFor(String eventId)  => reminderIdFor(eventId) ^ 0x1fffffff;
DateTime reminderTimeFor(DateTime start) => start.subtract(const Duration(hours: 1));
String timeUntilLabel(DateTime when)   // 'very soon' / 'in 45 min' / 'in 3 hrs 20min' / 'in 2 days'
```

**Why two different ID functions?** Notifications are cancelled by ID. If the
"you're registered" popup and the "event tomorrow" reminder shared an ID, showing
one would replace or cancel the other. `^ 0x1fffffff` flips the top bit, so the
confirmation ID can never equal the reminder ID for the same event.

**`_ensureReady()`** is called before every operation: loads the timezone database
(`tzdata.initializeTimeZones()`) and initializes the plugin, once, then caches the
result in `_ready`.

**Permission is requested on register, not on app start.** We ask when the student
actually wants something from us.

### 7.8 `lib/data/services/maps_launcher.dart` (28 lines)

Two branches: if the event has coordinates, open a pin; otherwise search by text.

```dart
if (event.hasCoordinates) {
  '…/maps/search/?api=1&query=${lat},${lng}'       // exact pin
} else {
  '…/maps/search/?api=1&query=${Uri.encodeComponent(address)}'  // text search
}
await launchUrl(uri, mode: LaunchMode.externalApplication);
```

`Uri.encodeComponent` escapes spaces and special characters so the URL is valid.
Falls back to `locationName` if `address` is empty. Returns `false` on failure so
the screen can show "Could not open maps."

### 7.9 `lib/data/services/calendar_launcher.dart` (59 lines)

Builds a **Google Calendar template URL** that opens a pre-filled "save this event"
page. No plugin, no `.ics` file writing — works on Android, iOS and web identically.

```dart
static Uri googleCalendarUrl(Event event) {
  final start = event.dateTime.toUtc();
  final end = start.add(defaultEventDuration);   // 2 hours
  return Uri.https('calendar.google.com', '/calendar/render', {
    'action': 'TEMPLATE',
    'text': event.name,
    'dates': '${_stamp(start)}/${_stamp(end)}',  // yyyyMMddTHHmmssZ
    if (event.description.isNotEmpty) 'details': event.description,
    if (event.address.isNotEmpty) 'location': '${event.locationName}, ${event.address}'
    else if (event.locationName.isNotEmpty) 'location': event.locationName,
  });
}
```

Two things worth knowing:
- **Why UTC?** `_stamp()` appends a literal `Z`. If we sent local time with a `Z`,
  Google would shift the event by your timezone offset.
- **Why 2 hours?** `Event` has no end time. `defaultEventDuration` is a documented
  constant for exactly that. Change the constant, not the model.
- **Apple Calendar / `.ics` export is intentionally out of scope** — it needs file
  writing + a share sheet (`share_plus`), which was judged disproportionate for this
  MVP. This is written in the file's doc comment on purpose.

`googleCalendarUrl()` is a *pure* function (no launching), which is why the tests can
assert on the exact URL string.

### 7.10 `lib/ui/core/theme.dart` (201 lines) — all the colours

One class, `EventHubTheme`, holding every colour as a named constant so no screen
ever hard-codes a hex code.

Light mode: white background, orange primary `#EA580C`, hairline borders, flat cards
(`elevation: 0`).
Dark mode: charcoal `#1B130C` background, same orange identity lightened to `#FFA94D`
so contrast stays readable.

`light()` and `dark()` each build a `ColorScheme` and then a `ThemeData` with
`useMaterial3: true`, then `copyWith` to style AppBar, Card (20px radius, 1px
border), Chips, buttons (48px min height — accessibility), SnackBar (floating), the
Dialog (24px radius) and the NavigationBar. Both modes share `_inputs(scheme)` so
text fields look identical in each theme.

Look for `Theme.of(context).colorScheme.primary` anywhere in a screen — that's the
pattern that makes dark mode "just work".

### 7.11 `lib/ui/core/theme_controller.dart` (49 lines) — remembering the theme choice

A `ChangeNotifier` with one job.

```dart
ThemeController([this._mode = ThemeMode.light]);
static const _prefsKey = 'eventhub_theme_mode';
```

- `load()` — reads `SharedPreferences` on startup. `SharedPreferences` is the phone's
  tiny built-in key-value storage. `ThemeMode.values.asNameMap()[raw]` converts the
  saved string `"dark"` back into the enum value.
- `setMode(mode)` — changes, calls `notifyListeners()`, then **saves**.
- `toggle()` — `dark → light`, anything else → `dark`.
- `toggleIcon` / `toggleTooltip` — computed getters so the icon always shows what
  you *will switch to*, not what you currently are.

### 7.12 `lib/ui/features/auth/view_models/auth_view_model.dart` (111 lines)

State: `userId`, `signedIn` (`userId != null`), `isLoading`, `errorMessage`,
plus separate `resetError` / `resetInfo` for the reset dialog.

The constructor subscribes to the auth stream:
```dart
AuthViewModel(this._auth) {
  _sub = _auth.userIdChanges.listen((id) { userId = id; notifyListeners(); });
  userId = _auth.currentUserId;     // catch up if already logged in
}
```
This is why the app opens straight to the home screen after a restart without any
"check login" code — the stream fires with the existing UID.

`_run()` is the shared body of sign-in and sign-up: clear error, set loading,
`notifyListeners()`, run, catch and translate the error, always clear loading in a
`finally` block. **`finally` guarantees the button never gets stuck spinning.**

`clearError()` is called on every keystroke (`onChanged: (_) => vm.clearError()`) so
an old error never sits over fresh typing.

`dispose()` cancels the subscription — otherwise the stream keeps firing at a
deleted object.

### 7.13 `lib/ui/features/auth/views/auth_view.dart` (316 lines) — login + signup

**One screen for both.** `_isSignup` is a `bool` that flips; the labels and the
button text follow it. `bool _obscure` toggles password visibility.

Structure: `Scaffold → SafeArea → Center → SingleChildScrollView → ConstrainedBox(maxWidth: 420) → Form`.
The max width stops the form stretching absurdly wide on web/desktop.

**Three layers of validation**, which is worth being able to explain:
1. **On the widget** — `validator:` on each `TextFormField` (contains `@` and `.`;
   length ≥ 6). Red text under the field, blocks submit via
   `if (!_formKey.currentState!.validate()) return;`.
2. **In the ViewModel / service** — re-checked, so it holds even if someone calls
   `signUp()` from elsewhere.
3. **In the database** — Firebase Auth enforces it too.

The second half of the file is `_ForgotPasswordDialog`, a private class in the same
file. It prefills the email you already typed, validates, calls
`vm.sendPasswordReset()`, then swaps its own content: the input field disappears and
the success message takes its place, and the button becomes "Done". **It deliberately
reuses `AuthViewModel`'s `resetError`/`resetInfo` instead of creating a separate
ViewModel** — one source of truth for auth state.

### 7.14 `lib/ui/features/discover/view_models/discover_view_model.dart` (106 lines)

Holds the events list and the two filters.

**`filtered` is a getter, not a stored value:**
```dart
List<Event> get filtered {
  final q = searchQuery.trim().toLowerCase();
  return _events.where((e) {
    if (selectedCategory != Event.allCategory && e.category != selectedCategory)
      return false;                       // filter 1: category
    if (q.isEmpty) return true;           // filter 2: search
    return e.name.toLowerCase().contains(q) ||
        e.category.toLowerCase().contains(q) ||
        e.locationName.toLowerCase().contains(q) ||
        e.address.toLowerCase().contains(q) ||
        e.description.toLowerCase().contains(q);
  }).toList();
}
```
Searching five fields is a deliberate choice — students search "library" or "quiz",
not exact titles.

**`counts`** is also computed on demand, so the numbers in the dropdown can never
drift from the data. `All` = total, each category = how many match.

`load()` cancels any previous subscription, then subscribes to
`_repo.watchEvents()`. Because it's a stream, Firebase pushes updates whenever
events change. `onError` sets a friendly message.

`clearFilters()` returns early if nothing is active — no pointless redraws.

### 7.15 `lib/ui/features/discover/views/discover_view.dart` (146 lines)

`RefreshIndicator > CustomScrollView > [Sliver…]` — **slivers** are how Flutter
builds a long scrollable list lazily, instead of building every row at once.

Slivers in order:
1. Search `TextField` (with a clear "×" button when there's text)
2. `DropdownButtonFormField` for category, showing `"Sports (2)"`
   — `key: ValueKey(vm.selectedCategory)` forces the dropdown to rebuild when the
   selection changes externally (e.g. "Clear filters")
3. Then **exactly one** of: loading / error / empty / list

The empty state is smart — it changes its wording based on `hasActiveFilters`:
*"No events found. Try a different search or category."* + a **Clear filters**
button, versus *"No events in this category yet."* with no button.

The list reads `context.watch<MyEventsViewModel>()` too, purely to pass
`registered: mine.isRegistered(event.id)` into each card so the badge is right.

### 7.16 `lib/ui/features/my_events/view_models/my_events_view_model.dart` (137 lines)

The busiest ViewModel. Three injected dependencies: `registrations`, `events`,
`notifications`.

**Two private lists, joined on read:**
```dart
List<Registration> _regs = [];        // "which events is this student in"
Map<String, Event>  _byId = {};       // "all event details, keyed by id"
```
`load(studentId)` fetches **both at the same time** with `Future.wait`, then builds
the lookup map. Fetching them in parallel instead of one after the other halves the
wait.

`_joined({required bool wherePast})` — for each registration, find its event,
skip it if the event no longer exists (deleted in the console), keep it if
`e.isPast == wherePast`, then sort. **Ascending for upcoming (soonest first),
descending for history (most recent first).**

`isRegistered(eventId)` is the one-liner behind every "Registered" badge in the app:
```dart
_regs.any((r) => r.eventId == eventId);
```

**`register()` is the most important function in the app.** Its order of operations is
the answer to "how does registering work?":

```
1. Is the event already past?  → stop, "Registration is closed: this event has passed."
2. Call registrations.register(studentId, event.id)
     ├─ DuplicateRegistration thrown → stop, "You are already registered for this event."
     └─ Any other error            → stop, "Registration failed. Try again."
3. Ask for notification permission
     ├─ GRANTED → show confirmation NOW + schedule the 1-hour reminder
     │            notice = "Registered. Reminder set for 1 hour before."
     └─ DENIED  → notice = "Registered. Enable notifications to get reminders."
4. Reload (load(studentId)) so every screen shows the new state
5. return true
```

**The registration is NOT rolled back if notifications fail.** Step 3 is
best-effort by design — see the comment on line 87. The student's spot is safe; they
just don't get a reminder.

**`cancel()`** deletes the registration **and** `cancelReminder(reminderIdFor(...))`,
so no orphan notification can fire for an event you cancelled.

**`notice` + `takeNotice()`** is a one-shot message channel. The ViewModel can't show
a SnackBar (it has no `context`), so it stores the sentence; the screen calls
`takeNotice()` to read **and clear** it, then shows the SnackBar itself. This is why
every action ends with `vm.takeNotice() ?? (ok ? 'Registered.' : 'Failed.')` — a
safe fallback in case there's no notice.

### 7.17 `lib/ui/features/my_events/views/registrations_list.dart` (111 lines)

**One file serves both the My Events and History tabs**, controlled by
`bool showPast`. Same code, same card, same refresh — only the data source
(`vm.history` vs `vm.upcoming`) and the message text change.

**Swipe-to-cancel** uses `Dismissible`:
- `direction: widget.showPast ? DismissDirection.none : DismissDirection.endToStart`
  — **history is read-only.** You cannot cancel something that already happened.
- Swiping reveals a red bar with a trash icon.
- `confirmDismiss:` opens `confirmCancelRegistration(...)` first.

`_confirmCancel()` is careful about every step:
```dart
final confirmed = await confirmCancelRegistration(context, eventName: event.name);
if (!confirmed || !context.mounted) return false;   // dismissed → nothing happens
final userId = context.read<AuthViewModel>().userId;
if (userId == null || !context.mounted) return false;
final ok = await vm.cancel(userId, event);
if (context.mounted) { …showSnackBar… }
return ok;    // false keeps the card on screen
```
Returning `false` on failure means the card snaps back — the list can never
disagree with the database. `context.mounted` is checked after every `await` because
the student could have navigated away while the network call was in flight.

### 7.18 `lib/ui/features/detail/views/detail_view.dart` (254 lines)

**No ViewModel of its own.** It borrows from two others:

```dart
for (final e in [...discover.all, ...mine.upcoming, ...mine.history]) {
  if (e.id == eventId) { event = e; break; }
}
```
It searches Discover's full list **plus** both of My Events' lists — so a detail page
works no matter which tab you tapped the card from. If the ID isn't found anywhere,
it shows an "Event not found." empty state instead of crashing.

Then the same computed state drives the layout:
```dart
final registered = mine.isRegistered(current.id);
final past      = current.isPast;
```
and the bottom button is chosen by a three-way `if`:
- **past** → disabled button, *"Registration closed — event has passed"*
- **registered** → tonal button, *"Cancel registration"*
- **neither** → filled button, *"Register for this event"*

`_register` / `_cancel` are both the same shape: get the UID → call the ViewModel →
`takeNotice()` → SnackBar. `_cancel` shows the confirmation dialog first.

`_HeroImage` handles three cases in order: empty URL → grey placeholder;
`isAssetImage(...)` → `Image.asset`; otherwise → `Image.network`. All three have an
`errorBuilder`, so a broken image never leaves a red box on screen.

`_InfoRow` is a small private widget: an icon + wrapped text, used for date and venue.

### 7.19 `lib/ui/core/widgets.dart` (409 lines) — shared UI

| Widget | Purpose |
|---|---|
| `EventCard` | The main card. A 220px-tall image filling the whole card, a transparent→black gradient scrim over the bottom so white text is readable, an orange category pill top-left, and a "Registered" / "Ended" pill top-right. Name, date, venue and a one-line description sit **on** the image. |
| `_OverlayBadge` | The translucent black pill behind "Registered"/"Ended". |
| `_ImageHeader` | Picks asset / network / placeholder, with a loading spinner and error fallback. |
| `_CategoryTag` | The orange pill. |
| `CategoryChips` | Horizontal category chips with counts. **Currently unused** — Discover moved to a dropdown, but the widget is kept and documented. Don't delete it without asking. |
| `LoadingState` | Centred spinner + label. |
| `EmptyState` | Icon + message + optional `details` explanation + optional action button (used for "Clear filters"). |
| `confirmCancelRegistration()` | Shared cancel dialog, returns `true` **only** on the red "Cancel Registration" button. Dismiss or "Keep Registration" → `false`. |

---

## 8. "Walk me through it" — every user action step by step

This section is written to be read out loud in a viva.

### 8.1 App launch

```
1. Android/iOS runs lib/main.dart → main()
2. WidgetsFlutterBinding.ensureInitialized()
3. _initFirebase(): try Firebase.initializeApp(...) → true/false
4. ThemeController() created, theme.load() reads SharedPreferences
5. runApp(EventHubApp(firebaseReady, theme))
6. EventHubApp.build() picks Real or Fake services
7. MultiProvider registers ThemeController, AuthViewModel, DiscoverViewModel,
   MyEventsViewModel
8. MaterialApp: light/dark themes + AuthGate as home + '/detail' route
9. AuthGate checks AuthViewModel.signedIn
10a. Not signed in → AuthView
10b. Signed in   → HomeShell → post-frame → MyEventsViewModel.load(uid)
11. DiscoverView appears → its initState → DiscoverViewModel.load() → subscribes
    to the events stream → cards render
```

### 8.2 Sign up

```
auth_view.dart _submit()
  1. _formKey.currentState!.validate()   ← email has @ and ., password ≥ 6
  2. vm.signUp(email, password)
  3. AuthViewModel._run():
       isLoading = true → notifyListeners()   (button spins, fields disable)
       auth.signUp(...)  →  Firebase  OR  Mock
       on error → friendlyAuthError / _mockMessage → errorMessage
       finally → isLoading = false → notifyListeners()
  4. Firebase's auth stream fires with the new UID
  5. AuthViewModel.userId updates → notifyListeners()
  6. AuthGate rebuilds → HomeShell           ← no manual navigation
  7. HomeShell.initState → MyEventsViewModel.load(uid)
```

### 8.3 Log in

Identical to sign-up except it calls `vm.signIn()` and `TextInput.finishAutofillContext()`
is called on success so the password manager offers to save the credential.

### 8.4 Forgot password

```
1. "Forgot password?" → _openResetDialog()
2. clearResetMessages()  (so a previous attempt doesn't linger)
3. _ForgotPasswordDialog opens, prefilled with the typed email
4. "Send reset link" → validate → vm.sendPasswordReset(email)
5. AuthViewModel.sendPasswordReset():
     isLoading = true
     auth.sendPasswordReset(...)          // Firebase sends the real email
     success → resetInfo = "Password reset email sent. Check your inbox."
     failure → resetError = friendlyResetError(e)
     finally → isLoading = false
6. Dialog swaps: input field hidden, success text shown, button becomes "Done"
7. On close → clearResetMessages() again
```

### 8.5 Search and filter

```
Type in the search box
  → vm.setSearchQuery(text)  → notifyListeners()
  → DiscoverView rebuilds (it watches the VM)
  → vm.filtered getter recomputes (it is NOT cached)
  → new list of EventCards

Pick a category from the dropdown
  → vm.setCategory(c)  → same chain
  → the dropdown labels already show "(n)" counts

Pull to refresh
  → RefreshIndicator → vm.load() → re-subscribe to the events stream

Empty result + "Clear filters"
  → _search.clear() + vm.clearFilters() → back to All + empty query
```

### 8.6 Open an event

```
Tap an EventCard
  → widget.onOpenDetail(event.id)
  → HomeShell._openDetail(id)
  → Navigator.pushNamed('/detail', arguments: id)
  → main.dart onGenerateRoute sees '/detail' + a String argument
  → DetailView(eventId: id)
  → scans Discover + upcoming + history for a matching ID
  → not found → "Event not found." / found → full page
```

### 8.7 Register — the important one

```
Tap "Register for this event"                       (detail_view.dart)
  1. userId = context.read<AuthViewModel>().userId; if null → do nothing
  2. mine.register(userId, event)                    (my_events_view_model.dart)
  3.   event.isPast?  → notice "Registration is closed…" → return false
  4.   registrations.register(userId, event.id)      (registration_repository.dart)
         doc ID = "<uid>_<eventId>"
         .get() → exists? → throw DuplicateRegistration
         .set() → write the document to Firestore
  5.   catch DuplicateRegistration → "You are already registered for this event."
  6.   notifications.requestPermission()
  7.   GRANTED:
         showNow(id: confirmationIdFor(id), "Registration confirmed",
                 "Quiz Bee starts in 3 days — Nov 15, 2026 at 1:00 PM at Library Hall")
         scheduleReminder(id: reminderIdFor(id),
                 when: event.dateTime - 1 hour,
                 androidScheduleMode: inexactAllowWhileIdle)
         notice = "Registered. Reminder set for 1 hour before."
       DENIED:
         notice = "Registered. Enable notifications to get reminders."
  8.   await load(studentId)   ← refresh from the database, not from memory
  9.   return true
10. mine.takeNotice() → show SnackBar with that sentence
11. Every screen rebuilds automatically: Discover card gets "Registered",
    My Events gains a card, the detail button flips to "Cancel registration"
```

### 8.8 Cancel (two ways, identical logic)

```
Detail page:  "Cancel registration" button
Swipe:        Dismissible on a My Events card  (History cannot be swiped)

Both → confirmCancelRegistration(context, eventName: …)
       "Keep Registration" / tap outside → false → nothing happens
       "Cancel Registration" (red) → true

  1. vm.cancel(userId, event)
       registrations.cancel(...)              ← deletes the Firestore document
       notifications.cancelReminder(reminderIdFor(event.id))   ← kills the reminder
  2. await load(studentId)
  3. notice = "Registration cancelled."
  4. SnackBar; card disappears; button flips back to "Register"
```

### 8.9 Toggle dark mode

```
Tap the theme icon in the AppBar
  → context.read<ThemeController>().toggle()
  → setMode(dark ⇄ light)
  → _mode = new value
  → notifyListeners()               ← MaterialApp and every screen rebuild
  → SharedPreferences.setString('eventhub_theme_mode', 'dark')
Next launch:
  → main() → theme.load() → reads the saved string → restores the choice
```

### 8.10 Maps and Calendar

```
"Open location in Maps"  → MapsLauncher.openEvent(event)
     hasCoordinates? → Google Maps URL with lat,lng
     else            → Google Maps URL with the (URL-encoded) address
     launchUrl(externalApplication)
     false → SnackBar "Could not open maps."

"Add to Calendar"        → CalendarLauncher.addEvent(event)
     googleCalendarUrl(event) → https://calendar.google.com/calendar/render?…
     launchUrl(externalApplication)  → browser/app opens the pre-filled form
     false → SnackBar "Could not open calendar on this device."
```

### 8.11 Log out

```
AppBar logout icon
  → AuthViewModel.signOut() → auth.signOut()
  → stream fires with null → userId = null → notifyListeners()
  → AuthGate rebuilds → AuthView (login screen)
```

---

## 9. What is stored in the database

Two **collections**. A collection is like a folder; a document is like a file in it.

### 9.1 `events/` — written **only** by staff in the Firebase console

```
events/
  evt-seminar-web/                       ← the document ID (we call it eventId)
    name:          "Web Development Seminar"
    category:      "Seminar"
    dateTime:      Timestamp(2026-11-15 09:00)      ← Firestore Timestamp
    locationName:  "School Auditorium"
    address:       "Main Campus, Building A"
    description:   "An introduction to modern web development…"
    imageUrl:      "assets/images/seminar-web.jpg"
    latitude:      14.5995        (optional)
    longitude:     120.9842       (optional)
```

Valid `category` values (fixed in `Event.categories`):
`Academic`, `Sports`, `Seminar`, `Organization`, `Entertainment`.
Plus the pseudo-value `All` used only by the filter.

`imageUrl` may be a **local** path (`assets/…`) or a **web** URL. The app decides with
`isAssetImage()`.

### 9.2 `registrations/` — written **only** by the app, for the signed-in student

```
registrations/
  abc123xyz789_evt-seminar-web/           ← document ID = "<studentUid>_<eventId>"
    studentId:    "abc123xyz789"          ← Firebase Auth UID
    eventId:      "evt-seminar-web"
    registeredAt: Timestamp(2026-10-12 14:33)
    status:       "registered"
```

`studentId` is the **Firebase UID**, not the email. That's why registrations survive
logging out and back in, and follow the student across devices.

### 9.3 What is NOT in the database

- **No profile documents.** No name, no student number, no avatar. Email + UID only.
- **No attendance records.** History is simply "registered + the date has passed".
- **No images in the database.** The photos are bundled in `assets/images/`; the
  database only stores the path.
- **No settings.** The theme choice lives on the phone (`SharedPreferences`), not in
  the cloud.

---

## 10. Security rules, explained

`firestore.rules` is the one file that decides what the database allows.
**Even a hacked app cannot bypass it.** Read this file and you can answer any
question about security.

```dart
match /events/{eventId} {
  allow read:  if request.auth != null;   // any signed-in student may read
  allow write: if false;                  // nobody may write through the app
}
```
**Events are read-only from the app.** Staff add them in the Firebase console, which
uses a different (admin) path that ignores these rules. This is *why* there is no
"create event" screen — the app is not allowed to.

```dart
match /registrations/{registrationId} {
  allow get:  if request.auth != null
      && (resource == null || resource.data.studentId == request.auth.uid);
  allow list: if request.auth != null
      && resource.data.studentId == request.auth.uid;
  allow create: if request.auth != null
      && request.resource.data.studentId == request.auth.uid       // 1. mine
      && registrationId == request.resource.data.studentId + '_'
                        + request.resource.data.eventId            // 2. correct ID
      && request.resource.data.status == 'registered';             // 3. valid status
  allow delete: if request.auth != null
      && resource.data.studentId == request.auth.uid;
  allow update: if false;
}
```

Line by line:

| Rule | Condition | Why |
|---|---|---|
| `get` | `resource == null` **OR** it's mine | The app does a `get()` to check for duplicates *before* creating. The document doesn't exist yet, so `resource` is null. Without this escape hatch the check would be denied. |
| `list` | `resource.data.studentId == uid` | Firestore evaluates this **per document** in the result. You can only ever receive your own registrations. |
| `create` 1 | `studentId == uid` | You can only register **yourself**. |
| `create` 2 | doc ID equals `studentId_eventId` | The duplicate guard, enforced by the database. |
| `create` 3 | `status == 'registered'` | Blocks writing nonsense statuses. |
| `delete` | `resource.data.studentId == uid` | You can only cancel your own. |
| `update` | `false` | Registrations are immutable. Cancel = delete + register again. |

**Also note `request.auth != null` everywhere** — a signed-out user can do nothing.

> **Deploying:** `firebase deploy --only firestore:rules`. Changing the local file
> does nothing until you run that command.

---

## 11. Notifications and reminders

### The full picture

| Moment | What happens |
|---|---|
| Student presses **Register** | `requestPermission()` — the OS/browser prompt appears **here**, not at app start |
| Permission **granted** | ① `showNow(confirmationId)` — an instant notification: *"Registration confirmed — Quiz Bee starts in 3 days — Nov 15, 2026 1:00 PM at Library Hall"* |
| | ② `scheduleReminder(reminderId, when: start − 1 hour)` — fires 1 hour before |
| Permission **denied** | Registration still succeeds. SnackBar: *"Registered. Enable notifications to get reminders."* |
| Student presses **Cancel** | `cancelReminder(reminderId)` — the pending reminder is destroyed |

### Why 1 hour before?

That's the spec requirement. `reminderTimeFor()` is a one-line pure function, so
changing it to 24 hours or 30 minutes is a one-line change and the test still covers it.

### Android vs web — why the code branches

| | Mobile (Android/iOS) | Web |
|---|---|---|
| Permission | `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()` / iOS `requestPermissions(alert, badge, sound)` | `WebFlutterLocalNotificationsPlugin.requestNotificationsPermission()` — a real browser prompt |
| Scheduling | `zonedSchedule(..., androidScheduleMode: inexactAllowWhileIdle)` — the **OS** does it, works even if the app is closed | A Dart `Timer` in `_webTimers` — **only works while the tab is open** |

Browsers have no OS-level scheduler, so the honest fallback is a `Timer`. The comment
in the code says exactly this. **Do not claim web reminders work in the background.**

`kIsWeb` is Flutter's compile-time "am I running in a browser?" check — no imports,
no branching in the widgets.

### Why `inexactAllowWhileIdle` instead of `exactAllowWhileIdle`?

Exact alarms require the special `SCHEDULE_EXACT_ALARM` permission and are hostile to
battery. `inexactAllowWhileIdle` may fire a few minutes late but needs nothing extra.
For "remind me an hour before", a couple of minutes' drift is irrelevant.

---

## 12. Tests — what they prove

27 tests across 8 files in `test/`. Run them with `flutter test`.

They run against the **mock** services — no internet, no Firebase project, ~1 second.

| File | Tests | What it proves |
|---|---|---|
| `eventhub_test.dart` | 5 | Discover filter (All / category / unknown), register once succeeds, register twice is blocked, cancel removes it, past events land in History not Upcoming, registrations are per-student |
| `eventhub_features_test.dart` | 10 | Per-category counts match the data; search is case-insensitive; search covers venue + description; search + category combine; `clearFilters` restores everything; reset email success/invalid/generic; the Google Calendar URL is correctly encoded and uses the 2-hour fallback |
| `auth_regression_test.dart` | 3 | The password field stays editable after a failed signup (a real bug that was fixed), short passwords are still rejected, the reset dialog reports success |
| `demo_history_test.dart` | 3 | Past → History, future → Upcoming; live registration doesn't wipe existing history; registering a past event is rejected **with no side effects** |
| `confirm_dialog_test.dart` | 2 | "Keep" returns false, "Cancel Registration" returns true |
| `theme_controller_test.dart` | 2 | Defaults to light, toggles both ways, **persists across instances** (via `SharedPreferences.setMockInitialValues`) |
| `detail_state_test.dart` | 1 | Detail screen renders the right state per event |
| `widget_test.dart` | 1 | Discover actually renders events and filters by category |

**The tests that would impress an examiner** are the three `demo_history_test.dart`
ones and the "no side effects" assertion — they test *behaviour*, not just "does it
compile".

`NoopNotificationService` exists mostly so tests can construct a
`MyEventsViewModel` without touching real notification permissions.

---

## 13. The demo seed script

`scripts/seed_demo.py` — 105 lines of Python. It talks to Firestore **directly**
(using `firebase-admin`), bypassing the app, because the app is *not allowed* to write
events.

**What it creates:**
1. `events/evt-past-robotics` — a past academic event (only if missing)
2. `registrations/<YOUR_UID>_evt-past-robotics` — so that event appears in **History**

**Why:** during a demo you can't wait for an event to become "past". This fakes one.

**Usage:**
```bash
cd scripts
python3 -m venv venv && source venv/bin/activate
pip install firebase-admin
python3 seed_demo.py <USER_UID>          # UID from Firebase Console → Authentication → Users
```

**It is idempotent** — safe to run any number of times; it checks `.exists()` before
writing. That matters, because the demo may be run several times.

`service_account.json` must **never** be committed to Git. Check `.gitignore`.

---

## 14. Design decisions and the "why" behind them

Each of these came up in a review or a viva question. Memorise the answer.

| # | Decision | Why |
|---|---|---|
| 1 | **The 4-layer structure** (`views → view_models → services → models`) | Swappable backend, testable logic, and when something breaks you know exactly which layer to look at. |
| 2 | **Real + Fake implementations everywhere** | The app always runs (even without Firebase), tests are instant, and logic is provable. |
| 3 | **Registrations keyed by `<uid>_<eventId>`** | Makes double-booking impossible at the *database* level, not just in the UI. |
| 4 | **`Event.isPast` computed from `dateTime`** | One source of truth for "has it happened?" — used by History, the Ended badge, and closing registration. They can never disagree. |
| 5 | **No end time on `Event`** | Keeps the data model simple. Calendar export uses a documented 2-hour constant. |
| 6 | **Events are read-only from the app** | The spec put event creation out of scope. Rather than leave a half-built admin screen, we made it structurally impossible — the rules say `write: if false`. |
| 7 | **`status` field on Registration** | Ready for future states (`attended`, `cancelled`) without a schema change. |
| 8 | **Error codes never reach the user** | Raw codes like `invalid-credential` mean nothing to a student, and leaking them reveals information. |
| 9 | **Reset flow never says "no such account"** | Prevents email enumeration — a real, textbook security property. |
| 10 | **Permission requested at register time** | Ask when the user wants something, not at launch. Higher grant rate, better UX. |
| 11 | **Registration never rolls back for a failed reminder** | The student's spot matters more than the notification. |
| 12 | **`notice` + `takeNotice()` instead of a direct SnackBar** | A ViewModel has no `BuildContext` and must not touch UI. It stores the message; the screen shows it. |
| 13 | **One `RegistrationsList` with a `showPast` flag** | My Events and History are the same list, split by `isPast`. ~110 lines instead of ~220. |
| 14 | **Hand-written date formatting** | Avoids the `intl` dependency. `formatEventDate` / `formatEventTime` are 15 lines total. |
| 15 | **`_joined()` skips registrations whose event vanished** | Staff can delete an event from the console; a dangling registration must not crash the app. |
| 16 | **`allow update: if false`** | Registrations are immutable. Cancel = delete, then register again. Simpler to reason about. |
| 17 | **Web reminders use a `Timer`** | Honest about the platform limit rather than pretending. |
| 18 | **`CategoryChips` kept but unused** | Discover moved to a dropdown (better for 6 categories + long labels). The widget is small, documented, and reusable. |

---

## 15. Known quirks (be honest, not perfect)

If a member discovers one of these, it's already written down here — that's a
feature, not a confession.

1. **Mock data is lost when you close the app.** It's in memory. Firebase mode
   persists properly.
2. **Web reminders only fire while the tab is open.** No browser API can do
   otherwise.
3. **`CategoryChips` is unused.** Left in place on purpose (see #18 above).
4. **`NoopNotificationService` is only used by tests**, never by `main.dart`.
   `main.dart` always constructs `LocalNotificationService`, which handles a denied
   permission internally.
5. **`EventHubTheme.display()` is unused** — a leftover helper from when
   `google_fonts` was considered.
6. **`MockRegistrationRepository.watchForStudent()` yields once and stops.** It's
   implemented to satisfy the contract, but `MyEventsViewModel` uses `fetchForStudent`
   and re-fetches after every change instead. In mock mode the refresh is manual
   (pull-to-refresh); in Firebase mode `watchEvents` pushes updates live.
7. **`FirebaseAuthService.userIdChanges` is `authStateChanges()`, not
   `idTokenChanges()`.** Right choice for UI purposes (fires less often) but worth
   knowing.
8. **The `permission-denied` catch in `register()`** exists for older deployed rules.
   Current rules don't need it, but it's harmless and keeps old deployments working.
9. **`lib/python3.12/…` exists inside `lib/`.** It's a stray copy of Python
   site-packages, **not** Flutter code. Ignore it. (Worth cleaning up before
   submission — but don't delete it without checking with the team.)

---

## 16. "I want to change X — edit which file?"

| Task | File(s) |
|---|---|
| Add a new event category | `lib/domain/models/event.dart` → `Event.categories` |
| Change colours / spacing / rounded corners | `lib/ui/core/theme.dart` |
| Change how many hours before the reminder | `lib/data/services/notification_service.dart` → `reminderTimeFor()` |
| Change the calendar event length (currently 2h) | `lib/data/services/calendar_launcher.dart` → `defaultEventDuration` |
| Change the words in a SnackBar / empty state | The ViewModel (`notice = …`) or `EmptyState(message: …)` |
| Add a new field to an event | `lib/domain/models/event.dart` (field + `fromMap` + `toMap`), then add it to the console documents and to `scripts/seed_demo.py` |
| Add a whole new tab | `lib/main.dart` (`pages` list + `NavigationDestination`) + a new `features/yourfeature/` folder |
| Change the login rules | `firestore.rules` **and** `lib/data/services/auth_service.dart` (`friendlyAuthError`) |
| Make registration cancellable-without-confirm | `lib/ui/features/my_events/views/registrations_list.dart` → `confirmDismiss` |
| Change the app name in the AppBar | `lib/main.dart` (HomeShell AppBar) and `pubspec.yaml` (`name:`) |
| Add a new image | Drop the file in `assets/images/`, set `imageUrl` to `"assets/images/yourfile.jpg"` |
| Change the seed script's demo event | `scripts/seed_demo.py` → `HISTORICAL_EVENT` |

---

## 17. Q&A cheat sheet for demos and viva

Print this page. Short answers, no waffling.

**Q1. What is this app?**
A Flutter app where students find school events and register for them, with a
1-hour-before reminder, running on Firebase.

**Q2. Why Flutter?**
One codebase → Android, iOS and web. It's already published as a website.

**Q3. What's the architecture?**
4 layers: UI (views) → ViewModels → Repositories/Services → Models. Dependencies
only point downward.

**Q4. Explain the ViewModel.**
It sits between the screen and the database. It holds the data the screen shows and
does the logic. When data changes it calls `notifyListeners()`, and Provider tells
the screens to redraw. It has no `context`, so it can't show a SnackBar directly —
it stores the text in `notice` and the screen calls `takeNotice()`.

**Q5. Why Provider instead of setState everywhere?**
`setState` only rebuilds one widget. Provider shares state app-wide, so registering
on the detail screen instantly updates the Discover badge and the My Events list.

**Q6. How does registering work?**
Tap Register → check the event isn't past → build the doc ID `<uid>_<eventId>` →
check it doesn't exist → write to Firestore → ask for notification permission →
send a confirmation and schedule the 1-hour reminder → reload from the database →
SnackBar. See [§8.7](#87-register--the-important-one).

**Q7. How do you prevent double registration?**
Twice. In the app: a `get()` before `set()` throws `DuplicateRegistration`. In the
database: the `create` rule requires the doc ID to equal `studentId_eventId`, so
a second document can't exist. Defence in depth.

**Q8. How does My Events differ from History?**
One widget, `RegistrationsList(showPast: true/false)`. Both join registrations with
events and split on `event.isPast`. Upcoming sorts soonest-first; History
most-recent-first.

**Q9. What is a Stream and where do you use it?**
A live feed that keeps sending values. `EventRepository.watchEvents()` subscribes to
Firestore, so when staff add an event in the console, students' phones update
automatically without pulling to refresh.

**Q10. Why are there two implementations of every service?**
So the app runs without Firebase (demo, first run) and so tests run instantly with
no network. `main.dart` picks Real if Firebase initialised, Fake otherwise.

**Q11. What is Firestore?**
Google's cloud NoSQL database. Collections → documents → fields. Data is fetched
as documents and mapped to our model classes by `fromMap`.

**Q12. How is the app secure?**
Firestore rules, enforced by the database — the app can't bypass them.
Students can only read and write their own registrations; events are read-only
from the client (`write: if false`); updates are forbidden entirely; every rule
requires `request.auth != null`.

**Q13. Why can't a student read someone else's registrations?**
`allow list` checks `resource.data.studentId == request.auth.uid`, evaluated per
document. Requests for anyone else's documents are filtered out.

**Q14. How do reminders work?**
On register we ask permission, show an instant confirmation, and schedule a
notification for one hour before the start using `zonedSchedule` with
`inexactAllowWhileIdle`. Cancelling a registration cancels the reminder too.

**Q15. Why doesn't the reset flow say "email not found"?**
Email enumeration. If we revealed it, an attacker could discover which emails have
accounts. We always say *"If an account exists for this email, a reset link has been
sent."*

**Q16. How does dark mode work?**
`ThemeController` (a ChangeNotifier) holds a `ThemeMode`, saves it to
`SharedPreferences` on every change, restores it at launch. `MaterialApp` watches it
and swaps `theme`/`darkTheme`. Screens read `Theme.of(context).colorScheme`, never
hard-coded colours.

**Q17. How do Maps and Calendar work?**
Both just build a URL and hand it to `url_launcher`.
Maps: a pin if the event has coordinates, otherwise a text search on the address.
Calendar: a Google Calendar `action=TEMPLATE` URL with a 2-hour block. Chosen over
`.ics` writing because it needs no extra dependency and works on all three platforms.

**Q18. What's the hardest part of the project?**
Keeping the "Registered" state consistent across three screens. Because
`MyEventsViewModel` is a single shared provider, one `load()` after every mutation
updates the detail page, the Discover badge and the My Events list at once — no
manual screen-to-screen communication.

**Q19. How do you know it works?**
27 automated tests covering filtering, search, duplicate registration, past-event
rejection, per-student isolation, error messages, the calendar URL, and theme
persistence. They use the mock services, so the whole suite runs in about a second.

**Q20. What would you add next?**
(i) An `.ics` export for Apple Calendar, (ii) FCM push notifications so web
reminders work in the background, (iii) an admin screen for staff to create events
(would require changing the `write: if false` rule), (iv) QR-code check-in at the
event.

---

## Appendix: file size reference

| File | Lines | Role |
|---|---|---|
| `lib/ui/core/widgets.dart` | 409 | Shared UI: EventCard, EmptyState, LoadingState, cancel dialog |
| `lib/ui/features/auth/views/auth_view.dart` | 316 | Login + signup + forgot-password dialog |
| `lib/ui/features/detail/views/detail_view.dart` | 254 | Event detail, register/cancel, maps, calendar |
| `lib/data/services/notification_service.dart` | 220 | Reminders |
| `lib/main.dart` | 206 | Entry point, providers, AuthGate, HomeShell |
| `lib/ui/core/theme.dart` | 201 | Colours and themes |
| `lib/data/services/auth_service.dart` | 155 | Auth contract + Firebase + Mock + error messages |
| `lib/ui/features/discover/views/discover_view.dart` | 146 | Discover screen |
| `lib/ui/features/my_events/view_models/my_events_view_model.dart` | 137 | Join + register + cancel |
| `lib/ui/features/my_events/views/registrations_list.dart` | 111 | My Events + History |
| `lib/ui/features/auth/view_models/auth_view_model.dart` | 111 | Auth state |
| `lib/ui/features/discover/view_models/discover_view_model.dart` | 106 | Filter + search |
| `lib/domain/models/event.dart` | 105 | The Event model + date helpers |
| `lib/firebase_options.dart` | 88 | Generated Firebase keys |
| `lib/data/services/calendar_launcher.dart` | 59 | Google Calendar URL |
| `lib/ui/core/theme_controller.dart` | 49 | Light/dark memory |
| `lib/domain/models/registration.dart` | 44 | The Registration model + `docId` |
| `lib/data/services/event_repository.dart` | 122 | Read events (Firestore + Mock) |
| `lib/data/services/registration_repository.dart` | 120 | Register / cancel / check |
| `lib/data/services/maps_launcher.dart` | 28 | Google Maps URL |

**Total: 20 files, ~2,990 lines** (excluding `test/` and `scripts/`).

---

*Questions not answered here? Add them to §17 so the next person doesn't have to
figure it out either.*