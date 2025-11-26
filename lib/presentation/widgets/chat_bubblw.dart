import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:instagram/domain/entities/message.dart';
import 'package:instagram/presentation/controllers/feed_video_player.dart'; // Pastikan path benar
import 'package:instagram/presentation/widgets/main_widget.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final MessageType type;
  final String? mediaUrl;

  const ChatBubble({
    Key? key,
    required this.text,
    required this.isMe,
    this.type = MessageType.text,
    this.mediaUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        // Padding lebih kecil untuk media agar gambar mentok ke pinggir
        padding: type == MessageType.text
            ? EdgeInsets.symmetric(vertical: 10, horizontal: 14)
            : EdgeInsets.all(4),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.7, // Max 70% lebar layar
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:
              MainAxisSize.min, // Penting agar tidak memanjang ke bawah
          children: [
            // --- 1. JIKA GAMBAR ---
            if (type == MessageType.image &&
                mediaUrl != null &&
                mediaUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 300, // Batas tinggi gambar
                    minHeight: 100,
                    minWidth: 150,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: mediaUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      width: 150,
                      color: Colors.black12,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              ),

            // --- 2. JIKA VIDEO ---
            if (type == MessageType.video &&
                mediaUrl != null &&
                mediaUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 250,
                  width: 200, // Beri lebar pasti juga biar aman
                  // Tambahkan Key unik agar VideoPlayerController tidak bentrok
                  child: FeedVideoPlayer(
                    key: ValueKey(mediaUrl!),
                    url: mediaUrl!,
                  ),
                ),
              ),

            // --- 3. JIKA TEKS (Caption atau Pesan Biasa) ---
            if (text.isNotEmpty) ...[
              if (type != MessageType.text) SizedBox(height: 8),
              Padding(
                padding: type != MessageType.text
                    ? EdgeInsets.symmetric(horizontal: 4)
                    : EdgeInsets.zero,
                child: W.text(data: text, color: Colors.white, fontSize: 15),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
