import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/attendance/attendance_screen.dart';
import 'features/onboarding/age_gate_screen.dart';
import 'features/timetable/timetable_grid_screen.dart';
import 'features/timetable/timetable_providers.dart';
import 'features/today/today_view_screen.dart';
import 'services/timetable_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  bool _isAgeConfirmed = false;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageProvider);
    _isAgeConfirmed = storage.isAgeConfirmed();

    // Seed default demo class page and sample schedule for instant testing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(currentPageProvider.notifier).createDefaultPageIfEmpty();
      await ref.read(timetableEntriesProvider.notifier).seedSampleSchedule();

      // Check for deep link / referrer pageId to auto-follow without account
      final uri = Uri.base;
      final queryPageId = uri.queryParameters['page_id'] ?? uri.queryParameters['id'];
      if (queryPageId != null && queryPageId.isNotEmpty) {
        await storage.setFollowedPageId(queryPageId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: _isAgeConfirmed
          ? const MainNavigationShell()
          : AgeGateScreen(
              onConfirmed: () {
                setState(() => _isAgeConfirmed = true);
              },
            ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TodayViewScreen(),
    TimetableGridScreen(),
    AttendanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Timetable',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Attendance',
          ),
        ],
      ),
    );
  }
}
