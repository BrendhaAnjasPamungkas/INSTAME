import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/presentation/controllers/feed_controller.dart';
import 'package:instagram/presentation/controllers/story_controller.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:instagram/presentation/widgets/post_card.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PostDetailPage extends StatelessWidget {
  // OPTION A: Scrollable List (From Profile)
  final List<Post>? posts;
  final int initialIndex;

  // OPTION B: Single Post ID (From Notification)
  final String? postId;

  // Dependencies
  final FeedController feedController;
  final StoryController? storyController;
  
  final ItemScrollController itemScrollController = ItemScrollController();

  PostDetailPage({
    Key? key,
    this.posts,               // Optional
    this.initialIndex = 0,    // Default 0
    this.postId,              // Optional
    
    // We can find controllers using Get.find inside if not provided, 
    // but it's better to pass them if possible. 
    // For simplicity in ActivityPage, we will allow them to be null 
    // and find them inside if needed.
    FeedController? feedController,
    this.storyController,
  }) : feedController = feedController ?? Get.find<FeedController>(tag: "feedController"), 
       super(key: key) {
         
    // Scroll logic for Option A
    if (posts != null && posts!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (itemScrollController.isAttached) {
          itemScrollController.jumpTo(index: initialIndex);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: W.text(data: "Postingan")),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 1. MODE SCROLL (FROM PROFILE)
    if (posts != null && posts!.isNotEmpty) {
      return ScrollablePositionedList.builder(
        itemScrollController: itemScrollController,
        itemCount: posts!.length,
        itemBuilder: (context, index) {
          return PostCard(
            post: posts![index],
            controller: feedController,
            storyController: storyController,
          );
        },
      );
    }
    
    // 2. MODE SINGLE (FROM NOTIFICATION)
    else if (postId != null) {
      // Try to find the post in FeedController's existing list
      // This is a quick fix. A better way is to fetch from API if not found.
      try {
        final Post post = feedController.posts.firstWhere(
          (p) => p.id == postId, 
          orElse: () => throw Exception("Post not found in feed"),
        );
        
        return SingleChildScrollView(
          child: PostCard(
            post: post,
            controller: feedController,
            storyController: storyController,
          ),
        );
      } catch (e) {
        // Fallback if post is not loaded in feed
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              W.text(data: "Postingan tidak tersedia di feed saat ini."),
            ],
          ),
        );
      }
    }

    // 3. EMPTY/LOADING
    return Center(child: CircularProgressIndicator());
  }
}