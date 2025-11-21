import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  const UserAvatar({
    Key? key,
    required this.profileImageUrl,
    this.radius = 18, // Default radius
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.grey[800];
    final icColor = iconColor ?? Colors.grey[600];

    // 1. CEK DATA KOSONG
    if (profileImageUrl == null || profileImageUrl!.trim().isEmpty) {
      return _buildPlaceholder(bgColor!, icColor!);
    }

    // 2. PAKSA HTTPS
    String secureUrl = profileImageUrl!;
    if (secureUrl.startsWith('http://')) {
      secureUrl = secureUrl.replaceFirst('http://', 'https://');
    }

    // 3. TAMPILKAN GAMBAR DENGAN ERROR HANDLING
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: secureUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Kunci ini memaksa refresh jika URL berubah
          key: ValueKey(secureUrl), 
          
          // Tampilan saat loading
          placeholder: (context, url) => Container(color: bgColor),
          
          // JIKA ERROR (Misal 404 atau link mati), kembali ke placeholder
          errorWidget: (context, url, error) => Icon(Icons.person, size: radius, color: icColor),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color bgColor, Color icColor) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(
        Icons.person,
        size: radius, // Ukuran icon setengah dari diameter
        color: icColor,
      ),
    );
  }
}