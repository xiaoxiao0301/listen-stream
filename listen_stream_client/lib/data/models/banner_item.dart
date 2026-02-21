/// 推荐Banner项，只包含显示需要的字段
class BannerItem {
  const BannerItem({
    required this.id,
    required this.picUrl,
    this.type,
    this.h5Url,
  });

  final String id;
  final String picUrl;
  final String? type;
  final String? h5Url;

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id']?.toString() ?? '',
      picUrl: json['picUrl'] as String? ?? '',
      type: json['type']?.toString(),
      h5Url: json['h5Url'] as String?,
    );
  }
}
