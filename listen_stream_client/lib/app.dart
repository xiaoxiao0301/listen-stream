import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_notifier.dart';
import 'core/auth/auth_state.dart';
import 'features/auth/page.dart';
import 'features/home/page.dart';
import 'features/library/page.dart';
import 'features/player/page.dart';
import 'features/singer/page.dart';
import 'features/playlist/page.dart';
import 'features/album/page.dart';
import 'features/search/page.dart';
import 'features/ranking/list_page.dart';
import 'features/ranking/detail_page.dart';
import 'shared/platform/platform_util.dart';
import 'shared/theme.dart';

/// A [ChangeNotifier] that fires whenever the auth state changes,
/// used as [GoRouter.refreshListenable] so the router re-evaluates
/// its redirect without being recreated.
class _AuthChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final _authListenable = Provider<_AuthChangeNotifier>((ref) {
  final notifier = _AuthChangeNotifier();
  ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, __) {
    notifier.notify();
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

final _router = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: ref.read(_authListenable),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;
      final isLoginRoute = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const PhoneLoginPage()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
          GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
          GoRoute(path: '/ranking', builder: (_, __) => const RankingListPage()),
          GoRoute(
            path: '/ranking/:topId',
            builder: (_, state) => RankingDetailPage(topId: state.pathParameters['topId']!),
          ),
          GoRoute(
            path: '/singer/:mid',
            builder: (_, state) => SingerDetailPage(mid: state.pathParameters['mid']!),
          ),
          GoRoute(
            path: '/playlist/:id',
            builder: (_, state) => PlaylistDetailPage(playlistId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/album/:mid',
            builder: (_, state) => AlbumDetailPage(albumMid: state.pathParameters['mid']!),
          ),
          GoRoute(path: '/library', builder: (_, __) => const LibraryPage()),
          GoRoute(path: '/player', builder: (_, __) => const PlayerPage()),
        ],
      ),
    ],
  );
});

class ListenStreamApp extends ConsumerWidget {
  const ListenStreamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_router);
    return MaterialApp.router(
      title: 'Listen Stream',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      routerConfig: router,
    );
  }
}

/// Bottom-nav shell (mobile/desktop). TV uses TvScaffold instead.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (PlatformUtil.isTV) {
      return child; // TV scaffold injected at TvScaffold level
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
        NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: '搜索'),
        NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: '我的'),
      ],
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go('/');
          case 1: context.go('/search');
          case 2: context.go('/library');
        }
      },
    );
  }
}
