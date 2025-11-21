import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UniversalImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isCircle;

  const UniversalImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isCircle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Cek Null atau Kosong
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildError();
    }

    // 2. Paksa HTTPS
    String finalUrl = imageUrl!;
    if (finalUrl.startsWith('http://')) {
      finalUrl = finalUrl.replaceFirst('http://', 'https://');
    }

    // 3. Widget Gambar
    Widget imageWidget = CachedNetworkImage(
      imageUrl: finalUrl,
      width: width,
      height: height,
      fit: fit,
      // Key penting agar gambar berubah saat URL berubah
      key: ValueKey(finalUrl), 
      placeholder: (context, url) => Container(
        width: width, 
        height: height, 
        color: Colors.grey[900],
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
      ),
      errorWidget: (context, url, error) {
        print("IMAGE ERROR ($finalUrl): $error"); // Print error ke console
        return _buildError();
      },
    );

    // 4. Jika butuh Lingkaran (Avatar)
    if (isCircle) {
      return ClipOval(child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: Icon(Icons.person, color: Colors.white54),
    );
  }
}