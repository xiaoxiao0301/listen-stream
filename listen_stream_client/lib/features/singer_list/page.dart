import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../shared/widgets/cover_image.dart';
import '../../shared/widgets/empty_state.dart';
import 'provider.dart';

class SingerListPage extends ConsumerStatefulWidget {
  const SingerListPage({super.key});

  @override
  ConsumerState<SingerListPage> createState() => _SingerListPageState();
}

class _SingerListPageState extends ConsumerState<SingerListPage> {
  int _selectedArea = -100;
  int _selectedGenre = -100;
  int _selectedIndex = -100;
  int _selectedSex = -100;

  @override
  Widget build(BuildContext context) {
    final filterOptionsAsync = ref.watch(singerFilterOptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('歌手'),
      ),
      body: filterOptionsAsync.when(
        data: (filterData) {
          final data = filterData['data'] as Map<String, dynamic>;
          final areas = (data['area'] as List).cast<Map<String, dynamic>>();
          final genres = (data['genre'] as List).cast<Map<String, dynamic>>();
          final indexes = (data['index'] as List).cast<Map<String, dynamic>>();
          final sexes = (data['sex'] as List).cast<Map<String, dynamic>>();

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
                          _buildFilterRow('流派', genres, _selectedGenre, (id) {
                            setState(() => _selectedGenre = id);
                          }, isMobile),
                          if (!isMobile) const SizedBox(height: 12),
                          _buildFilterRow('性别', sexes, _selectedSex, (id) {
                            setState(() => _selectedSex = id);
                          }, isMobile),
                          if (!isMobile) const SizedBox(height: 12),
                          _buildFilterRow('首字母', indexes, _selectedIndex, (id) {
                            setState(() => _selectedIndex = id);
                          }, isMobile),
                        ],
                      ),
                    ),
                  ),

                  // 歌手列表
                  Expanded(
                    child: _SingerListView(
                      area: _selectedArea,
                      genre: _selectedGenre,
                      index: _selectedIndex,
                      sex: _selectedSex,
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
          onRetry: () => ref.invalidate(singerFilterOptionsProvider),
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

class _SingerListView extends ConsumerWidget {
  const _SingerListView({
    required this.area,
    required this.genre,
    required this.index,
    required this.sex,
  });

  final int area;
  final int genre;
  final int index;
  final int sex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final singerListAsync = ref.watch(
      singerListProvider({
        'area': area,
        'genre': genre,
        'index': index,
        'sex': sex,
        'page': 1,
        'size': 80,
      }),
    );

    return singerListAsync.when(
      data: (response) {
        final data = response['data'] as Map<String, dynamic>;
        final singers = (data['singerList'] as List).cast<Map<String, dynamic>>();

        if (singers.isEmpty) {
          return const EmptyState(
            icon: Icons.person_outline,
            message: '暂无歌手',
          );
        }

        return ResponsiveBuilderWithInfo(
          builder: (context, deviceType, constraints) {
            final isMobile = deviceType == DeviceType.mobile;
            final crossAxisCount = ResponsiveGrid.singerColumns(context);
            final spacing = isMobile ? 12.0 : 16.0;

            return AdaptiveContainer(
              child: GridView.builder(
                padding: ResponsiveSpacing.pagePadding(context),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: 0.75,
                ),
                itemCount: singers.length,
                itemBuilder: (context, index) {
                  final singer = singers[index];
                  final singerId = singer['singer_id'] as int;
                  final singerName = singer['singer_name'] as String;
                  final singerMid = singer['singer_mid'] as String;
                  final singerPic = singer['singer_pic'] as String? ?? '';
                  final concernNum = singer['concernNum'] as int? ?? 0;

                  // 构建头像URL
                  String avatarUrl = singerPic;
                  if (avatarUrl.isEmpty && singerMid.isNotEmpty) {
                    avatarUrl =
                        'https://y.gtimg.cn/music/photo_new/T001R150x150M000$singerMid.jpg';
                  }

                  return InkWell(
                    onTap: () {
                      context.push('/singer/$singerMid');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      children: [
                        Expanded(
                          child: AvatarImage(
                            imageUrl: avatarUrl,
                            size: double.infinity,
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 10),
                        Text(
                          singerName,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: isMobile ? 14 : 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        if (concernNum > 0)
                          Text(
                            '${_formatNumber(concernNum)} 关注',
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
        onRetry: () => ref.invalidate(singerListProvider({
              'area': area,
              'genre': genre,
              'index': index,
              'sex': sex,
              'page': 1,
              'size': 80,
            })),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 10000) {
      return '${(num / 10000).toStringAsFixed(1)}万';
    }
    return num.toString();
  }
}
