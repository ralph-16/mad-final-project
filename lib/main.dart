import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'data/services/auth_service.dart';
import 'data/services/event_repository.dart';
import 'data/services/notification_service.dart';
import 'data/services/registration_repository.dart';
import 'firebase_options.dart';
import 'ui/core/theme.dart';
import 'ui/core/theme_controller.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/auth/views/auth_view.dart';
import 'ui/features/detail/views/detail_view.dart';
import 'ui/features/discover/view_models/discover_view_model.dart';
import 'ui/features/discover/views/discover_view.dart';
import 'ui/features/my_events/view_models/my_events_view_model.dart';
import 'ui/features/my_events/views/registrations_list.dart';

/// Tries Firebase; falls back to in-memory services so the UI
/// runs before `flutterfire configure` has been done.
Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e) {
    debugPrint('Firebase unavailable, using mock services: $e');
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await _initFirebase();
  final theme = ThemeController();
  await theme.load();
  runApp(EventHubApp(firebaseReady: firebaseReady, theme: theme));
}

class EventHubApp extends StatelessWidget {
  const EventHubApp({super.key, required this.firebaseReady, required this.theme});
  final bool firebaseReady;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    final AuthService auth = firebaseReady
        ? FirebaseAuthService(FirebaseAuth.instance)
        : MockAuthService();
    final EventRepository events = firebaseReady
        ? FirestoreEventRepository(FirebaseFirestore.instance)
        : MockEventRepository();
    final RegistrationRepository registrations = firebaseReady
        ? FirestoreRegistrationRepository(FirebaseFirestore.instance)
        : MockRegistrationRepository();
    final NotificationService notifications =
        LocalNotificationService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider(
            create: (_) => AuthViewModel(auth)),
        ChangeNotifierProvider(
            create: (_) => DiscoverViewModel(events)),
        ChangeNotifierProvider(
          create: (_) => MyEventsViewModel(
            registrations: registrations,
            events: events,
            notifications: notifications,
          ),
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
              title: 'EventHub',
              theme: EventHubTheme.light(),
              darkTheme: EventHubTheme.dark(),
              themeMode: context.watch<ThemeController>().mode,
              home: const AuthGate(),
              onGenerateRoute: (settings) {
                if (settings.name == '/detail' &&
                    settings.arguments is String) {
                  return MaterialPageRoute(
                    builder: (_) =>
                        DetailView(eventId: settings.arguments as String),
                  );
                }
                return null;
              },
            ),
      ),
    );
  }
}

/// Signed-out students see auth; signed-in see the tabbed app.
/// Registrations stay per-account (Story 1) via the Auth UID.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthViewModel>().signedIn;
    if (!signedIn) return const AuthView();
    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Register/Cancel state on the detail page and Discover badges depend
    // on this student's registrations, so fetch them at sign-in as well —
    // not only when the My Events / History tabs open, since Discover is
    // the entry tab and its detail view reads MyEventsViewModel directly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthViewModel>().userId;
      if (userId != null) {
        context.read<MyEventsViewModel>().load(userId);
      }
    });
  }

  void _openDetail(String eventId) {
    Navigator.of(context).pushNamed('/detail', arguments: eventId);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DiscoverView(onOpenDetail: _openDetail),
      RegistrationsList(showPast: false, onOpenDetail: _openDetail),
      RegistrationsList(showPast: true, onOpenDetail: _openDetail),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 8),
            const Text('EventHub'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(context.watch<ThemeController>().toggleIcon),
            tooltip:
                context.watch<ThemeController>().toggleTooltip,
            onPressed: () =>
                context.read<ThemeController>().toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Log out',
            onPressed: () => context.read<AuthViewModel>().signOut(),
          ),
        ],
      ),
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'My Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
