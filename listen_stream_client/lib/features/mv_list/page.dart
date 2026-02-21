import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../shared/widgets/cover_image.dart';
import '../../shared/widgets/empty_state.dart';
import 'provider.dart';

class MvListPage extends ConsumerStatefulWidget {
  const MvListPage({super.key});

  @override
  ConsumerState<MvListPage> createState() => _MvListPageState();
}

class _MvListPageState extends ConsumerState<MvListPage> {
  int _selectedArea = 15; // 默认全部
  int _selectedVersion = 7; // 默认全部

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(mvCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MV'),
      ),
      body: categoriesAsync.when(
        data: (categoryData) {
          final data = categoryData['data'] as Map<String, dynamic>;
          final areas = (data['area'] as List).cast<Map<String, dynamic>>();
          final versions = (data['version'] as List).cast<Map<String, dynamic>>();

          return ResponsiveBuilderWithInfo(
            builder: (context, deviceType, constraints) {
              final isMobile = deviceType == DeviceType.mobile;

              return Column(
                children: [
                  // 筛选条件
                  Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: ResponsiveSpacing.pagePadding(context).copyWith(
                      top: isMobile ? 8 : 12,
                      bottom: isMobile ? 8 : 12,
                    ),
                    child: AdaptiveContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterRow('地区', areas, _selectedArea, (id) {
                            setState(() => _selectedArea = id);
                          }, isMobile),
                          if (!isMobile) const SizedBox(height: 12),
                          _buildFilterRow('类型', versions, _selectedVersion, (id) {
                            setState(() => _selectedVersion = id);
                          }, isMobile),
                        ],
                      ),
                    ),
                  ),

                  // MV列表
                  Expanded(
                    child: _MvListView(
                      area: _selectedArea,
                      version: _selectedVersion,
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => NetworkErrorState(
          message: '加载失败',
          onRetry: () => ref.invalidate(mvCategoriesProvider),
        ),
      ),
    );
  }

  Widget _buildFilterRow(
    String label,
    List<Map<String, dynamic>> items,
    int selectedId,
    ValueChanged<int> onChanged,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: isMobile ? 0 : 8, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Wrap(
          spacing: isMobile ? 8 : 12,
          runSpacing: isMobile ? 8 : 10,
          children: items.map((item) {
            final id = item['id'] as int;
            final name = item['name'] as String;
            final isSelected = id == selectedId;

            return FilterChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (_) => onChanged(id),
              labelStyle: TextStyle(
                fontSize: isMobile ? 13 : 14,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 0 : 2,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MvListView extends ConsumerWidget {
  const _MvListView({
    required this.area,
    required this.version,
  });

  final int area;
  final int version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mvListAsync = ref.watch(
      mvListProvider({
        'area': area,
        'version': version,
        'page': 1,
        'size': 40,
      }),
    );

    return mvListAsync.when(
      data: (response) {
        final data = response['data'] as Map<String, dynamic>;
        final mvList = (data['list'] as List).cast<Map<String, dynamic>>();

        if (mvList.isEmpty) {
          return const EmptyState(
            icon: Icons.video_library_outlined,
            message: '暂无MV',
          );
        }

        return ResponsiveBuilderWithInfo(
          builder: (context, deviceType, constraints) {
            final isMobile = deviceType == DeviceType.mobile;
            final crossAxisCount = ResponsiveGrid.mvColumns(context);
            final spacing = isMobile ? 12.0 : 16.0;

            return AdaptiveContainer(
              child: GridView.builder(
                padding: ResponsiveSpacing.pagePadding(context),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: 16 / 12,
                ),
                itemCount: mvList.length,
                itemBuilder: (context, index) {
                  final mv = mvList[index];
                  final mvid = mv['mvid'] as int;
                  final title = mv['title'] as String;
                  final vid = mv['vid'] as String;
                  final picurl = mv['picurl'] as String;
                  final playcnt = mv['playcnt'] as int;
                  final duration = mv['duration'] as int;
                  final singers = (mv['singers'] as List).cast<Map<String, dynamic>>();

                  final singerNames = singers
                      .map((s) => s['name'] as String)
                      .join('、');

                  return InkWell(
                    onTap: () {
                      // TODO: 跳转到MV详情页
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('播放 MV: $title')),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              CoverImage(
                                imageUrl: picurl,
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 8,
                              ),
                              // 播放次数
                              Positioned(
                                right: 8,
                                bottom: 8,
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
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _formatPlayCount(playcnt),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // 时长
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: isMobile ? 14 : 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (singerNames.isNotEmpty)
                          Text(
                            singerNames,
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
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => NetworkErrorState(
        message: '加载失败',
        onRetry: () => ref.invalidate(mvListProvider({
              'area': area,
              'version': version,
              'page': 1,
              'size': 40,
            })),
      ),
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
