import 'package:flutter/material.dart';
import '../../core/responsive/responsive.dart';

/// 封面图片组件 - 统一处理图片加载、错误、占位符
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.fit = BoxFit.cover,
    this.placeholderColor = const Color(0xFFe0e0e0),
    this.shape = BoxShape.rectangle,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final Color placeholderColor;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    // Ensure imageUrl is not empty
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: placeholderColor,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(borderRadius)
              : null,
        ),
        child: Icon(
          Icons.music_note,
          size: (width ?? 48) * 0.4,
          color: Colors.grey[400],
        ),
      );
    }
    
    Widget image = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: placeholderColor,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(borderRadius)
              : null,
        ),
        child: Icon(
          Icons.music_note,
          size: (width ?? 48) * 0.4,
          color: Colors.grey[400],
        ),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: placeholderColor,
            shape: shape,
            borderRadius: shape == BoxShape.rectangle
                ? BorderRadius.circular(borderRadius)
                : null,
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );

    // 根据形状决定是否使用 ClipRRect
    if (shape == BoxShape.rectangle && borderRadius > 0) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    } else if (shape == BoxShape.circle) {
      image = ClipOval(child: image);
    }

    return image;
  }
}

/// 响应式封面图片 - 根据设备类型自动调整大小
class ResponsiveCoverImage extends StatelessWidget {
  const ResponsiveCoverImage({
    super.key,
    required this.imageUrl,
    this.mobileSize = 56.0,
    this.tabletSize = 64.0,
    this.desktopSize = 72.0,
    this.tvSize = 88.0,
    this.borderRadius = 8.0,
    this.fit = BoxFit.cover,
    this.shape = BoxShape.rectangle,
  });

  final String imageUrl;
  final double mobileSize;
  final double tabletSize;
  final double desktopSize;
  final double tvSize;
  final double borderRadius;
  final BoxFit fit;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final size = responsiveValue(
      context: context,
      mobile: mobileSize,
      tablet: tabletSize,
      desktop: desktopSize,
      tv: tvSize,
    );

    return CoverImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: borderRadius,
      fit: fit,
      shape: shape,
    );
  }
}

/// 圆形头像组件
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.imageUrl,
    this.size = 48.0,
  });

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CoverImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      shape: BoxShape.circle,
    );
  }
}
