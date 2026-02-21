import 'package:flutter/material.dart';

/// 卡片项组件 - 用于展示歌单、歌曲、专辑等
class CardItem extends StatelessWidget {
  const CardItem({
    super.key,
    required this.coverUrl,
    required this.title,
    this.subtitle,
    this.onTap,
    this.width = 100,
    this.imageSize = 96,
  });

  final String coverUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double width;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                coverUrl,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: const ColoredBox(color: Color(0xFFe0e0e0)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
