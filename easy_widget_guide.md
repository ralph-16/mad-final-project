# EventHub — Easy Widget Guide

> **What this is:** every single **widget** (visual component) in the project, one by
> one — what it looks like on screen, what goes into it, where it is written, and
> where it is used.
>
> **Companion to** `easy_code_summary.md` (which explains the data/logic side).
> **Search tip:** every entry has a location like `lib/main.dart:45`. In VS Code,
> `Ctrl+G` (Cmd+G on Mac) then paste the location to jump straight there.

---

## Contents

1. [Widget basics in 60 seconds](#1-widget-basics-in-60-seconds)
2. [Complete widget index (find anything fast)](#2-complete-widget-index-find-anything-fast)
3. [`main.dart` — 3 widgets](#3-maindart--3-widgets)
4. [`lib/ui/core/widgets.dart` — 8 widgets](#4-libuicorewidgetsdart--8-widgets)
5. [`auth_view.dart` — 2 widgets](#5-auth_viewdart--2-widgets)
6. [`discover_view.dart` — 1 widget](#6-discover_viewdart--1-widget)
7. [`registrations_list.dart` — 1 widget](#7-registrations_listdart--1-widget)
8. [`detail_view.dart` — 3 widgets](#8-detail_viewdart--3-widgets)
9. [`theme.dart` — the widget that isn't one](#9-themedart--the-widget-that-isnt-one)
10. [Full widget trees for every screen](#10-full-widget-trees-for-every-screen)
11. [Widgets written inline (not extracted)](#11-widgets-written-inline-not-extracted)
12. [Which widget do I edit if…](#12-which-widget-do-i-edit-if)
13. [Widget Q&A](#13-widget-qa)

---

## 1. Widget basics in 60 seconds

**A widget is just a description of a piece of screen.** In Flutter, everything —
including the entire page — is a widget. There are only three kinds in this project:

| Kind | What it means | Count here |
|---|---|---|
| **`StatelessWidget`** | Never changes on its own. You give it data, it draws. Example: `EventCard`, `DetailView`. | 12 |
| **`StatefulWidget`** | Remembers things (which tab, is the password hidden). Pairs with a `State` class. | 4 (+4 State classes) |
| **Private widgets** (name starts with `_`) | Only usable inside their own file. Deliberately hidden from the rest of the app. | 7 |

**Every widget has the same skeleton:**

```dart
class MyWidget extends StatelessWidget {          // 1. the class
  const MyWidget({super.key, required this.title});// 2. the constructor + inputs
  final String title;                             // 3. store the inputs

  @override                                       // 4. build() = what it looks like
  Widget build(BuildContext context) {
    return Text(title);                           // 5. the screen output
  }
}
```

**`super.key`** — Flutter's own tracking label, used when you reorder lists. Every
widget we write passes it. Never touch it.

**`const`** — means "this widget never changes, build it once and reuse it."
You see it on almost every widget in this project. It's a performance optimisation.

---

## 2. Complete widget index (find anything fast)

| # | Widget | Type | Defined at | Used at | Public? |
|---|---|---|---|---|---|
| 1 | `EventHubApp` | Stateless | `lib/main.dart:45` | `lib/main.dart:42` | ✅ yes |
| 2 | `AuthGate` | Stateless | `lib/main.dart:104` | `lib/main.dart:85` | ✅ yes |
| 3 | `HomeShell` | Stateful | `lib/main.dart:115` | `lib/main.dart:111` | ✅ yes |
| 3b | `_HomeShellState` | State | `lib/main.dart:122` | — | — |
| 4 | `EventCard` | Stateless | `lib/ui/core/widgets.dart:8` | `discover_view.dart:134`, `registrations_list.dart:81` | ✅ yes |
| 5 | `_OverlayBadge` | Stateless | `lib/ui/core/widgets.dart:158` | `widgets.dart:58` | ❌ private |
| 6 | `_ImageHeader` | Stateless | `lib/ui/core/widgets.dart:175` | `widgets.dart:33` | ❌ private |
| 7 | `_CategoryTag` | Stateless | `lib/ui/core/widgets.dart:222` | `widgets.dart:51` | ❌ private |
| 8 | `CategoryChips` | Stateless | `lib/ui/core/widgets.dart:248` | ⚠️ **nowhere** | ✅ yes |
| 9 | `LoadingState` | Stateless | `lib/ui/core/widgets.dart:301` | `discover_view.dart:100`, `registrations_list.dart:46` | ✅ yes |
| 10 | `EmptyState` | Stateless | `lib/ui/core/widgets.dart:320` | 5 places (see §4.7) | ✅ yes |
| — | `confirmCancelRegistration()` | *function, not a widget* | `lib/ui/core/widgets.dart:380` | `registrations_list.dart:96`, `detail_view.dart:149` | ✅ yes |
| 11 | `AuthView` | Stateful | `lib/ui/features/auth/views/auth_view.dart:11` | `lib/main.dart:110` | ✅ yes |
| 11b | `_AuthViewState` | State | `auth_view.dart:18` | — | — |
| 12 | `_ForgotPasswordDialog` | Stateful | `auth_view.dart:218` | `auth_view.dart:208` | ❌ private |
| 12b | `_ForgotPasswordDialogState` | State | `auth_view.dart:226` | — | — |
| 13 | `DiscoverView` | Stateful | `lib/ui/features/discover/views/discover_view.dart:9` | `lib/main.dart:148` | ✅ yes |
| 13b | `_DiscoverViewState` | State | `discover_view.dart:17` | — | — |
| 14 | `RegistrationsList` | Stateful | `lib/ui/features/my_events/views/registrations_list.dart:11` | `lib/main.dart:149` **and** `:150` | ✅ yes |
| 14b | `_RegistrationsListState` | State | `registrations_list.dart:25` | — | — |
| 15 | `DetailView` | Stateless | `lib/ui/features/detail/views/detail_view.dart:15` | `lib/main.dart:91` | ✅ yes |
| 16 | `_InfoRow` | Stateless | `detail_view.dart:181` | `detail_view.dart:59`, `:63` | ❌ private |
| 17 | `_HeroImage` | Stateless | `detail_view.dart:202` | `detail_view.dart:51` | ❌ private |

**Totals: 20 widget classes** (12 public, 7 private, plus 4 `State` classes) and
**1 shared dialog function**, across **6 files**.

**Tested in the widget test suite:** `AuthView` (`auth_regression_test.dart:62`),
`DiscoverView` (`widget_test.dart:30`), `DetailView` (`detail_state_test.dart:72`).

---

## 3. `lib/main.dart` — 3 widgets

### 3.1 `EventHubApp` — the root widget

**📍 Location:** `lib/main.dart:45`
**📍 Used at:** `lib/main.dart:42` — `runApp(EventHubApp(...))`
**Type:** StatelessWidget

**What it does:** This is the very first widget Flutter draws. It doesn't look like
anything on screen — its job is to **build the app's skeleton**: choose the real or
fake services, register them in Provider, and put `MaterialApp` underneath.

**Inputs (parameters):**

| Parameter | Type | Required | Meaning |
|---|---|---|---|
| `firebaseReady` | `bool` | ✅ yes | `true` = use real Firebase, `false` = use mocks |
| `theme` | `ThemeController` | ✅ yes | The shared light/dark controller |

**What it renders (nothing visible — a container):**

```
MultiProvider                                  ← main.dart:64  (4 providers)
│  ├── ThemeController                          (created in main(), passed in)
│  ├── AuthViewModel(auth)
│  ├── DiscoverViewModel(events)
│  └── MyEventsViewModel(registrations, events, notifications)
└── Builder                                     ← main.dart:79
   └── MaterialApp                              ← main.dart:80
       ├── theme:      EventHubTheme.light()
       ├── darkTheme:  EventHubTheme.dark()
       ├── themeMode:  context.watch<ThemeController>().mode
       ├── home:       const AuthGate()         ← main.dart:85
       └── onGenerateRoute: '/detail' → DetailView(eventId)   ← main.dart:86-95
```

**Two things worth explaining if asked:**

1. **Why `Builder` at line 79?** `themeMode` needs `context.watch<ThemeController>()`,
   but `MaterialApp` sits *below* the providers. A `Builder` creates a **new
   `context` underneath the providers**, so the `watch` works. Without it you'd get
   the classic *"ProviderNotFoundException"*.

2. **Why are the services created inside `build()`?**
   `MultiProvider` is a StatelessWidget, so its `create:` callbacks run on first
   build. `build()` runs after `firebaseReady` is known, so we can pick Real vs Fake.
   Flutter only calls it again on a real change, so this isn't wasteful.

---

### 3.2 `AuthGate` — the login wall

**📍 Location:** `lib/main.dart:104`
**📍 Used at:** `lib/main.dart:85` (`home: const AuthGate()`)
**Type:** StatelessWidget — just **10 lines of logic**

**What it does:** The one widget whose whole job is **one question**: "is anyone
logged in?" It sits as `MaterialApp.home`, so *the entire app is either the login
screen or the home screen* — there is no navigation between them.

**What it renders:**

```
        signedIn == false                signedIn == true
   ┌───────────────────────┐       ┌───────────────────────┐
   │                       │       │                       │
   │      AuthView         │       │      HomeShell        │
   │   (login/signup)      │       │    (3-tab app)        │
   │                       │       │                       │
   └───────────────────────┘       └───────────────────────┘
```

**The whole body:**

```dart
@override
Widget build(BuildContext context) {
  final signedIn = context.watch<AuthViewModel>().signedIn;
  if (!signedIn) return const AuthView();
  return const HomeShell();
}
```

**How the switch happens:** `context.watch` (not `read`!) means this widget
**rebuilds automatically** whenever `AuthViewModel` calls `notifyListeners()`.
Firebase's auth stream fires with the UID → `userId` changes → `signedIn` flips →
`AuthGate` rebuilds → login screen is replaced by the home screen.

**Key point to say out loud:** *We never call Navigator to go to the home screen.
The login and home screens are the same position in the tree, and the data decides
which one is there.*

---

### 3.3 `HomeShell` — the 3-tab container

**📍 Location:** `lib/main.dart:115` (widget) + `lib/main.dart:122` (`_HomeShellState`)
**📍 Used at:** `lib/main.dart:111`
**Type:** StatefulWidget → `_HomeShellState`

**Why Stateful?** It must remember **which tab is currently selected.** That's the
one thing that changes inside it without coming from outside.

**State it remembers:**

| Field | Type | Line | Meaning |
|---|---|---|---|
| `_tab` | `int` | `main.dart:123` | `0` = Discover, `1` = My Events, `2` = History |

**What it renders:**

```
Scaffold                                          ← main.dart:153
├── appBar: AppBar                                ← main.dart:154
│    ├── Row [ SvgPicture.asset('assets/images/logo.svg', 28×28),  ← :158
│    │          SizedBox(8),
│    │          Text('EventHub') ]                ← :164
│    └── actions:
│         ├── IconButton(context.watch<ThemeController>().toggleIcon)  ← :168
│         │      onPressed → context.read<ThemeController>().toggle()
│         └── IconButton(Icons.logout_outlined)                        ← :175
│                onPressed → context.read<AuthViewModel>().signOut()
│
├── body: SafeArea(child: pages[_tab])            ← main.dart:182
│         pages = [                                ← main.dart:147-151
│           DiscoverView(onOpenDetail: _openDetail),        index 0
│           RegistrationsList(showPast: false, …),           index 1
│           RegistrationsList(showPast: true,  …),           index 2
│         ]
│
└── bottomNavigationBar: NavigationBar            ← main.dart:183
     destinations: Discover / My Events / History
```

**The `pages` list trick:** all three screens are listed in one array, but
`pages[_tab]` means **only the selected tab is actually built.** Flutter doesn't draw
the other two. This is why switching tabs is instant.

**`initState()` (main.dart:126-139):**

```dart
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {   // ← after first frame
    if (!mounted) return;
    final userId = context.read<AuthViewModel>().userId;
    if (userId != null) {
      context.read<MyEventsViewModel>().load(userId);
    }
  });
}
```

- **`addPostFrameCallback`** = "run this after the screen has finished drawing."
  We can't call `context.read` during `initState` because the widget isn't attached
  to the tree yet — this is the safe standard way.
- **`if (!mounted) return;`** = "stop if the user already logged out."
- **Why load here at all?** Because **Discover is the first tab**, and its cards need
  to know which events you're registered for (to show the "Registered" badge).
  Without this, badges would be missing until you visited the My Events tab.
- The comment at lines 128-131 explains exactly this — read it if asked.

**`_openDetail()` (main.dart:141-143):** the bridge from a tapped card to the detail screen.

```dart
void _openDetail(String eventId) {
  Navigator.of(context).pushNamed('/detail', arguments: eventId);
}
```

**How the eventId travels:** it's passed as `arguments`, caught by `onGenerateRoute`
in `EventHubApp` (`main.dart:86-95`), which checks `settings.arguments is String`
and builds `DetailView(eventId: …)`. **If you pass the wrong type, no route matches
and the app goes blank** — that `is String` check is a safety guard.

**The theme toggle uses `watch` for display and `read` for action** — this pattern
appears all over the app:

```dart
icon: Icon(context.watch<ThemeController>().toggleIcon),   // rebuild when it changes
onPressed: () => context.read<ThemeController>().toggle(), // just call it
```

---

## 4. `lib/ui/core/widgets.dart` — 8 widgets

**This is the shared component library.** Anything in here is used by more than one
screen. This is the file to open when someone says *"the cards look wrong"* or
*"that empty screen is ugly."*

### 4.1 `EventCard` — the most important widget in the app

**📍 Location:** `lib/ui/core/widgets.dart:8`
**📍 Used at:** `discover_view.dart:134` and `registrations_list.dart:81` (2 places)
**Type:** StatelessWidget

**Inputs:**

| Parameter | Type | Required | What it does with it |
|---|---|---|---|
| `event` | `Event` | ✅ | The data to display |
| `registered` | `bool` | ✅ | Shows the green "Registered" badge if `true` |
| `onTap` | `VoidCallback?` | ❌ optional | Called when tapped; `null` = not tappable |

**What it looks like:**

```
┌────────────────────────────────────────────┐
│ ┌──────────┐              ┌─────────────┐ │
│ │ Seminar  │              │ ✓Registered │ │  ← pills on top of the image
│ └──────────┘              └─────────────┘ │
│                                            │
│         [ the event photo, full bleed ]    │
│                                            │
│▒▒▒▒▒▒▒ gradient from clear to black ▒▒▒▒▒▒│
│ Inter-School Quiz Bee                      │  ← name, white, bold, 2 lines max
│ 📅 Nov 15, 2026 · 1:00 PM                  │  ← date row
│ 📍 Library Hall                            │  ← venue row
│ Annual academic quiz competition. Teams…   │  ← description, 1 line, faint
└────────────────────────────────────────────┘
        220px tall, 20px rounded corners
```

If `registered` is `false` **and** the event is past, the top-right pill shows
**"Ended"** in faint italic instead.

**How it's built (the `Stack` trick):**

```dart
Card                                          // rounded 20, 1px border, no shadow
└── InkWell(onTap)                            // ripple effect when tapped
    └── SizedBox(height: 220)                 // fixed card height
        └── Stack(fit: StackFit.expand)       // ← children layered on top of each other
            ├── _ImageHeader(event)           // 1. bottom layer = the photo
            ├── DecoratedBox(gradient)        // 2. dark scrim over the lower half
            ├── _CategoryTag(category)       // 3. top-left pill
            ├── _OverlayBadge(…)              // 4. top-right pill (conditional)
            └── Positioned(bottom: 14, …)     // 5. the text block on top
```

**`Stack` = layering.** Everything after `_ImageHeader` sits *on top of* the image
instead of below it. That's what makes the "text over photo" design possible.

**The gradient is why white text is readable** (widgets.dart:35-46):

```dart
colors: [Colors.transparent, Colors.black87],  // clear → 87% black
stops:  [0.35, 1.0],                           // starts fading at 35% down
```

**The text block (widgets.dart:87-148), in order:**
1. **Name** — 16px, `FontWeight.w700`, white, `maxLines: 2`, ellipsis
2. **Date row** — `Icons.event_outlined` 14px + `'${formatEventDate(...)} · ${formatEventTime(...)}'`
3. **Venue row** — `Icons.place_outlined` 14px + `locationName`, `maxLines: 1`
4. **Description** — only `if (event.description.isNotEmpty)`, 11px, 60% white, 1 line

**Every text has `overflow: TextOverflow.ellipsis`** so a long event name shows
"Robotics Worksh…" instead of breaking the card layout.

---

### 4.2 `_OverlayBadge` — the "Registered" / "Ended" pill

**📍 Location:** `lib/ui/core/widgets.dart:158`
**📍 Used at:** `lib/ui/core/widgets.dart:58` (inside `EventCard`)
**Type:** StatelessWidget · 🔒 **private** (only `EventCard` may use it)

| Parameter | Type | Required |
|---|---|---|
| `child` | `Widget` | ✅ — whatever goes inside the pill |

**What it looks like:**

```
     ┌──────────────────┐
     │  ✓ Registered    │   black 55% opacity, fully rounded (radius 999)
     └──────────────────┘   10px horizontal + 5px vertical padding
```

**Why the `child` parameter?** So this widget doesn't care *what* the badge says.
`EventCard` passes either an icon+text Row (Registered) or a plain Text (Ended).

**Why radius 999?** Flutter treats a very large border radius as "round the ends",
producing a perfect pill at any width.

---

### 4.3 `_ImageHeader` — the photo picker

**📍 Location:** `lib/ui/core/widgets.dart:175`
**📍 Used at:** `lib/ui/core/widgets.dart:33` (first layer of `EventCard`)
**Type:** StatelessWidget · 🔒 private

| Parameter | Type | Required |
|---|---|---|
| `event` | `Event` | ✅ |

**What it does:** Picks the right kind of image widget. **Three branches, in order:**

```
event.imageUrl is ""  ?
   ├── YES → grey box + 🗓 icon (48px, Icons.event_outlined)
   │
   └── NO  → isAssetImage(imageUrl)?  (i.e. starts with "assets/")
             ├── YES → Image.asset(…)          ← bundled local photo
             │           errorBuilder → broken-image icon
             └── NO  → Image.network(…)         ← a web URL
                         loadingBuilder → circular spinner while downloading
                         errorBuilder  → broken-image icon
```

**The safety pattern:** *both* real image widgets have an `errorBuilder`. If a photo
is deleted or the Wi-Fi drops, you get a grey box with a broken-image icon — never a
red error box, never a crash.

---

### 4.4 `_CategoryTag` — the orange pill

**📍 Location:** `lib/ui/core/widgets.dart:222`
**📍 Used at:** `lib/ui/core/widgets.dart:51` (top-left of `EventCard`)
**Type:** StatelessWidget · 🔒 private

| Parameter | Type | Required |
|---|---|---|
| `label` | `String` | ✅ — the category name |

**What it looks like:**

```
     ┌───────────┐
     │  Seminar  │    white background, orange text, radius 999
     └───────────┘    text uses EventHubTheme.primary (the app's brand orange)
```

The exact opposite of `_OverlayBadge` in colour, so the two pills never blend into
each other when they sit side by side at the top of a card.

---

### 4.5 `CategoryChips` — ⚠️ currently unused

**📍 Location:** `lib/ui/core/widgets.dart:248`
**📍 Used at:** **nowhere.** Discover switched to a dropdown (see §6).
**Type:** StatelessWidget

> **Important for the team:** this widget is **not dead code by accident** — it's
> deliberately kept. Don't delete it without asking. See §12 for what it's for.

| Parameter | Type | Required | Meaning |
|---|---|---|---|
| `options` | `List<String>` | ✅ | e.g. `['All', 'Academic', 'Sports', …]` |
| `selected` | `String` | ✅ | which one is currently active |
| `onSelected` | `ValueChanged<String>` | ✅ | called with the tapped category |
| `counts` | `Map<String, int>?` | ❌ optional | if provided, labels become `"Sports (3)"` |

**What it looks like:**

```
 ┌─────────┐ ┌────────────┐ ┌─────────┐ ┌──────────────┐  ← scrolls sideways
 │ All (6) │ │ Academic(2)│ │ Sports  │ │ Seminar (2)  │
 └─────────┘ └────────────┘ └─────────┘ └──────────────┘
   selected = white text on orange
   others   = orange text on light grey
```

**The count logic (widgets.dart:262-265):**

```dart
String _label(String option) {
  final n = counts?[option];
  return n == null ? option : '$option ($n)';   // no counts → plain label
}
```

Uses `ChoiceChip`, which handles the selected/unselected styling itself.

---

### 4.6 `LoadingState` — the spinner

**📍 Location:** `lib/ui/core/widgets.dart:301`
**📍 Used at:** `discover_view.dart:100`, `registrations_list.dart:46`
**Type:** StatelessWidget

| Parameter | Type | Required | Default |
|---|---|---|---|
| `label` | `String` | ❌ optional | `'Loading events…'` |

**What it looks like:**

```
        ╭─────────╮
        │  ◠  ◠   │     CircularProgressIndicator
        ╰─────────╯
      Loading your events…    ← whatever label you passed
```

**Why the default exists:** most places want the same text, so they can write
`const LoadingState()` with no arguments. `registrations_list.dart` overrides it.

---

### 4.7 `EmptyState` — used 5 times (the most reused widget)

**📍 Location:** `lib/ui/core/widgets.dart:320`
**Type:** StatelessWidget

| Parameter | Type | Required | Meaning |
|---|---|---|---|
| `message` | `String` | ✅ | the main line |
| `icon` | `IconData?` | ❌ optional | defaults to `Icons.event_busy_outlined` |
| `details` | `String?` | ❌ optional | a smaller second line explaining how to fix it |
| `actionLabel` | `String?` | ❌ optional | text for the recovery button |
| `onAction` | `VoidCallback?` | ❌ optional | what the button does |

**What it looks like (with all 4 optional parts):**

```
            ┌────────────────────┐
            │                    │
            │         🧩         │    48px icon
            │                    │
            │  No events found.  │    ← message
            │  Try a different   │    ← details (small, grey)
            │  search or         │
            │  category.         │
            │                    │
            │  ⊘ Clear filters   │    ← OutlinedButton with
            │                    │      Icons.filter_alt_off_outlined
            └────────────────────┘
```

**Every single use in the app:**

| # | File:line | `message` | `icon` | Button? |
|---|---|---|---|---|
| 1 | `discover_view.dart:103` | "Could not load events. Pull to refresh." | `cloud_off_outlined` | no |
| 2 | `discover_view.dart:110` | "No events found." *or* "No events in this category yet." | `search_off_outlined` | ✅ only if filters are active |
| 3 | `registrations_list.dart:49` | "Could not load your events. Try again." | `cloud_off_outlined` | no |
| 4 | `registrations_list.dart:53` | "No upcoming events…" *or* "No past events yet…" | default | no |
| 5 | `detail_view.dart:38` | "Event not found." | default | no |

**The `details` + button trick (widgets.dart:363-370):** both only render when
provided, which is why use #2 can show *either* a button or a calm sentence
depending on whether the student typed a search.

**Why `if (x != null) ...[ ]` everywhere?** In Dart, `...[a, b]` (the spread
operator inside a list) inserts multiple children only when the condition is true.
Without it you'd have to write a ternary returning an empty list. **You'll see this
pattern in `auth_view.dart` and `detail_view.dart` too — get used to it.**

---

### 4.8 `confirmCancelRegistration()` — a function, not a widget

**📍 Location:** `lib/ui/core/widgets.dart:380`
**📍 Used at:** `registrations_list.dart:96` (swipe), `detail_view.dart:149` (button)
**Returns:** `Future<bool>` — `true` **only** if the student pressed the red button.

**What it looks like:**

```
        ╭──────────────────────────────────╮
        │  Cancel Registration?            │
        │                                  │
        │  Are you sure you want to cancel  │
        │  your registration for           │
        │  "Inter-School Quiz Bee"?        │   ← eventName interpolated
        │                                  │
        │  ┌────────────┐ ┌──────────────┐ │
        │  │    Keep    │ │   Cancel     │ │
        │  │ Registration│ │ Registration │ │   ← red, filled
        │  └────────────┘ └──────────────┘ │
        ╰──────────────────────────────────╯
```

**Why it's a function, not a widget:** it *performs an action* (shows a dialog and
waits for the answer). A widget only draws. This one needs to `await` the result and
return a boolean, so it has to be a function.

**The safety logic:**

```dart
final confirmed = await showDialog<bool>(…);   // true / false / null
return confirmed ?? false;                     // dismissed = null → false
```

Tapping outside the dialog, pressing back, or choosing "Keep Registration" all give
`false`. **There is no path to `true` other than the red button.**

The red button is styled with `scheme.error` so it can't be mistaken for the
neutral option — this is a destructive action.

---

## 5. `auth_view.dart` — 2 widgets

**📍 File:** `lib/ui/features/auth/views/auth_view.dart`

### 5.1 `AuthView` — login and signup in one screen

**📍 Location:** `auth_view.dart:11` (widget) + `auth_view.dart:18` (`_AuthViewState`)
**📍 Used at:** `lib/main.dart:110` (by `AuthGate`)
**Type:** StatefulWidget

**State it remembers:**

| Field | Type | Line | Meaning |
|---|---|---|---|
| `_formKey` | `GlobalKey<FormState>` | `:19` | lets you run all validators at once |
| `_email` | `TextEditingController` | `:20` | what's typed in the email box |
| `_password` | `TextEditingController` | `:21` | what's typed in the password box |
| `_isSignup` | `bool` | `:22` | `false` = login, `true` = create account |
| `_obscure` | `bool` | `:23` | `true` = password hidden as dots |

**What it looks like:**

```
   ☀/🌙                                        ← theme toggle, top-right
                                                 ┌────────┐
                                                 │ EventHub │   ← SVG logo, 56×56
                                                 └────────┘
                                                  EventHub        ← bold headline
                             Find school events. Register. Get reminded.

   ┌──────────────────────────────────────────┐
   │ ✉  Email                                 │
   │    you@school.edu                        │
   └──────────────────────────────────────────┘
   ┌──────────────────────────────────────────┐
   │ 🔒 Password                  👁          │  ← 👁 toggles _obscure
   │    ••••••••                              │
   └──────────────────────────────────────────┘
                                          Forgot password?

   ⚠ Incorrect email or password.            ← only if there IS an error (red)

   ┌──────────────────────────────────────────┐
   │              Log  in                     │  ← FilledButton, or a spinner
   └──────────────────────────────────────────┘
           New here? Create an account         ← TextButton, flips _isSignup
```

In **signup mode** the button says "Create account", the placeholder says
"At least 6 characters", and the "Forgot password?" link **disappears**.

**Why `ConstrainedBox(maxWidth: 420)` (line 41)?** On a phone the width is already
small, but on **web/desktop** the form would stretch across the whole screen.
420px keeps it looking like a login form everywhere. (This is why the app also works
as a website.)

**`SingleChildScrollView` (line 38)** — without it, when the on-screen keyboard opens
on a short phone, the buttons get cut off and you can't scroll to them.

**The five layers of the tree (lines 35-42):**

```
Scaffold
└── SafeArea            ← avoids the notch/status bar
    └── Center
        └── SingleChildScrollView
            └── Padding(24)
                └── ConstrainedBox(maxWidth: 420)
                    └── Form(key: _formKey)
                        └── Column(crossAxisAlignment: stretch)
```

**`crossAxisAlignment: stretch`** (line 45) makes every child fill the width, so you
don't have to set a width on each field.

**The two fields (lines 82-129), fully annotated:**

```dart
TextFormField(
  controller: _email,
  decoration: const InputDecoration(
    labelText: 'Email', hintText: 'you@school.edu',
    prefixIcon: Icon(Icons.email_outlined),      // 📧 icon inside the box
    border: OutlineInputBorder(),
  ),
  enabled: !vm.isLoading,                        // greys out while submitting
  keyboardType: TextInputType.emailAddress,      // mobile shows @ and . keys
  autofillHints: const [AutofillHints.email],     // password manager support
  autocorrect: false,                            // don't "correct" an email
  onChanged: (_) => vm.clearError(),             // clear the old error on typing
  validator: (v) => (v == null || !v.contains('@') || !v.contains('.'))
      ? 'Enter a valid email address.' : null,   // null means "valid"
)
```

**`validator` returning `null` = valid.** Returning a `String` = invalid, and Flutter
shows that string in red under the field. That's the whole contract.

**`_submit()` (line 194-202) — the press handler:**

```dart
Future<void> _submit(BuildContext context, AuthViewModel vm) async {
  if (!_formKey.currentState!.validate()) return;   // any field bad → stop
  final ok = _isSignup
      ? await vm.signUp(_email.text, _password.text)
      : await vm.signIn(_email.text, _password.text);
  if (ok && context.mounted) {
    TextInput.finishAutofillContext();              // let the password manager save
  }
}
```

**Line 195 is the gatekeeper:** `validate()` runs *every* validator and returns
`true` only if all passed. One line prevents all bad submissions.

**`dispose()` (line 26-30) — always do this:**

```dart
void dispose() {
  _email.dispose();
  _password.dispose();
  super.dispose();
}
```

Every `TextEditingController` you create **must** be disposed or it leaks memory.
This is the #1 thing an examiner looks for in a StatefulWidget.

---

### 5.2 `_ForgotPasswordDialog` — the reset popup

**📍 Location:** `auth_view.dart:218` (widget) + `:226` (state)
**📍 Used at:** `auth_view.dart:208` (inside `showDialog`)
**Type:** StatefulWidget · 🔒 private

**Why private?** It's an implementation detail of `AuthView`. Other screens can never
open it, and it can never be used accidentally.

| Parameter | Type | Required | Meaning |
|---|---|---|---|
| `initialEmail` | `String` | ✅ | prefills whatever the student already typed |

**What it looks like — BEFORE and AFTER sending:**

```
  BEFORE                              AFTER
  ┌────────────────────────┐        ┌────────────────────────┐
  │ Reset password         │        │ Reset password         │
  │                        │        │                        │
  │ Enter your account     │        │ Password reset email   │
  │ email and we will send │        │ sent. Check your inbox.│
  │ a reset link.          │        │                        │
  │                        │        └────────────────────────┘
  │ ┌────────────────────┐ │         [     Done     ]
  │ ✉ Email              │ │         ← the "Send reset link"
  │   you@school.edu     │ │            button is GONE
  │   ⌄ (autofocus)      │ │
  │ └────────────────────┘ │         ┌───────────────────────┐
  └────────────────────────┘         │ ✉ invalid email addr… │  ← only on failure
   [ Cancel ] [ Send reset link ]
```

**How the swap happens (line 245):**

```dart
final sent = vm.resetInfo != null;     // one flag controls the whole layout
```

If a success message exists, `sent` is `true`, and every `if (!sent)` block
disappears. **One boolean redraws the entire dialog.** That's why it's a
StatefulWidget reading from the ViewModel instead of a plain StatelessWidget.

**`initState()` (line 231) uses `late final`:**

```dart
late final TextEditingController _email;

@override
void initState() {
  super.initState();
  _email = TextEditingController(text: widget.initialEmail);
}
```

**`late final` means "I'll assign this later, but exactly once, and never change it."**
Needed here because the initial text comes from `widget.initialEmail` — you can't
set that in a field initializer.

**The security note (the reason this dialog exists in this form):** the failure text
comes from `friendlyResetError()`, which for an unknown address says *"If an account
exists for this email, a reset link has been sent."* — **never** "no account found".
Otherwise an attacker could type random emails and learn which ones are registered.

---

## 6. `discover_view.dart` — 1 widget

### `DiscoverView` — the browse screen

**📍 Location:** `discover_view.dart:9` (widget) + `:17` (state)
**📍 Used at:** `lib/main.dart:148` (tab index 0)
**Type:** StatefulWidget

**State it remembers:**

| Field | Type | Line | Meaning |
|---|---|---|---|
| `_search` | `TextEditingController` | `:18` | the text in the search box |

**Why Stateful when the query lives in the ViewModel?** The VM holds the *meaning*
(`searchQuery`); the controller holds the *text being typed*. Two different jobs.

**What it looks like:**

```
   🔍 Search events…                        [×]   ← suffix × only when there's text
   ┌──────────────────────────────────────────┐
   │ ☰ Category                            ▾  │
   └──────────────────────────────────────────┘
   All (6)      ← dropdown, each option shows its count
   ────────────────────────────────
   ┌────────────────────────────────────────┐
   │            EventCard 1                  │
   ├────────────────────────────────────────┤
   │            EventCard 2                  │
   ├────────────────────────────────────────┤
   │              …                          │
   └────────────────────────────────────────┘
```

And the three other states it can be in:

```
  loading      error                 empty + filters
  ┌────────┐   ┌────────┐            ┌────────────────────┐
  │  ◠     │   │  ☁     │            │      🔍̸           │
  │Loading │   │Could   │            │ No events found.   │
  │events… │   │not load│            │ Try a different    │
  │        │   │Pull to │            │ search or category.│
  │        │   │refresh │            │  [⊘ Clear filters] │
  └────────┘   └────────┘            └────────────────────┘
```

**`initState()` (line 21-26) — starting the data load:**

```dart
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<DiscoverViewModel>().load();   // after the first frame
  });
}
```

**Why not call `load()` directly?** Because ViewModels are provided *above* this
widget, and `context.read` is only safe once the widget is attached to the tree.
`addPostFrameCallback` is the standard fix. **The same pattern appears in
`HomeShell.initState` and `RegistrationsList.initState`.**

**`build()` — the sliver list (lines 40-145):**

```
RefreshIndicator(onRefresh: () => vm.load())          ← pull to refresh
└── CustomScrollView
    ├── SliverToBoxAdapter → Padding → TextField          ← search      (lines 48-71)
    ├── SliverToBoxAdapter → Padding → DropdownButtonFormField  ← category (72-97)
    └── then EXACTLY ONE of:                              (98-141)
        ├── SliverFillRemaining(LoadingState)             ← loading
        ├── SliverFillRemaining(EmptyState)               ← error
        ├── SliverFillRemaining(EmptyState + button)      ← empty
        └── SliverPadding → SliverList.separated           ← the cards
              └── itemBuilder → EventCard(...)
```

**What are slivers?** Normal `ListView.builder` builds rows as you scroll. A
`CustomScrollView` with **slivers** lets you mix different sections — a search box,
a dropdown, a spinner, and a lazy list — in one scroll. Each section is a separate
widget that decides how much space it needs.

**`SliverFillRemaining`** = "take all the space that's left." That's how the loading
and empty states can be vertically centred in the middle of the screen.

**The card-building lines (132-139):**

```dart
itemBuilder: (context, i) {
  final event = vm.filtered[i];
  return EventCard(
    event: event,
    registered: mine.isRegistered(event.id),   // ← from the OTHER view model
    onTap: () => widget.onOpenDetail(event.id),
  );
},
```

**This is why `DiscoverView` reads two ViewModels** (lines 41-42):

```dart
final vm   = context.watch<DiscoverViewModel>();    // the events + filters
final mine = context.watch<MyEventsViewModel>();     // "am I registered?"
```

It borrows My Events' state purely to colour the badges. **No duplicate data, no
extra database call.**

**Why the dropdown has `key: ValueKey(vm.selectedCategory)` (line 76):**
`DropdownButtonFormField` remembers its own selection internally. When the selection
changes from *outside* (e.g. the student taps "Clear filters"), the widget wouldn't
notice. Changing the key forces Flutter to rebuild it from scratch with the new
value. **This is the standard fix for that exact problem.**

---

## 7. `registrations_list.dart` — 1 widget

### `RegistrationsList` — serves **two** tabs

**📍 Location:** `registrations_list.dart:11` (widget) + `:25` (state)
**📍 Used at:** `lib/main.dart:149` **and** `lib/main.dart:150`
**Type:** StatefulWidget

**This is the best reuse example in the codebase.** One widget, two screens:

```dart
// lib/main.dart:149  →  My Events tab
RegistrationsList(showPast: false, onOpenDetail: _openDetail)

// lib/main.dart:150  →  History tab
RegistrationsList(showPast: true,  onOpenDetail: _openDetail)
```

**Inputs:**

| Parameter | Type | Required | Meaning |
|---|---|---|---|
| `showPast` | `bool` | ✅ | `false` = upcoming (My Events), `true` = past (History) |
| `onOpenDetail` | `void Function(String)` | ✅ | callback with the event ID |

**What one boolean changes:**

| `showPast` | `false` (My Events) | `true` (History) |
|---|---|---|
| Data shown | `vm.upcoming` | `vm.history` |
| Empty message | "No upcoming events. Browse and register for one." | "No past events yet. Events you attended will appear here." |
| Swipe to cancel | ✅ enabled | ❌ `DismissDirection.none` — read-only |
| Sort order | soonest first | most recent first |

**What it looks like:**

```
   ← swipe left to reveal this →

  ┌──────────────────────────────────────┐  ┌─────────────────┐
  │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│  │  🗑 Cancel      │  ← red bar
  │            EventCard                  │  │    registration │
  ├──────────────────────────────────────┤  └─────────────────┘
  │            EventCard                  │
  └──────────────────────────────────────┘
```

**The `Dismissible` widget (lines 67-86):** lets the student swipe a card away.

```dart
Dismissible(
  key: ValueKey(event.id),                            // must be unique per card
  direction: widget.showPast
      ? DismissDirection.none                          // History: cannot swipe
      : DismissDirection.endToStart,                   // My Events: swipe left only
  background: Container(… red … delete icon),          // what shows behind
  confirmDismiss: (_) => _confirmCancel(context, vm, event),  // MUST confirm first
  child: EventCard(event: event, registered: true, …),
)
```

**Three details that matter a lot:**

1. **`confirmDismiss` runs before anything is deleted.** Returning `false` cancels
   the swipe entirely. **Nothing is lost by an accidental swipe.**
2. **Returning `false` after a failed cancel makes the card snap back** — so the list
   can never show something the database disagrees with.
3. **`key: ValueKey(event.id)`** — a `Dismissible` with duplicate or missing keys
   throws "Duplicate keys" or behaves incorrectly when the list reorders. The event
   ID is unique, so it's the right key.

**`_confirmCancel()` (lines 94-110) — the careful handler:**

```dart
Future<bool> _confirmCancel(context, vm, event) async {
  final confirmed = await confirmCancelRegistration(context, eventName: event.name);
  if (!confirmed || !context.mounted) return false;      // dismissed → abort
  final userId = context.read<AuthViewModel>().userId;
  if (userId == null || !context.mounted) return false;  // logged out → abort
  final ok = await vm.cancel(userId, event);             // do the work
  if (context.mounted) {
    final msg = vm.takeNotice() ?? (ok ? 'Cancelled.' : 'Failed.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  return ok;                                              // false = snap back
}
```

**`context.mounted` is checked three times.** After every `await`, the student could
have navigated away — and using a dead `context` crashes the app. **This is
required in modern Flutter and is the single most commonly missed detail.**

**`vm.takeNotice() ?? (ok ? … : …)`** — the ViewModel set a friendly message if it
could; the `??` fallback covers the case where it didn't. Either way a SnackBar shows.

---

## 8. `detail_view.dart` — 3 widgets

**📍 File:** `lib/ui/features/detail/views/detail_view.dart`

### 8.1 `DetailView` — one event, full page

**📍 Location:** `detail_view.dart:15`
**📍 Used at:** `lib/main.dart:91` — inside `onGenerateRoute`
**Type:** StatelessWidget

**Inputs:**

| Parameter | Type | Required | Meaning |
|---|---|---|---|
| `eventId` | `String` | ✅ | which event to show |

**Why only the ID, not the whole `Event`?** Because the route is opened by name
(`'/detail'`), and a named route can only carry one simple value. The widget then
**looks the event up itself** — which also means it always shows the freshest copy.

**The lookup (lines 21-33) — searching three lists:**

```dart
final discover = context.watch<DiscoverViewModel>();
final mine     = context.watch<MyEventsViewModel>();
Event? event;
for (final e in [...discover.all, ...mine.upcoming, ...mine.history]) {
  if (e.id == eventId) { event = e; break; }
}
```

**Three lists, not one**, because the card could have been tapped from Discover, from
My Events, **or** from History. If we only searched Discover, a registered past event
would show "Event not found."

**Line 35-40 — the graceful failure:**

```dart
if (event == null) {
  return Scaffold(
    appBar: AppBar(title: const Text('Event')),
    body: const EmptyState(message: 'Event not found.'),
  );
}
```

An event can genuinely vanish: staff delete it from the Firebase console while
someone has the page open. **We show a message instead of crashing.**

**What it looks like:**

```
  ←                        Inter-School Quiz Bee              ← category is the title
  ┌──────────────────────────────────────────┐
  │                                          │
  │              [ big photo ]               │  200px tall, 16px rounded
  │                                          │
  └──────────────────────────────────────────┘

  Inter-School Quiz Bee                      ← headlineSmall, bold

  🕐 Nov 15, 2026 · 1:00 PM
  📍 Library Hall
     Main Campus, Library 2F

  Annual academic quiz competition. Teams of
  three, all year levels welcome.

  ✓ Registered                               ← only if registered && not past
                                              (green, EventHubTheme.success)

  ┌────────────────────────────────────────┐
  │  🗺  Open location in Maps              │  OutlinedButton.icon
  └────────────────────────────────────────┘
  ┌────────────────────────────────────────┐
  │  📅  Add to Calendar                    │  OutlinedButton.icon
  └────────────────────────────────────────┘
  ┌────────────────────────────────────────┐
  │     Register for this event            │  FilledButton (orange)
  └────────────────────────────────────────┘
```

**The three-way button (lines 104-127) — the whole state machine:**

```dart
if (past)                     // the event already happened
  → disabled button: "Registration closed — event has passed"
else if (registered)          // you already have a spot
  → FilledButton.tonal:  "Cancel registration"
else                          // normal case
  → FilledButton:         "Register for this event"
```

**One `if/else if/else` covers every possible situation** — no screen can get into an
impossible state like "Register" showing on a past event. If asked *"how do you
guarantee the button is always correct?"* — this is the answer: **all three facts are
computed once at the top (lines 42-43) and the layout is a pure function of them.**

**Why `FilledButton.tonal` for cancel?** It's the *same action position* but visually
less aggressive than the orange Register button. You never have to look twice to know
which one you pressed. Destructive actions get `confirmCancelRegistration()` first.

**The four handlers:**

| Handler | Line | Does |
|---|---|---|
| `_register` | 134 | reads `userId`, `vm.register(...)`, SnackBar from `takeNotice()` |
| `_cancel` | 147 | **confirmation dialog first**, then `vm.cancel(...)`, SnackBar |
| `_openMaps` | 164 | `MapsLauncher.openEvent(event)`, SnackBar only if it returned `false` |
| `_openCalendar` | 172 | `CalendarLauncher.addEvent(event)`, SnackBar only on `false` |

**All four follow the identical shape:**

```dart
final ok = await <do the thing>(…);
if (context.mounted) {
  final msg = vm.takeNotice() ?? (ok ? 'Success.' : 'Failed.');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
```

**Learn this shape and you understand 80% of the buttons in this app.**

---

### 8.2 `_InfoRow` — an icon beside text

**📍 Location:** `detail_view.dart:181`
**📍 Used at:** `detail_view.dart:59` (date) and `detail_view.dart:63` (venue)
**Type:** StatelessWidget · 🔒 private

| Parameter | Type | Required | Meaning |
|---|---|---|---|
| `icon` | `IconData` | ✅ | e.g. `Icons.calendar_today_outlined` |
| `label` | `String` | ✅ | the text — `\n` allowed for 2 lines |

**What it looks like:**

```
  🕐  Nov 15, 2026 · 1:00 PM
  📍  Library Hall
      Main Campus, Library 2F
```

**The code (lines 187-199), and the two decisions inside it:**

```dart
Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,   // ① align tops, not centers
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(label)),                 // ② Expanded = take remaining width
    ],
  ),
)
```

① **`CrossAxisAlignment.start`** is essential here — the venue text is two lines and
the icon is one. With the default `.center`, the icon would float in the middle of the
two lines instead of sitting at the top.

② **`Expanded`** stops the text from overflowing. In a `Row`, a long `Text` normally
throws a layout error; `Expanded` says *"take whatever width is left."*

**Why extract this at all?** It's used twice with different icons. Copy-pasting that
`Row` would be 24 duplicated lines that could drift apart.

---

### 8.3 `_HeroImage` — the big photo

**📍 Location:** `detail_view.dart:202`
**📍 Used at:** `detail_view.dart:51`
**Type:** StatelessWidget · 🔒 private

| Parameter | Type | Required |
|---|---|---|
| `event` | `Event` | ✅ |

**What it looks like:**

```
  ┌────────────────────────────────────────┐
  │                                        │   200px tall, full width,
  │           [ the photo ]                │   16px rounded corners
  │                                        │
  └────────────────────────────────────────┘
```

With two fallbacks, same as `_ImageHeader`:

```
  no imageUrl?        →  grey box + 🗓 (64px)
  image fails to load →  grey box + broken-image icon (64px)
```

**⚠️ Important difference from `_ImageHeader` in `widgets.dart`:** this version wraps
the image in **`ClipRRect`**, so the photo has rounded corners. `_ImageHeader` doesn't,
because the card's own `Card(clipBehavior: Clip.antiAlias)` does the rounding there.
**Rounding happens once, in whichever widget owns the edges.**

---

## 9. `theme.dart` — the widget that isn't one

**📍 Location:** `lib/ui/core/theme.dart:5`
**Type:** a plain class with `static` members — **not a widget**

**What it is:** the app's entire colour and style vocabulary. No screen ever writes a
hex code, because that would break dark mode.

**Why it's in this guide:** `MaterialApp` uses it (`main.dart:82-83`), and widgets
pull colours from it via `Theme.of(context)`. If a member asks *"where does the orange
come from?"* — this file.

**The API:**

| Member | Line | What it gives you |
|---|---|---|
| `EventHubTheme.primary` | `:6` | `#EA580C` — the brand orange |
| `EventHubTheme.softOrange` | `:8` | `#F97316` — lighter accent |
| `EventHubTheme.golden` | `:9` | `#FDBA74` — warm highlight |
| `EventHubTheme.background` | `:11` | `#FFFFFF` — pure white page |
| `EventHubTheme.muted` / `mutedFg` / `border` | `:14-16` | greys for subtle surfaces |
| `EventHubTheme.danger` | `:17` | `#B3261E` — destructive red |
| `EventHubTheme.success` | `:19` | `#2E7D32` — the green "Registered" |
| `EventHubTheme.light()` | `:59` | the whole light `ThemeData` |
| `EventHubTheme.dark()` | `:155` | the whole dark `ThemeData` |

**How a widget uses it (2 patterns, both in the codebase):**

```dart
// Pattern 1 — pull a raw token (widgets.dart:237, detail_view.dart:73)
color: EventHubTheme.primary

// Pattern 2 — pull from the active theme so dark mode works automatically
color: Theme.of(context).colorScheme.error
```

**Pattern 2 is preferred.** It returns *different* colours depending on whether
dark mode is active. **Pattern 1 always returns the same colour** — fine for the brand
orange, wrong for anything that must stay readable on a dark background.

**The customisation `light()` and `dark()` apply** (this is the visual style of the
whole app):

| Widget themed | Style |
|---|---|
| Cards | no shadow, 20px radius, 1px border |
| Buttons | minimum 48px tall (touch target), 14px radius |
| Dialogs | 24px radius |
| SnackBars | floating, dark pill |
| NavigationBar | no tint, pale-orange selected pill |
| Text fields | filled, 16px radius, 2px orange focus border |
| AppBar | flat, no shadow on scroll |

---

## 10. Full widget trees for every screen

Copy-paste these when you need to explain a screen from top to bottom.

### 10.1 Login screen

```
AuthView                                        auth_view.dart:11
└── Scaffold
    └── SafeArea
        └── Center
            └── SingleChildScrollView
                └── Padding(24)
                    └── ConstrainedBox(maxWidth: 420)
                        └── Form
                            └── Column
                                ├── Row [ Spacer, IconButton(theme) ]
                                ├── SvgPicture.asset('logo.svg', 56×56)
                                ├── Text('EventHub', headlineMedium)
                                ├── Text('Find school events. Register. Get reminded.')
                                ├── TextFormField(email)
                                ├── TextFormField(password, suffixIcon: 👁)
                                ├── TextButton('Forgot password?')
                                ├── Text(errorMessage, red)          ← conditional
                                ├── FilledButton(Log in / spinner)   ← conditional
                                └── TextButton('New here? Create an account')
```

### 10.2 Discover

```
HomeShell                                       main.dart:115
├── AppBar [ logo SVG + 'EventHub' | theme | logout ]
├── body: DiscoverView                         main.dart:148
│   └── RefreshIndicator
│       └── CustomScrollView
│           ├── SliverToBoxAdapter → TextField (search)
│           ├── SliverToBoxAdapter → DropdownButtonFormField (category + counts)
│           └── SliverFillRemaining(LoadingState | EmptyState)
│              or SliverPadding → SliverList.separated
│                     └── EventCard × N        widgets.dart:8
│                           └── Card → InkWell → SizedBox(220) → Stack
│                                 ├── _ImageHeader            widgets.dart:175
│                                 ├── gradient scrim
│                                 ├── _CategoryTag            widgets.dart:222
│                                 ├── _OverlayBadge           widgets.dart:158
│                                 └── text column (name/date/venue/desc)
└── NavigationBar (3 destinations)
```

### 10.3 My Events / History

```
HomeShell
└── body: RegistrationsList(showPast: X)       registrations_list.dart:11
    └── LoadingState | EmptyState
       or RefreshIndicator
          └── ListView.separated
              └── Dismissible                    ← My Events only
                  └── background (red bar)
                  └── confirmDismiss → confirmCancelRegistration()
                  └── child: EventCard           widgets.dart:8
└── NavigationBar
```

### 10.4 Event detail

```
MaterialApp.onGenerateRoute('/detail')          main.dart:86
└── DetailView(eventId)                          detail_view.dart:15
    └── Scaffold
        ├── AppBar(title: event.category)
        └── SafeArea → ListView
            ├── _HeroImage                       detail_view.dart:202
            ├── Text(name)
            ├── _InfoRow(calendar, date)         detail_view.dart:181
            ├── _InfoRow(place, venue)           detail_view.dart:181
            ├── Text(description)
            ├── Row(✓ Registered)                ← conditional
            ├── OutlinedButton.icon(Maps)
            ├── OutlinedButton.icon(Calendar)
            └── FilledButton(Register | Cancel | Closed)   ← 3-way
```

---

## 11. Widgets written inline (not extracted)

Flutter built-in widgets used directly in `build()` methods. There's no need to
remember all of them — here are the ones that appear and what they do:

| Widget | What it does | Where used |
|---|---|---|
| `Scaffold` | The standard page frame: `appBar`, `body`, `bottomNavigationBar` | `main.dart:35`, `main.dart:153`, `auth_view.dart:35`, `detail_view.dart:45/36` |
| `AppBar` | The coloured bar at the top with `title` and `actions` | `main.dart:154`, `detail_view.dart:46` |
| `SafeArea` | Adds padding so content avoids the notch / status bar | `main.dart:182`, `auth_view.dart:36`, `detail_view.dart:47` |
| `Text` | Displays text. `style:` controls size/weight/colour | everywhere |
| `Column` | Stacks children **vertically** | `auth_view.dart:44`, `widgets.dart:90/342` |
| `Row` | Stacks children **horizontally** | `main.dart:155`, `detail_view.dart:194` |
| `SizedBox` | An empty fixed-size box — used for **spacing** | everywhere (`SizedBox(height: 12)`) |
| `Center` / `Align` | Centres a child | `auth_view.dart:37`, `widgets.dart:301/341` |
| `Padding` | Adds space **around** a child | everywhere |
| `Stack` | Layers children on top of each other | `widgets.dart:30` (EventCard) |
| `Positioned` | Places a child at a specific spot inside a `Stack` | `widgets.dart:48/54/87` |
| `Container` | A box with colour, padding, border, radius | everywhere |
| `Icon` | Shows a Material icon | everywhere |
| `IconButton` | A tappable icon button | `main.dart:168/175`, `auth_view.dart:50/109` |
| `FilledButton` | The main solid orange action button | `auth_view.dart:153`, `detail_view.dart:121` |
| `FilledButton.tonal` | A softer version, for secondary actions | `detail_view.dart:113` |
| `OutlinedButton` / `.icon` | An outlined button, optionally with an icon | `detail_view.dart:86/95` |
| `TextButton` | A borderless text action | `auth_view.dart:133/171` |
| `Card` | A rounded, bordered surface | `widgets.dart:24` |
| `InkWell` | Makes its child tappable with a ripple effect | `widgets.dart:26` |
| `Image.asset` / `.network` | Shows a bundled photo / a web photo | `widgets.dart:191/204`, `detail_view.dart:223/240` |
| `Image.errorBuilder` | Shown when the image fails | both image widgets |
| `ClipRRect` | Clips a child's corners to a radius | `detail_view.dart:221/238` |
| `CircularProgressIndicator` | The spinning "loading" circle | `widgets.dart:308`, `auth_view.dart:164` |
| `DropdownButtonFormField` | The category dropdown | `discover_view.dart:75` |
| `RefreshIndicator` | Adds pull-to-refresh to a scrollable | `discover_view.dart:44`, `registrations_list.dart:59` |
| `NavigationBar` | The Material 3 bottom tab bar | `main.dart:183` |
| `NavigationDestination` | One tab's icon + label | `main.dart:187` |
| `GlobalKey<FormState>` | Lets you run all field validators at once | `auth_view.dart:19/195` |
| `TextFormField` | A text field that can validate itself | `auth_view.dart:82/101/260` |
| `TextEditingController` | Holds and listens to a text field's content | `auth_view.dart:20/21` |
| `ListView.separated` | A lazily-built list with gaps between rows | `widgets.dart:271`, `registrations_list.dart:61` |
| `Dismissible` | A swipeable row with a background action | `registrations_list.dart:67` |
| `SvgPicture.asset` | Shows an SVG (our logo) | `main.dart:158`, `auth_view.dart:63` |
| `Semantics` | Screen-reader metadata (`liveRegion: true` announces errors) | `auth_view.dart:142` |

---

## 12. Which widget do I edit if…

| Complaint | Go to |
|---|---|
| "The event cards look wrong / too tall / bad contrast" | `EventCard` — `lib/ui/core/widgets.dart:8` |
| "The 'Registered' badge is ugly" | `_OverlayBadge` — `lib/ui/core/widgets.dart:158` |
| "The category pill is the wrong colour" | `_CategoryTag` — `lib/ui/core/widgets.dart:222` |
| "Photos look stretched / wrong shape" | `_ImageHeader` — `lib/ui/core/widgets.dart:175` |
| "The big photo on the detail page is square" | `_HeroImage` — `detail_view.dart:202` |
| "The empty screen is confusing" | `EmptyState` — `lib/ui/core/widgets.dart:320` |
| "The loading text is wrong" | `LoadingState` — `lib/ui/core/widgets.dart:301` |
| "The cancel popup wording is wrong" | `confirmCancelRegistration` — `lib/ui/core/widgets.dart:380` |
| "The search box looks wrong" | `discover_view.dart:51-71` |
| "The category dropdown looks wrong" | `discover_view.dart:75-96` |
| "Swipe-to-delete is broken" | `Dismissible` in `registrations_list.dart:67-86` |
| "The tabs/app bar are wrong" | `HomeShell` — `lib/main.dart:145-204` |
| "All colours are wrong" | `EventHubTheme` — `lib/ui/core/theme.dart:5` |
| "The Register button logic is wrong" | `DetailView` three-way `if` — `detail_view.dart:104-127` |
| "I want to restore the chip filter" | `CategoryChips` — `lib/ui/core/widgets.dart:248` (already written!) |

---

## 13. Widget Q&A

**Q1. What is a widget?**
A description of a piece of screen. Everything in Flutter is a widget — a button, a
line of text, and the whole page. Widgets combine to build the tree Flutter draws.

**Q2. Stateless vs Stateful?**
Stateless = never changes by itself. Stateful = remembers something between rebuilds
(like which tab is open). If a class needs a field that changes without an outside
cause, it's Stateful.

**Q3. How many widgets did we write and where?**
20 widget classes across 6 files — 4 in `main.dart`, 8 in `ui/core/widgets.dart`,
2 in `auth_view.dart`, 1 each in `discover_view.dart` and `registrations_list.dart`,
and 3 in `detail_view.dart`.

**Q4. Why is `HomeShell` Stateful?**
It must remember which tab is selected (`int _tab` at `main.dart:123`).

**Q5. Why is `EventCard` Stateless?**
Everything it shows — the event, whether you're registered — arrives as a parameter.
It never decides anything by itself, so it has nothing to remember.

**Q6. What's the `_` at the start of a name?**
Private. `_InfoRow`, `_HeroImage`, `_AuthViewState` can only be used inside their own
file. It keeps the public API small so nobody depends on an internal detail.

**Q7. What does `const` on a constructor do?**
"This widget never changes — build it once and reuse it." It's a real performance
win, which is why nearly every widget in this project has it.

**Q8. What is `super.key`?**
Flutter's own identity label for a widget, needed when reordering lists. Always
accept it; never set it manually.

**Q9. What does `build()` do?**
Returns the widget tree for this piece of screen. Flutter calls it again whenever
something it depends on changes — that's the whole rebuild model.

**Q10. Why does `AuthGate` use `watch` instead of `read`?**
Because it must **rebuild** when login state changes. `read` would give the same
value forever and the screen would never switch.

**Q11. Why do two buttons read the ViewModel but use different functions?**
`watch` is for **display** (`icon: Icon(context.watch<ThemeController>().toggleIcon)`
— the icon must update). `read` is for **actions** (`onPressed: () =>
context.read<ThemeController>().toggle()` — just call it, no rebuild needed).

**Q12. How does the detail screen find the event if it's only given an ID?**
It searches three lists (`discover.all`, `mine.upcoming`, `mine.history`) at lines
23-33. Named routes can only carry simple values, so the widget does the lookup
itself — which also guarantees it shows fresh data.

**Q13. What's a `Key` and why does `EventCard` need one?**
`Dismissible` at `registrations_list.dart:68` requires a unique `ValueKey(event.id)`
so Flutter can tell the cards apart when the list changes. Duplicate keys throw
errors; a missing key makes the swipe behave unpredictably.

**Q14. What are slivers, and why did Discover need them?**
Slivers let you build one scrollable screen out of different sections. Discover needs
a search box, a dropdown, and a lazy list — `CustomScrollView` with `SliverToBoxAdapter`
and `SliverList.separated` handles that; a plain `ListView` can't mix them.

**Q15. Why is there a `Builder` in `main.dart:79`?**
Because `MaterialApp` needs to `watch` a Provider that sits **above** it. `Builder`
creates a `context` from *below* the provider, so the `watch` resolves. Without it:
`ProviderNotFoundException`.

**Q16. Why does `EmptyState` have so many optional parameters?**
Because one widget must cover five different situations (loading error, no results,
filtered-empty, no registrations, event not found). Optional parameters let each call
site say only what it needs.

**Q17. Why is `CategoryChips` kept when nothing uses it?**
Discover moved to a dropdown (better for 6 categories and long labels). The widget is
~50 lines, documented, and reusable — cheaper to keep than to rewrite. Documented as
a deliberate choice in `easy_code_summary.md` §15 so nobody "cleans it up" by mistake.

**Q18. How does the "Clear filters" button appear only when needed?**
`discover_view.dart:108-124` passes `actionLabel` and `onAction` to `EmptyState` only
when `vm.hasActiveFilters` is true. `EmptyState` renders the button only if both are
non-null (widgets.dart:363).

**Q19. Why does `AuthView` use `dispose()`?**
`TextEditingController`s create native resources. If you don't call `.dispose()` on
them, memory leaks every time the screen is rebuilt. **Every StatefulWidget that
creates a controller must dispose it.**

**Q20. Which widget would you add first if we had another week?**
A `StudentProfileCard` in `lib/ui/core/widgets.dart`, reused by the detail page and a
new profile tab — following the `EventCard` pattern: one small StatelessWidget, pure
inputs, no logic inside.

---

*Found a widget not explained here? Add it so the next person doesn't have to
open all 6 files to find it.*