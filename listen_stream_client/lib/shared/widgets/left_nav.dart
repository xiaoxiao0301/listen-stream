import 'package:flutter/material.dart';
import '../design/tokens.dart';

class NavItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const NavItem({required this.icon, required this.label, this.onTap});
}

class LeftNav extends StatefulWidget {
  final double width;
  final List<NavItem> items;
  final int activeIndex;
  const LeftNav({super.key, this.width = 240, required this.items, this.activeIndex = 0});

  @override
  State<LeftNav> createState() => _LeftNavState();
}

class _LeftNavState extends State<LeftNav> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: EdgeInsets.symmetric(vertical: DesignTokens.space, horizontal: DesignTokens.space / 2),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(widget.items.length, (i) {
          final item = widget.items[i];
          final isActive = i == widget.activeIndex;

          return MouseRegion(
            onEnter: (_) => setState(() => _hovered = i),
            onExit: (_) => setState(() => _hovered = null),
            child: GestureDetector(
              onTap: item.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).primaryColor.withOpacity(0.08)
                      : (_hovered == i ? Theme.of(context).cardColor.withOpacity(0.03) : Colors.transparent),
                  borderRadius: BorderRadius.circular(DesignTokens.rMed),
                  boxShadow: _hovered == i ? DesignTokens.hoverShadow : null,
                ),
                transform: Matrix4.translationValues(0, (_hovered == i ? -2 : 0).toDouble(), 0),
                child: Row(
                  children: [
                    Icon(item.icon, size: 22, color: isActive ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium?.color),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.label, style: DesignTokens.body(context).copyWith(fontWeight: isActive ? FontWeight.w600 : null))),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
