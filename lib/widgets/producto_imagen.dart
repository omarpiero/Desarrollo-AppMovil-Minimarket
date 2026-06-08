import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';

class ProductoImagen extends StatelessWidget {
  final String imagenUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const ProductoImagen({
    super.key,
    required this.imagenUrl,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.contain,
  });

  bool get _tieneImagen => imagenUrl.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: MinimarketTheme.primaryYellow.withValues(alpha: 0.18),
        ),
      ),
      child: _tieneImagen
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: CachedNetworkImage(
                imageUrl: imagenUrl.trim(),
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                fit: fit,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MinimarketTheme.secondaryNavy,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const _ImagenPlaceholder(),
              ),
            )
          : const _ImagenPlaceholder(),
    );
  }
}

class _ImagenPlaceholder extends StatelessWidget {
  const _ImagenPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_not_supported_rounded,
        color: MinimarketTheme.primaryYellowDark,
        size: 30,
      ),
    );
  }
}
