import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:instagram/presentation/widgets/post_card.dart'; // Import PostCard
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart'; // Wajib Install

class PostDetailPage extends StatelessWidget {
  final List<Post> posts;
  final int initialIndex;

  // Controller untuk scroll ke posisi awal
  final ItemScrollController itemScrollController = ItemScrollController();

  PostDetailPage({
    Key? key, 
    required this.posts, 
    required this.initialIndex
  }) : super(key: key) {
    // Scroll otomatis ke index yang diklik setelah halaman dibuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemScrollController.isAttached) {
        itemScrollController.jumpTo(index: initialIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: W.text(data: "Postingan")),
      body: ScrollablePositionedList.builder(
        itemScrollController: itemScrollController,
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: posts[index]);
        },
      ),
    );
  }
}