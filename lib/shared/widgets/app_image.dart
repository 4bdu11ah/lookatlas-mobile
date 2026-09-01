import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

/// One widget for every image source. Pass a string and it figures out the
/// rest:
///
/// ```dart
/// AppImage('https://example.com/a.png')   // cached network raster
/// AppImage('https://example.com/a.svg')   // network SVG
/// AppImage('assets/logo.svg')             // bundled SVG
/// AppImage('assets/photo.jpg')            // bundled raster
/// AppImage('/storage/emo/pic.png')        // file on disk
/// AppImage.memory(bytes)                  // in-memory bytes
/// ```
///
/// SVG vs raster is detected from the `.svg` extension. Network rasters are
/// disk/memory cached and decoded at the displayed size. `file://` sources use
/// `dart:io` and are not supported on web.
class AppImage extends StatelessWidget {
  const AppImage(
    String this.source, {
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.color,
    this.semanticLabel,
    this.placeholder,
    this.errorWidget,
    this.onImageLoaded,
    this.onRemove,
    this.removeTooltip = 'Remove image',
    this.removeIcon = Icons.close,
    super.key,
  }) : bytes = null;

  /// Render raw bytes (e.g. an image picked or downloaded into memory).
  const AppImage.memory(
    Uint8List this.bytes, {
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.color,
    this.semanticLabel,
    this.placeholder,
    this.errorWidget,
    this.onImageLoaded,
    this.onRemove,
    this.removeTooltip = 'Remove image',
    this.removeIcon = Icons.close,
    super.key,
  }) : source = null;

  final String? source;
  final Uint8List? bytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Tint applied via `srcIn` (most useful for monochrome SVGs/icons).
  final Color? color;
  final String? semanticLabel;
  final Widget? placeholder;
  final Widget? errorWidget;
  final VoidCallback? onImageLoaded;
  final VoidCallback? onRemove;
  final String removeTooltip;
  final IconData removeIcon;

  bool get _isSvg {
    final s = source;
    if (s == null) return false;
    final path = Uri.tryParse(s)?.path ?? s;
    return path.toLowerCase().endsWith('.svg');
  }

  bool get _isNetwork {
    final s = source;
    return s != null && (s.startsWith('http://') || s.startsWith('https://'));
  }

  bool get _isAsset => source != null && source!.startsWith('asset');

  ColorFilter? get _colorFilter =>
      color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn);

  @override
  Widget build(BuildContext context) {
    final image = _buildImage(context);
    final clipped = borderRadius == null
        ? image
        : ClipRRect(borderRadius: borderRadius!, child: image);
    if (onRemove == null) return clipped;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        clipped,
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: AppColors.black,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: removeTooltip,
              onPressed: onRemove,
              icon: Icon(removeIcon, color: AppColors.white, size: 18),
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    if (bytes != null) return _memory(context);
    if (_isSvg) return _svg();
    if (_isNetwork) return _networkRaster(context);
    if (_isAsset) return _assetRaster(context);
    return _fileRaster(context);
  }

  /// Physical-pixel decode target for a logical [dimension], so large sources
  /// are rasterized at the displayed size instead of full resolution.
  int? _cacheDimension(BuildContext context, double? dimension) =>
      dimension == null
      ? null
      : (dimension * MediaQuery.devicePixelRatioOf(context)).round();

  // --- SVG (network / asset / file) ---
  Widget _svg() {
    final placeholderBuilder = placeholder == null
        ? null
        : (_) => placeholder!;

    if (_isNetwork) {
      return SvgPicture.network(
        source!,
        width: width,
        height: height,
        fit: fit,
        colorFilter: _colorFilter,
        semanticsLabel: semanticLabel,
        placeholderBuilder: placeholderBuilder,
      );
    }
    if (_isAsset) {
      return SvgPicture.asset(
        source!,
        width: width,
        height: height,
        fit: fit,
        colorFilter: _colorFilter,
        semanticsLabel: semanticLabel,
        placeholderBuilder: placeholderBuilder,
      );
    }
    return SvgPicture.file(
      File(source!),
      width: width,
      height: height,
      fit: fit,
      colorFilter: _colorFilter,
      semanticsLabel: semanticLabel,
      placeholderBuilder: placeholderBuilder,
    );
  }

  // --- Network raster (cached + size-capped) ---
  Widget _networkRaster(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CachedNetworkImage(
      imageUrl: source!,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      memCacheWidth: width == null ? null : (width! * dpr).round(),
      memCacheHeight: height == null ? null : (height! * dpr).round(),
      fadeInDuration: const Duration(milliseconds: 250),
      imageBuilder: onImageLoaded == null
          ? null
          : (context, provider) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => onImageLoaded?.call(),
              );
              return Image(
                image: provider,
                width: width,
                height: height,
                fit: fit,
                color: color,
                colorBlendMode: color == null ? null : BlendMode.srcIn,
              );
            },
      // While the download runs, show the caller's placeholder or a shimmer.
      placeholder: (_, _) => placeholder ?? const ShimmerBox(),
      errorWidget: (_, _, _) => errorWidget ?? _defaultError,
    );
  }

  Widget _assetRaster(BuildContext context) => Image.asset(
    source!,
    width: width,
    height: height,
    fit: fit,
    color: color,
    colorBlendMode: color == null ? null : BlendMode.srcIn,
    cacheWidth: _cacheDimension(context, width),
    cacheHeight: _cacheDimension(context, height),
    semanticLabel: semanticLabel,
    errorBuilder: (_, _, _) => errorWidget ?? _defaultError,
  );

  Widget _fileRaster(BuildContext context) => Image.file(
    File(source!),
    width: width,
    height: height,
    fit: fit,
    color: color,
    colorBlendMode: color == null ? null : BlendMode.srcIn,
    cacheWidth: _cacheDimension(context, width),
    cacheHeight: _cacheDimension(context, height),
    semanticLabel: semanticLabel,
    errorBuilder: (_, _, _) => errorWidget ?? _defaultError,
  );

  Widget _memory(BuildContext context) => Image.memory(
    bytes!,
    width: width,
    height: height,
    fit: fit,
    color: color,
    colorBlendMode: color == null ? null : BlendMode.srcIn,
    cacheWidth: _cacheDimension(context, width),
    cacheHeight: _cacheDimension(context, height),
    semanticLabel: semanticLabel,
    errorBuilder: (_, _, _) => errorWidget ?? _defaultError,
  );

  Widget get _defaultError => const ColoredBox(
    color: AppColors.blackAlpha07,
    child: Center(child: Icon(Icons.broken_image_outlined)),
  );
}
