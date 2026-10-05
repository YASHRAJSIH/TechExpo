import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubits/bookmarks_cubit.dart';

import 'models/session.dart';
import 'pages/bookmarks_page.dart';
import 'pages/session_detail_page.dart';
import 'pages/sessions_page.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const TechExpoApp());
}

class TechExpoApp extends StatelessWidget {
  const TechExpoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookmarksCubit(),
      child: MaterialApp(
        title: 'MunichTech EXPO',
        debugShowCheckedModeBanner: false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
