import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/domain/entities/post.dart'; // Import PostType
import 'package:video_player/video_player.dart';

class UploadPreviewWidget extends StatefulWidget {
  final XFile file;
  final PostType type;

  const UploadPreviewWidget({Key? key, required this.file, required this.type}) : super(key: key);

  @override
  _UploadPreviewWidgetState createState() => _UploadPreviewWidgetState();
}

class _UploadPreviewWidgetState extends State<UploadPreviewWidget> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.type == PostType.video) {
      // XFile.path di Web adalah Blob URL (network)
      // Di Mobile adalah File Path
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.file.path))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.setLooping(true);
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == PostType.video) {
      return _videoController != null && _videoController!.value.isInitialized
          ? AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          : Center(child: CircularProgressIndicator());
    } else {
      // Tampilkan Gambar (Support Web & Mobile)
      return Image.network(
        widget.file.path,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
  }
}