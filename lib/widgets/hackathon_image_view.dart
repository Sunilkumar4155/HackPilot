import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/hackathon.dart';
import '../utils/hackathon_image_helper.dart';

/// A high-performance, responsive image widget for Hackathon banners and thumbnails.
/// It uses CachedNetworkImage with memory and disk constraints to minimize RAM usage,
/// prevents cumulative layout shift (CLS), and gracefully falls back to local assets
/// if network fails, ensuring no blank containers ever appear.
class HackathonImageView extends StatelessWidget {
  const HackathonImageView({
    super.key,
    required this.event,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showGradientOverlay = false,
  });

  final Hackathon event;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showGradientOverlay;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = HackathonImageHelper.resolveImageUrl(event);
    final localAsset = HackathonImageHelper.getLocalAssetFallback(
      event.title,
      event.description,
    );

    final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.5;
    final targetW = width != null && width!.isFinite
        ? (width! * pixelRatio).round().clamp(80, 1000)
        : 600;
    final targetH = height != null && height!.isFinite
        ? (height! * pixelRatio).round().clamp(60, 700)
        : 400;

    Widget imageContent;

    if (resolvedUrl.isEmpty) {
      imageContent = Image.asset(
        localAsset,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: targetW,
        cacheHeight: targetH,
        errorBuilder: (_, _, _) => _fallbackPlaceholder(),
      );
    } else {
      imageContent = CachedNetworkImage(
        imageUrl: resolvedUrl,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: targetW,
        memCacheHeight: targetH,
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 600,
        fadeInDuration: const Duration(milliseconds: 180),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => _loadingPlaceholder(),
        errorWidget: (context, url, error) => Image.asset(
          localAsset,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: targetW,
          cacheHeight: targetH,
          errorBuilder: (_, _, _) => _fallbackPlaceholder(),
        ),
      );
    }

    Widget result = imageContent;

    if (showGradientOverlay) {
      result = Stack(
        fit: StackFit.expand,
        children: [
          result,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (borderRadius != null) {
      result = ClipRRect(
        borderRadius: borderRadius!,
        child: result,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: result,
    );
  }

  Widget _loadingPlaceholder() => Container(
    width: width,
    height: height,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F151E),
          Color(0xFF16202E),
          Color(0xFF0F151E),
        ],
      ),
    ),
    child: const Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFFF6818),
        ),
      ),
    ),
  );

  Widget _fallbackPlaceholder() => Container(
    width: width,
    height: height,
    color: const Color(0xFF0F172A),
    child: const Center(
      child: Icon(Icons.rocket_launch_rounded, color: Color(0xFFFF6818), size: 28),
    ),
  );
}
