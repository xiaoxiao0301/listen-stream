import 'package:flutter/material.dart';
import '../../core/responsive/responsive.dart';

/// Section 标题组件 - 统一处理区块标题样式
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel = '更多',
    this.padding,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? action;
  final String actionLabel;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final defaultPadding = ResponsiveSpacing.horizontalPadding(context);

    return Padding(
      padding: padding ?? defaultPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: action,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 简单的 Section 标题（无更多按钮）
class SimpleSectionHeader extends StatelessWidget {
  const SimpleSectionHeader({
    super.key,
    required this.title,
    this.padding,
  });

  final String title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: title,
      padding: padding,
    );
  }
}

/// 带计数的 Section 标题
class SectionHeaderWithCount extends StatelessWidget {
  const SectionHeaderWithCount({
    super.key,
    required this.title,
    required this.count,
    this.action,
    this.padding,
  });

  final String title;
  final int count;
  final VoidCallback? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: '$title ($count)',
      action: action,
      padding: padding,
    );
  }
}
