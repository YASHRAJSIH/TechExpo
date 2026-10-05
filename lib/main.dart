import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/app_config.dart';
import 'cubits/bookmarks_cubit.dart';
import 'cubits/sessions_cubit.dart';
import 'cubits/sessions_state.dart';
import 'data/bookmarks_storage.dart';
import 'data/sessions_api.dart';
import 'data/sessions_repository.dart';
import 'models/session.dart';
import 'pages/bookmarks_page.dart';
import 'pages/session_detail_page.dart';
import 'pages/sessions_page.dart';
import 'theme/app_colors.dart';

void main() {
  _setUpGlobalErrorHandling();
  runApp(TechExpoApp(config: AppConfig.fromFlavorName(appFlavor)));
}

/// Last line of defence for errors no one else caught.
/// Crashlytics would be hooked in here.
void _setUpGlobalErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      'Flutter error',
      name: 'TechExpo',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'Uncaught error',
      name: 'TechExpo',
      error: error,
      stackTrace: stack,
    );
    return true;
  };
}

class TechExpoApp extends StatelessWidget {
  const TechExpoApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SessionsCubit(
            SessionsRepository(
              api: SessionsApi(endpoint: config.sessionsEndpoint),
            ),
          )..load(),
        ),
        BlocProvider(
          create: (_) => BookmarksCubit(SharedPrefsBookmarksStorage())..load(),
        ),
      ],
      // Keeps saved bookmarks in sync with the latest session data.
      child: BlocListener<SessionsCubit, SessionsState>(
        listenWhen: (_, current) => current is SessionsLoaded,
        listener: (context, state) => context.read<BookmarksCubit>().updateFrom(
          (state as SessionsLoaded).sessions,
        ),
        child: MaterialApp(
          title: config.appName,
          debugShowCheckedModeBanner: false,
          builder: (context, child) =>
              config.wrapWithBanner(child ?? const SizedBox.shrink()),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              tertiary: AppColors.tertiary,
              surface: AppColors.neutral,
            ),
            scaffoldBackgroundColor: AppColors.neutral,
          ),
          home: const HomeShell(),
          onGenerateRoute: _onGenerateRoute,
        ),
      ),
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SessionDetailPage.routeName:
        final session = settings.arguments as Session;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SessionDetailPage(session: session),
        );
      default:
        return null;
    }
  }
}

/// Bottom navigation between the main pages.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Info page is added later.
  static const _pages = <Widget>[
    SessionsPage(),
    BookmarksPage(),
    Center(child: Text('Info')),
  ];

  static const _sessionsTab = 0;

  @override
  Widget build(BuildContext context) {
    // Back on another tab goes to Sessions first; back on Sessions exits.
    return PopScope(
      canPop: _index == _sessionsTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = _sessionsTab);
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note, color: AppColors.primary),
              label: 'Sessions',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark, color: AppColors.primary),
              label: 'Bookmarks',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info, color: AppColors.primary),
              label: 'Info',
            ),
          ],
        ),
      ),
    );
  }
}
