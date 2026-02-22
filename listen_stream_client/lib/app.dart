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
import 'features/song/page.dart';
import 'features/search/page.dart';
import 'features/ranking/list_page.dart';
import 'features/ranking/detail_page.dart';
import 'features/radio/list_page.dart';
import 'features/radio/detail_page.dart';
import 'features/singer_list/page.dart';
import 'features/mv_list/page.dart';
import 'features/mv/page.dart';
import 'shared/platform/platform_util.dart';
import 'shared/theme.dart';
import 'shared/widgets/tv/tv_components.dart';
import 'shared/widgets/left_nav.dart';
import 'shared/widgets/player_bar.dart';
import 'core/responsive/responsive.dart';

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
          GoRoute(path: '/radio', builder: (_, __) => const RadioListPage()),
          GoRoute(
            path: '/radio/:radioId',
            builder: (_, state) => RadioDetailPage(radioId: state.pathParameters['radioId']!),
          ),
          GoRoute(path: '/singer-list', builder: (_, __) => const SingerListPage()),
          GoRoute(path: '/mv-list', builder: (_, __) => const MvListPage()),
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
          GoRoute(
            path: '/song/:mid',
            builder: (_, state) => SongDetailPage(songMid: state.pathParameters['mid']!),
          ),
          GoRoute(
            path: '/mv/:vid',
            builder: (_, state) => MvDetailPage(vid: state.pathParameters['vid']!),
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

/// Bottom-nav shell (mobile/desktop). TV uses side navigation.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/search');
      case 2:
        context.go('/library');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilderWithInfo(
      builder: (context, deviceType, constraints) {
        // TV端使用侧边栏导航（LeftNav）
        if (deviceType == DeviceType.tv || PlatformUtil.isTV) {
          return Row(
            children: [
              LeftNav(
                width: 240,
                activeIndex: _selectedIndex,
                items: [
                  NavItem(icon: Icons.home_outlined, label: '首页', onTap: () => context.go('/')),
                  NavItem(icon: Icons.search_outlined, label: '搜索', onTap: () => context.go('/search')),
                  NavItem(icon: Icons.library_music_outlined, label: '我的音乐', onTap: () => context.go('/library')),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: widget.child),
                    const PlayerBar(),
                  ],
                ),
              ),
            ],
          );
        }

        // 桌面端使用侧边栏导航
        if (deviceType == DeviceType.desktop) {
          return Row(
            children: [
              LeftNav(
                width: 240,
                activeIndex: _selectedIndex,
                items: [
                  NavItem(icon: Icons.home_outlined, label: '首页', onTap: () => context.go('/')),
                  NavItem(icon: Icons.search_outlined, label: '搜索', onTap: () => context.go('/search')),
                  NavItem(icon: Icons.library_music_outlined, label: '我的音乐', onTap: () => context.go('/library')),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: widget.child),
                    const PlayerBar(),
                  ],
                ),
              ),
            ],
          );
        }

        // 移动端使用底部导航
        return Scaffold(
          body: widget.child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: '首页',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: '搜索',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: '我的',
              ),
            ],
          ),
        );
      },
    );
  }
}
