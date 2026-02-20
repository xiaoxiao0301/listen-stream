import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../platform_util.dart';
import 'tv_focus_card.dart';

/// TV-specific scaffold: side navigation + content area (C.8).
///
/// Side nav is collapsed by default; revealed by pressing Left D-pad.
class TvScaffold extends ConsumerStatefulWidget {
  const TvScaffold({super.key, required this.child});
  final Widget child;

  /// Wraps any page with TvScaffold when running on TV, otherwise passes through.
  static Widget wrap(Widget child) =>
      PlatformUtil.isTV ? TvScaffold(child: child) : child;

  @override
  ConsumerState<TvScaffold> createState() => _TvScaffoldState();
}

class _TvScaffoldState extends ConsumerState<TvScaffold> {
  bool _navOpen = false;
  final _navFocusNode = FocusNode();

  @override
  void dispose() { _navFocusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Row(
        children: [
          // ── Side navigation ─────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _navOpen ? 200 : 64,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 48),
                _NavItem(icon: Icons.home, label: '首页', open: _navOpen,
                    onTap: () { context.go('/'); setState(() => _navOpen = false); }),
                _NavItem(icon: Icons.library_music, label: '我的', open: _navOpen,
                    onTap: () { context.go('/library'); setState(() => _navOpen = false); }),
                const Spacer(),
                _NavItem(icon: _navOpen ? Icons.chevron_left : Icons.chevron_right,
                    label: _navOpen ? '收起' : '展开', open: _navOpen,
                    onTap: () => setState(() => _navOpen = !_navOpen)),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: FocusTraversalGroup(child: widget.child),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.open, required this.onTap});
  final IconData icon;
  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TvFocusCard(
      onSelect: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon),
            if (open) ...[const SizedBox(width: 12), Text(label)],
          ],
        ),
      ),
    );
  }
}
