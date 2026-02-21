import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../shared/widgets/cover_image.dart';
import '../../shared/widgets/empty_state.dart';
import 'provider.dart';

class RankingListPage extends ConsumerWidget {
  const RankingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingListAsync = ref.watch(rankingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
      ),
      body: rankingListAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const EmptyState(
              icon: Icons.trending_up,
              message: '暂无排行榜',
            );
          }

          return ResponsiveBuilderWithInfo(
            builder: (context, deviceType, constraints) {
              final isMobile = deviceType == DeviceType.mobile;
              final crossAxisCount = ResponsiveGrid.playlistColumns(context);
              final spacing = isMobile ? 12.0 : 16.0;

              return AdaptiveContainer(
                child: ListView.builder(
                  padding: ResponsiveSpacing.pagePadding(context),
                  itemCount: groups.length,
                  itemBuilder: (context, groupIndex) {
                    final group = groups[groupIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: groupIndex == 0 ? 0 : 16,
                            bottom: 12,
                          ),
                          child: Text(
                            group.groupName,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: spacing,
                            crossAxisSpacing: spacing,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: group.topList.length,
                          itemBuilder: (context, index) {
                            final category = group.topList[index];
                            return InkWell(
                              onTap: () {
                                context.push('/ranking/${category.topId}');
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: CoverImage(
                                      imageUrl: category.coverUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      borderRadius: 8,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 6 : 8),
                                  Text(
                                    category.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: isMobile ? 14 : 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${category.listenNumText} 播放',
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 13,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => NetworkErrorState(
          message: '加载失败',
          onRetry: () => ref.invalidate(rankingListProvider),
        ),
      ),
    );
  }
}
