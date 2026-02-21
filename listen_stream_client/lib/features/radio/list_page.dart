import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../shared/widgets/cover_image.dart';
import '../../shared/widgets/empty_state.dart';
import 'provider.dart';

class RadioListPage extends ConsumerWidget {
  const RadioListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioListAsync = ref.watch(radioListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('电台'),
      ),
      body: radioListAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const EmptyState(
              icon: Icons.radio,
              message: '暂无电台',
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
                            group.title,
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
                            childAspectRatio: 0.85,
                          ),
                          itemCount: group.radios.length,
                          itemBuilder: (context, index) {
                            final radio = group.radios[index];
                            return InkWell(
                              onTap: () {
                                context.push('/radio/${radio.id}');
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: CoverImage(
                                      imageUrl: radio.picUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      borderRadius: 8,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 6 : 8),
                                  Text(
                                    radio.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: isMobile ? 14 : 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (radio.listenNum > 0)
                                    Text(
                                      '${radio.listenNumText} 收听',
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
          onRetry: () => ref.invalidate(radioListProvider),
        ),
      ),
    );
  }
}
