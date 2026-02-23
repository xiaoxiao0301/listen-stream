import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/theme.dart';
import '../design/tokens.dart';

class NavItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const NavItem({required this.icon, required this.label, this.onTap});
}

class LeftNav extends ConsumerStatefulWidget {
  final double width;
  final List<NavItem> items;
  final int activeIndex;
  const LeftNav({super.key, this.width = 240, required this.items, this.activeIndex = 0});

  @override
  ConsumerState<LeftNav> createState() => _LeftNavState();
}

class _LeftNavState extends ConsumerState<LeftNav> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isGlass = themeMode == AppThemeMode.glass;
    
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: isGlass
            ? Colors.white.withOpacity(0.05)
            : Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: isGlass ? ImageFilter.blur(sigmaX: 20, sigmaY: 20) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App branding at top
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Listen',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Stream',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: List.generate(widget.items.length, (i) {
                      final item = widget.items[i];
                      final isActive = i == widget.activeIndex;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hovered = i),
                          onExit: (_) => setState(() => _hovered = null),
                          child: GestureDetector(
                            onTap: item.onTap,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor.withOpacity(0.15),
                                          Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                        ],
                                      )
                                    : null,
                                color: !isActive && _hovered == i
                                    ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              transform: Matrix4.translationValues(
                                0,
                                (_hovered == i ? -2 : 0).toDouble(),
                                0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 24,
                                    color: isActive
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                        color: isActive
                                            ? Theme.of(context).primaryColor
                                            : null,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                // Theme switcher at bottom
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _NavThemeSwitcher(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Theme switcher for navigation sidebar
class _NavThemeSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    
    return PopupMenuButton<AppThemeMode>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.palette_outlined,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '主题设置',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_up_rounded,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
      tooltip: '选择主题',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        _buildThemeItem(context, ref, AppThemeMode.light, '明亮', Icons.wb_sunny_rounded, currentTheme),
        _buildThemeItem(context, ref, AppThemeMode.dark, '深色', Icons.nightlight_round, currentTheme),
        _buildThemeItem(context, ref, AppThemeMode.glass, '玻璃', Icons.blur_on_rounded, currentTheme),
        _buildThemeItem(context, ref, AppThemeMode.warm, '温暖', Icons.local_fire_department_rounded, currentTheme),
      ],
      onSelected: (mode) {
        ref.read(themeProvider.notifier).setTheme(mode);
      },
    );
  }
  
  PopupMenuItem<AppThemeMode> _buildThemeItem(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode mode,
    String label,
    IconData icon,
    AppThemeMode current,
  ) {
    final isSelected = mode == current;
    return PopupMenuItem<AppThemeMode>(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Theme.of(context).primaryColor : null,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check_rounded,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}
