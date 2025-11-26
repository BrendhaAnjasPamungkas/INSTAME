import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/usecase/get_post_by_id_usecase.dart';
import 'package:instagram/domain/usecase/toggle_like_post_usecase.dart';
import 'package:instagram/injection_container.dart';

class PostDetailController extends GetxController {
  final GetPostByIdUseCase getPostByIdUseCase = locator<GetPostByIdUseCase>();
  final ToggleLikePostUseCase toggleLikeUseCase = locator<ToggleLikePostUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();

  final String postId;
  PostDetailController(this.postId);

  var isLoading = true.obs;
  final Rx<Post?> post = Rx(null);

  String get currentUserId => firebaseAuth.currentUser?.uid ?? "";

  @override
  void onInit() {
    super.onInit();
    fetchPost();
  }

  void fetchPost() async {
    isLoading.value = true;
    final result = await getPostByIdUseCase.execute(postId);
    result.fold(
      (failure) => Get.snackbar("Error", failure.message),
      (data) => post.value = data,
    );
    isLoading.value = false;
  }

  void toggleLike() async {
    if (post.value == null) return;
    
    // Optimistic Update (Update UI duluan)
    final currentPost = post.value!;
    final isLiked = currentPost.likes.contains(currentUserId);
    
    List<String> newLikes = List.from(currentPost.likes);
    if (isLiked) {
      newLikes.remove(currentUserId);
    } else {
      newLikes.add(currentUserId);
    }

    post.value = currentPost.copyWith(likes: newLikes);

    // Panggil API
    await toggleLikeUseCase(ToggleLikePostParams(postId: postId, userId: currentUserId));
  }
}