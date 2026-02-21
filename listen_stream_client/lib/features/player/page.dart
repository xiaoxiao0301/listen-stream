import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/responsive/responsive.dart';
import '../../core/player/playback_service.dart';
import '../../shared/widgets/cover_image.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(playbackServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: 显示更多选项
            },
          ),
        ],
      ),
      body: ResponsiveBuilderWithInfo(
        builder: (context, deviceType, constraints) {
          final isMobile = deviceType == DeviceType.mobile ||
              deviceType == DeviceType.tablet;

          return StreamBuilder<PlaybackEvent>(
            stream: svc.handler.player.playbackEventStream,
            builder: (context, snap) {
              final item = svc.handler.mediaItem.value;
              final playing = svc.handler.player.playing;
              final position = svc.handler.player.position;
              final duration = svc.handler.player.duration ?? Duration.zero;

              // 响应式封面大小
              final coverSize = responsiveValue(
                context: context,
                mobile: 280.0,
                tablet: 320.0,
                desktop: 400.0,
                tv: 500.0,
              );

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: ResponsiveSpacing.pagePadding(context),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isMobile ? 20 : 40),

                        // Cover art
                        if (item?.artUri != null)
                          CoverImage(
                            imageUrl: item!.artUri.toString(),
                            width: coverSize,
                            height: coverSize,
                            borderRadius: 12,
                          )
                        else
                          Container(
                            width: coverSize,
                            height: coverSize,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.music_note,
                              size: coverSize * 0.4,
                              color: Colors.white54,
                            ),
                          ),

                        SizedBox(height: isMobile ? 32 : 48),

                        // Song info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                item?.title ?? '未在播放',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 22 : 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item?.artist ?? '',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: isMobile ? 15 : 18,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isMobile ? 32 : 48),

                        // Progress slider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: isMobile ? 2 : 3,
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: isMobile ? 6 : 8,
                                  ),
                                ),
                                child: Slider(
                                  value: position.inSeconds
                                      .toDouble()
                                      .clamp(0, duration.inSeconds.toDouble()),
                                  max: duration.inSeconds
                                      .toDouble()
                                      .clamp(1, double.infinity),
                                  onChanged: (v) => svc.handler.player
                                      .seek(Duration(seconds: v.toInt())),
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white30,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isMobile ? 24 : 32),

                        // Control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 循环模式
                            if (!isMobile)
                              IconButton(
                                icon: const Icon(
                                  Icons.repeat,
                                  color: Colors.white54,
                                  size: 28,
                                ),
                                onPressed: () {
                                  // TODO: 切换循环模式
                                },
                              ),

                            if (!isMobile) const SizedBox(width: 16),

                            // 上一曲
                            IconButton(
                              icon: Icon(
                                Icons.skip_previous,
                                color: Colors.white,
                                size: isMobile ? 36 : 44,
                              ),
                              onPressed: svc.playPrevious,
                            ),

                            const SizedBox(width: 24),

                            // 播放/暂停
                            IconButton(
                              icon: Icon(
                                playing
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                                size: isMobile ? 64 : 80,
                              ),
                              onPressed: () => playing
                                  ? svc.handler.pause()
                                  : svc.handler.play(),
                            ),

                            const SizedBox(width: 24),

                            // 下一曲
                            IconButton(
                              icon: Icon(
                                Icons.skip_next,
                                color: Colors.white,
                                size: isMobile ? 36 : 44,
                              ),
                              onPressed: svc.playNext,
                            ),

                            if (!isMobile) const SizedBox(width: 16),

                            // 随机播放
                            if (!isMobile)
                              IconButton(
                                icon: const Icon(
                                  Icons.shuffle,
                                  color: Colors.white54,
                                  size: 28,
                                ),
                                onPressed: () {
                                  // TODO: 切换随机播放
                                },
                              ),
                          ],
                        ),

                        SizedBox(height: isMobile ? 32 : 48),

                        // Additional controls (desktop only)
                        if (!isMobile)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    // TODO: 收藏
                                  },
                                  icon: const Icon(
                                    Icons.favorite_border,
                                    color: Colors.white54,
                                  ),
                                  label: const Text(
                                    '收藏',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    // TODO: 评论
                                  },
                                  icon: const Icon(
                                    Icons.comment_outlined,
                                    color: Colors.white54,
                                  ),
                                  label: const Text(
                                    '评论',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    // TODO: 分享
                                  },
                                  icon: const Icon(
                                    Icons.share_outlined,
                                    color: Colors.white54,
                                  ),
                                  label: const Text(
                                    '分享',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
