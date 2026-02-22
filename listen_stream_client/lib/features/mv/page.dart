import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/cover_image.dart';
import 'provider.dart';

class MvDetailPage extends ConsumerWidget {
  const MvDetailPage({super.key, required this.vid});
  final String vid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mvAsync = ref.watch(mvDetailFamily(vid));
    return mvAsync.when(
      loading: () => const Scaffold(body: LoadingShimmer(height: double.infinity)),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('MV详情')),
        body: AppErrorWidget(onRetry: () => ref.invalidate(mvDetailFamily(vid))),
      ),
      data: (data) => _MvDetail(vid: vid, data: data),
    );
  }
}

class _MvDetail extends StatelessWidget {
  const _MvDetail({required this.vid, required this.data});
  final String vid;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final info = (data['info'] as Map<String, dynamic>?) ?? {};
    final name = info['name'] as String? ?? '';
    final coverPic = info['cover_pic'] as String? ?? '';
    final desc = info['desc'] as String? ?? '';
    final playcnt = info['playcnt'] as int? ?? 0;
    final duration = info['duration'] as int? ?? 0;
    final singers = (info['singers'] as List? ?? []).cast<Map<String, dynamic>>();
    
    final singerNames = singers.map((s) => s['name'] as String? ?? '').where((n) => n.isNotEmpty).join(' / ');

    return ResponsiveBuilderWithInfo(
      builder: (context, deviceType, constraints) {
        final isMobile = deviceType == DeviceType.mobile || deviceType == DeviceType.tablet;

        return Scaffold(
          appBar: AppBar(
            title: Text(name),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MV封面/播放器占位
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: coverPic.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CoverImage(
                              imageUrl: coverPic,
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: 0,
                            ),
                            // 播放按钮覆盖层
                            Container(
                              color: Colors.black26,
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: isMobile ? 64 : 96,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: Center(
                            child: Icon(
                              Icons.videocam,
                              size: isMobile ? 64 : 96,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // MV标题
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      // 歌手名称（可点击跳转）
                      if (singerNames.isNotEmpty)
                        InkWell(
                          onTap: () {
                            if (singers.isNotEmpty) {
                              final mid = singers.first['mid'] as String? ?? '';
                              if (mid.isNotEmpty) {
                                context.push('/singer/$mid');
                              }
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                singerNames,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // 播放次数和时长
                      Row(
                        children: [
                          Icon(Icons.play_arrow, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatPlayCount(playcnt),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      // 描述
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          '简介',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          desc,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿次播放';
    } else if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万次播放';
    } else {
      return '$count次播放';
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
