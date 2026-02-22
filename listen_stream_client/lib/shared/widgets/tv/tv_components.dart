import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';

/// TV端侧边栏导航
class TvSideNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<TvNavigationDestination> destinations;
  final double width;

  const TvSideNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // Logo区域
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  Icons.music_note,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                // Prevent overflow by allowing the title to flex and ellipsize
                Expanded(
                  child: Text(
                    'Listen Stream',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 导航项
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                final isSelected = index == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => onDestinationSelected(index),
                      borderRadius: BorderRadius.circular(12),
                      hoverColor:
                          Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? destination.selectedIcon
                                  : destination.icon,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            // Allow label to flex so long labels don't overflow the row
                            Expanded(
                              child: Text(
                                destination.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// TV端导航目标
class TvNavigationDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const TvNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// TV端布局包装器
class TvLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<TvNavigationDestination> destinations;

  const TvLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TvSideNavigation(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// TV端优化的网格视图
class TvGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;

  const TvGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 7,
    this.mainAxisSpacing = 24.0,
    this.crossAxisSpacing = 24.0,
    this.childAspectRatio = 1.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding ?? ResponsiveSpacing.pagePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// TV端卡片项
class TvCardItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool autofocus;
  final Widget? badge;

  const TvCardItem({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.onTap,
    this.autofocus = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: autofocus,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;

          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: isFocused
                  ? (Matrix4.identity()..scale(1.08))
                  : Matrix4.identity(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: isFocused
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  )
                                : null,
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.5),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.music_note,
                                        size: 48,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.music_note,
                                      size: 48,
                                    ),
                                  ),
                          ),
                        ),
                        if (badge != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: badge!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isFocused ? 18 : 16,
                      fontWeight: isFocused ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
