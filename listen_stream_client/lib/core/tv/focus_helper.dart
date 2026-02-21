import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TV端焦点管理辅助类
/// 用于处理TV端的焦点导航和键盘/遥控器输入
class TvFocusHelper {
  /// 为TV端优化的EdgeInsets
  static EdgeInsets tvPadding({
    double vertical = 40.0,
    double horizontal = 60.0,
  }) {
    return EdgeInsets.symmetric(
      vertical: vertical,
      horizontal: horizontal,
    );
  }

  /// TV端推荐的最小触摸目标尺寸
  static const double minTargetSize = 48.0;

  /// TV端推荐的焦点高亮边框宽度
  static const double focusBorderWidth = 4.0;

  /// TV端推荐的焦点高亮圆角
  static const double focusBorderRadius = 8.0;

  /// 处理TV端方向键导航
  static KeyEventResult handleDirectionalNavigation(
    FocusNode node,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        node.focusInDirection(TraversalDirection.up);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        node.focusInDirection(TraversalDirection.down);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        node.focusInDirection(TraversalDirection.left);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        node.focusInDirection(TraversalDirection.right);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        // 触发选择事件
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }
}

/// TV端焦点高亮装饰
class TvFocusDecoration {
  /// 获取焦点时的装饰
  static BoxDecoration focused({
    Color? color,
    Color? backgroundColor,
    double borderRadius = TvFocusHelper.focusBorderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(
        color: color ?? Colors.white,
        width: TvFocusHelper.focusBorderWidth,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: (color ?? Colors.white).withOpacity(0.5),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// 未获取焦点时的装饰
  static BoxDecoration unfocused({
    Color? backgroundColor,
    double borderRadius = TvFocusHelper.focusBorderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
}

/// TV端可聚焦按钮
class TvFocusableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final EdgeInsets? padding;
  final Color? focusColor;
  final double borderRadius;

  const TvFocusableButton({
    super.key,
    required this.child,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.padding,
    this.focusColor,
    this.borderRadius = TvFocusHelper.focusBorderRadius,
  });

  @override
  State<TvFocusableButton> createState() => _TvFocusableButtonState();
}

class _TvFocusableButtonState extends State<TvFocusableButton> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusColor = widget.focusColor ?? theme.colorScheme.primary;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onPressed?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: _isFocused
              ? TvFocusDecoration.focused(
                  color: focusColor,
                  borderRadius: widget.borderRadius,
                )
              : TvFocusDecoration.unfocused(
                  borderRadius: widget.borderRadius,
                ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: _isFocused ? 18 : 16,
              fontWeight: _isFocused ? FontWeight.w600 : FontWeight.normal,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// TV端可聚焦卡片
class TvFocusableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final double borderRadius;
  final Color? focusColor;

  const TvFocusableCard({
    super.key,
    required this.child,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = 12.0,
    this.focusColor,
  });

  @override
  State<TvFocusableCard> createState() => _TvFocusableCardState();
}

class _TvFocusableCardState extends State<TvFocusableCard> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusColor = widget.focusColor ?? theme.colorScheme.primary;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onPressed?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          decoration: _isFocused
              ? TvFocusDecoration.focused(
                  color: focusColor,
                  borderRadius: widget.borderRadius,
                )
              : TvFocusDecoration.unfocused(
                  borderRadius: widget.borderRadius,
                ),
          transform: _isFocused
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          child: widget.child,
        ),
      ),
    );
  }
}

/// TV端网格焦点导航辅助
class TvGridFocusTraversalPolicy extends FocusTraversalPolicy {
  final int columnCount;

  TvGridFocusTraversalPolicy({required this.columnCount});

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    return descendants;
  }

  @override
  FocusNode? findFirstFocus(FocusNode currentNode) {
    return findFirstFocusInDirection(currentNode, TraversalDirection.down) ??
        currentNode;
  }

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final next = findFirstFocusInDirection(currentNode, direction);
    if (next != null) {
      next.requestFocus();
      return true;
    }
    return false;
  }

  @override
  FocusNode? findFirstFocusInDirection(
    FocusNode currentNode,
    TraversalDirection direction,
  ) {
    return null; // Flutter will use default directional navigation
  }
}
