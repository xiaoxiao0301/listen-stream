import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../shared/widgets/cover_image.dart';

/// 歌曲详情页 - 提供播放和收藏功能
class SongDetailPage extends ConsumerWidget {
  const SongDetailPage({super.key, required this.songMid});

  final String songMid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: 实现歌曲详情数据加载
    final coverUrl =
        'https://y.gtimg.cn/music/photo_new/T002R300x300M000$songMid.jpg';

    return Scaffold(
      appBar: AppBar(
        title: const Text('歌曲详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveBuilderWithInfo(
        builder: (context, deviceType, constraints) {
          final isMobile = deviceType == DeviceType.mobile ||
              deviceType == DeviceType.tablet;

          // 根据设备类型调整封面大小
          final coverSize = responsiveValue(
            context: context,
            mobile: 250.0,
            tablet: 300.0,
            desktop: 400.0,
            tv: 500.0,
          );

          // 根据设备类型调整按钮尺寸
          final buttonMinWidth = responsiveValue(
            context: context,
            mobile: 120.0,
            tablet: 140.0,
            desktop: 160.0,
            tv: 180.0,
          );

          final buttonHeight = ResponsiveSize.buttonHeight(context);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: ResponsiveSpacing.pagePadding(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),

                    // 专辑封面
                    CoverImage(
                      imageUrl: coverUrl,
                      width: coverSize,
                      height: coverSize,
                      borderRadius: 16,
                    ),

                    SizedBox(height: isMobile ? 32 : 48),

                    // 歌曲信息 - TODO: 从API获取
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            '歌曲名称',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontSize: isMobile ? 24 : 32,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '歌手名称',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 48 : 64),

                    // 操作按钮
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        // 收藏按钮
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: 实现收藏功能
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('收藏功能开发中')),
                            );
                          },
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('收藏'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(buttonMinWidth, buttonHeight),
                          ),
                        ),

                        // 播放按钮
                        FilledButton.icon(
                          onPressed: () {
                            // TODO: 实现播放功能
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('播放功能开发中')),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('播放'),
                          style: FilledButton.styleFrom(
                            minimumSize: Size(buttonMinWidth, buttonHeight),
                          ),
                        ),

                        // 添加到歌单按钮
                        if (!isMobile)
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: 实现添加到歌单功能
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('添加到歌单功能开发中')),
                              );
                            },
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('添加到歌单'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(buttonMinWidth, buttonHeight),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
