import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:instagram/presentation/widgets/main_widget.dart'; // Import W

class StoryRingWidget extends StatelessWidget {
  final String username;
  final String? profileImageUrl;
  final VoidCallback onTap;
  final bool hasUnviewedStories; // (Kita akan pakai ini nanti)

  const StoryRingWidget({
    Key? key,
    required this.username,
    this.profileImageUrl,
    required this.onTap,
    this.hasUnviewedStories = true, // Asumsikan aktif dulu
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Column(
          children: [
            // 1. Lingkaran Gradien (Cincin)
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Jika True (Belum dilihat): Pakai Gradien Warna-warni
                // Jika False (Sudah dilihat): Gradien Null
                gradient: hasUnviewedStories
                    ? LinearGradient(
                        colors: [Color(0xFFFEDA75), Color(0xFFFA7E1E), Color(0xFFD62976), Color(0xFF962FBF), Color(0xFF4F5BD5)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      )
                    : null,
                // Jika False (Sudah dilihat): Pakai Warna Abu-abu
                color: hasUnviewedStories ? null : Colors.grey[600], 
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0), // Jarak antara cincin & foto
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black, // Background foto
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0), // Jarak foto & bg hitam
                    child: ClipOval(
                      child: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: profileImageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: Icon(Icons.person, size: 30, color: Colors.grey[600]),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            W.gap(height: 4),
            // 2. Username
            W.text(
              data: username.length > 9 ? "${username.substring(0, 8)}..." : username,
              fontSize: 12,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}