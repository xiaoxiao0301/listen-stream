import 'package:flutter/material.dart';
import 'cover_image.dart';

/// 媒体卡片组件 - 统一的卡片样式（专辑、歌单、歌手等）
class MediaCard extends StatefulWidget {
  const MediaCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.onTap,
    this.badge,
    this.playCount,
    this.aspectRatio = 1.0,
    this.borderRadius = 8.0,
    this.imageShape = BoxShape.rectangle,
  });

  final String imageUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? badge;
  final int? playCount;
  final double aspectRatio;
  final double borderRadius;
  final BoxShape imageShape;

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(widget.borderRadius);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: borderRadius,
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: borderRadius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 封面图片
                AspectRatio(
                  aspectRatio: widget.aspectRatio,
                  child: Stack(
                    children: [
                      CoverImage(
                        imageUrl: widget.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: widget.borderRadius,
                        shape: widget.imageShape,
                      ),
                      // 播放次数角标
                      if (widget.playCount != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_arrow,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _formatCount(widget.playCount!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // 自定义角标
                      if (widget.badge != null)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: widget.badge!,
                        ),
                    ],
                  ),
                ),
                // Text area with fixed padding
                Flexible(
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 标题
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      // 副标题
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    } else if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    } else {
      return count.toString();
    }
  }
}

/// 专辑卡片
class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
    this.onTap,
  });

  final String imageUrl;
  final String title;
  final String artist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      imageUrl: imageUrl,
      title: title,
      subtitle: artist,
      onTap: onTap,
    );
  }
}

/// 歌单卡片
class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.creator,
    this.playCount,
    this.onTap,
  });

  final String imageUrl;
  final String title;
  final String? creator;
  final int? playCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      imageUrl: imageUrl,
      title: title,
      subtitle: creator,
      playCount: playCount,
      onTap: onTap,
    );
  }
}

/// 歌手卡片
class ArtistCard extends StatelessWidget {
  const ArtistCard({
    super.key,
    required this.imageUrl,
    required this.name,
    this.description,
    this.onTap,
  });

  final String imageUrl;
  final String name;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      imageUrl: imageUrl,
      title: name,
      subtitle: description,
      onTap: onTap,
      imageShape: BoxShape.circle,
      aspectRatio: 1.0,
    );
  }
}

/// MV 卡片
class MvCard extends StatelessWidget {
  const MvCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
    this.playCount,
    this.onTap,
  });

  final String imageUrl;
  final String title;
  final String artist;
  final int? playCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      imageUrl: imageUrl,
      title: title,
      subtitle: artist,
      playCount: playCount,
      onTap: onTap,
      aspectRatio: 16 / 9,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'MV',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
