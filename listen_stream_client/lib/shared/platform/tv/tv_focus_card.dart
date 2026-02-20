import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TV navigable card: scale + glow on focus, activates on Select/Enter (C.8).
class TvFocusCard extends StatefulWidget {
  const TvFocusCard({
    super.key,
    required this.child,
    required this.onSelect,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback onSelect;
  final FocusNode? focusNode;

  @override
  State<TvFocusCard> createState() => _TvFocusCardState();
}

class _TvFocusCardState extends State<TvFocusCard> {
  bool _focused = false;
  late final FocusNode _node;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(() => setState(() => _focused = _node.hasFocus));
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _focused ? 1.1 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: _focused
                  ? [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 16, spreadRadius: 2)]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
