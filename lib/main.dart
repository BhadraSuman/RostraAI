import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/attendance/attendance_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/class_discovery_screen.dart';
import 'features/onboarding/user_profile_setup_screen.dart';
import 'features/timetable/timetable_grid_screen.dart';
import 'features/timetable/timetable_providers.dart';
import 'features/today/today_view_screen.dart';
import 'firebase_options.dart';
import 'services/firestore_sync_service.dart';
import 'services/timetable_storage.dart';
import 'services/update_checker_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Safe Firebase Initialization (with offline-first fallback)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirestoreSyncService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization note (offline mode fallback): $e');
  }

  final storage = await TimetableStorage.init();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
      ],
      child: const RostraAIApp(),
    ),
  );
}

class RostraAIApp extends ConsumerStatefulWidget {
  const RostraAIApp({super.key});

  @override
  ConsumerState<RostraAIApp> createState() => _RostraAIAppState();
}

class _RostraAIAppState extends ConsumerState<RostraAIApp> {
  bool _isLoggedIn = false;
  bool _isProfileComplete = false;
  bool _hasJoinedClass = false;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageProvider);
    _isLoggedIn = storage.isLoggedIn();
    _isProfileComplete = storage.isProfileComplete();
    _hasJoinedClass = storage.getFollowedPageId() != null;

    // Seed default demo class page and sample schedule for instant testing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(currentPageProvider.notifier).createDefaultPageIfEmpty();
        await ref.read(timetableEntriesProvider.notifier).seedSampleSchedule();

        // Check for deep link / referrer pageId to auto-follow without account on web
        if (kIsWeb) {
          final uri = Uri.base;
          final queryPageId = uri.queryParameters['page_id'] ?? uri.queryParameters['id'];
          if (queryPageId != null && queryPageId.isNotEmpty) {
            await storage.setFollowedPageId(queryPageId);
            if (mounted) setState(() => _hasJoinedClass = true);
          }
        }

        // Check for in-app updates in the background
        final updateInfo = await UpdateCheckerService.checkForUpdate();
        final navCtx = appNavigatorKey.currentContext;
        if (updateInfo != null && updateInfo.hasUpdate && navCtx != null && navCtx.mounted) {
          UpdateCheckerService.showUpdateDialog(navCtx, updateInfo);
        }
      } catch (e, st) {
        debugPrint('PostFrameCallback error: $e\n$st');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to sign out
    ref.listen<UserProfile?>(authProvider, (prev, next) {
      if (next == null && _isLoggedIn) {
        setState(() => _isLoggedIn = false);
      }
    });

    Widget activeScreen;
    if (!_isLoggedIn) {
      activeScreen = LoginScreen(
        onLoginSuccess: () {
          final storage = ref.read(storageProvider);
          setState(() {
            _isLoggedIn = true;
            _isProfileComplete = storage.isProfileComplete();
          });
        },
      );
    } else if (!_isProfileComplete) {
      activeScreen = UserProfileSetupScreen(
        onProfileComplete: () {
          setState(() => _isProfileComplete = true);
        },
      );
    } else if (!_hasJoinedClass) {
      activeScreen = ClassDiscoveryScreen(
        onClassSelected: (page, isCR) async {
          final storage = ref.read(storageProvider);
          await storage.addFollowedPage(page.id);
          await storage.savePage(page);
          await storage.setEditorMode(isCR);
          ref.read(currentPageProvider.notifier).updatePage(page);
          ref.read(isEditorModeProvider.notifier).setMode(isCR);
          setState(() => _hasJoinedClass = true);
        },
        onBack: () {
          setState(() => _isProfileComplete = false);
        },
      );
    } else {
      activeScreen = const MainNavigationShell();
    }

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: activeScreen,
    );
  }
}

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  final List<Widget> _screens = const [
    TodayViewScreen(),
    TimetableGridScreen(),
    AttendanceScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        elevation: 6,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.peachTint,
        onDestinationSelected: (idx) {
          ref.read(bottomNavIndexProvider.notifier).setIndex(idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded, color: AppTheme.burntOrange),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week_rounded, color: AppTheme.burntOrange),
            label: 'Timetable',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded, color: AppTheme.burntOrange),
            label: 'Attendance',
          ),
        ],
      ),
    );
  }
}
