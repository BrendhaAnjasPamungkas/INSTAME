import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram/data/datasources/chat_datasource.dart';
import 'package:instagram/data/datasources/notification_datasource.dart';
import 'package:instagram/data/datasources/post_datasource.dart';
import 'package:instagram/data/datasources/story_datasource.dart';
import 'package:instagram/data/repositories/chat_repository_impl.dart';
import 'package:instagram/data/repositories/notification_repository_impl.dart';
import 'package:instagram/data/repositories/pos_repositories_impl.dart';
import 'package:instagram/data/repositories/story_repository_impl.dart';
import 'package:instagram/domain/repositories/chat_repository.dart';
import 'package:instagram/domain/repositories/notification_repository.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';
import 'package:instagram/domain/repositories/story_repository.dart';
import 'package:instagram/domain/usecase/add_comment_usecase.dart';
import 'package:instagram/domain/usecase/create_post_usecase.dart';
import 'package:instagram/domain/usecase/delete_comment_usecase.dart';
import 'package:instagram/domain/usecase/delete_message_usecase.dart';
import 'package:instagram/domain/usecase/delete_post_usecase.dart';
import 'package:instagram/domain/usecase/delete_story_usecase.dart';
import 'package:instagram/domain/usecase/get_chat_rooms_usecase.dart';
import 'package:instagram/domain/usecase/get_comment_usecase.dart';
import 'package:instagram/domain/usecase/get_message_usecase.dart';
import 'package:instagram/domain/usecase/get_notification_usecase.dart';
import 'package:instagram/domain/usecase/get_post_by_id_usecase.dart';
import 'package:instagram/domain/usecase/get_post_usecase.dart';
import 'package:instagram/domain/usecase/get_story_items_usecase.dart';
import 'package:instagram/domain/usecase/get_story_usecase.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/domain/usecase/get_user_post_usecase.dart';
import 'package:instagram/domain/usecase/logout_usecase.dart';
import 'package:instagram/domain/usecase/search_usecase.dart';
import 'package:instagram/domain/usecase/send_email_verification_usecase.dart';
import 'package:instagram/domain/usecase/send_message_usecase.dart';
import 'package:instagram/domain/usecase/send_password_usecase.dart';
import 'package:instagram/domain/usecase/signin_usecase.dart';
import 'package:instagram/domain/usecase/toggle_follow_usecase.dart';
import 'package:instagram/domain/usecase/toggle_like_comment_usecase.dart';
import 'package:instagram/domain/usecase/toggle_like_post_usecase.dart';
import 'package:instagram/domain/usecase/update_user_data_usecase.dart';
import 'package:instagram/domain/usecase/upload_story_usecase.dart';
import 'package:instagram/domain/usecase/view_story_usecase.dart';

import './domain/usecase/get_auth_status_usecase.dart';
import 'package:firebase_storage/firebase_storage.dart';

// --- PERBAIKI IMPORT DI BAWAH INI ---
import 'package:instagram/data/repositories/auth_repository_impl.dart';
import 'package:instagram/data/datasources/auth_datasources.dart'; // Hapus 'features/auth/'
import 'package:instagram/domain/repositories/auth_repository.dart'; // Hapus 'features/auth/'
import 'package:instagram/domain/usecase/signup_usecase.dart';
// Sesuaikan path ini juga

// ... import lainnya

final locator = GetIt.instance;

void init() {
  // === EXTERNAL ===
  locator.registerLazySingleton(() => FirebaseAuth.instance);
  locator.registerLazySingleton(() => FirebaseFirestore.instance);
  locator.registerLazySingleton(() => FirebaseStorage.instance);

  // Domain (Use Cases)
  locator.registerLazySingleton(() => CreatePostUseCase(locator()));
  locator.registerLazySingleton(() => SignUpUseCase(locator()));
  locator.registerLazySingleton(() => GetAuthStatusUsecase(locator()));
  locator.registerLazySingleton(() => SignInUseCase(locator()));
  locator.registerLazySingleton(() => GetPostsUseCase(locator()));

  // Data (Repositories & DataSources)
  locator.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(remoteDataSource: locator()),
  );

  // --- PERBAIKI SINTAKS DI BAWAH INI ---
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: locator(),
      firebaseAuth: locator(), // Panggil constructor & inject dependency
    ),
  );

  locator.registerLazySingleton<AuthRemoteDataSource>(
    () =>
        AuthRemoteDataSourceImpl(firebaseAuth: locator(), firestore: locator()),
  );
  locator.registerLazySingleton(() => LogOutUseCase(locator()));
  locator.registerLazySingleton(() => UpdateUserDataUseCase(locator()));
  locator.registerLazySingleton(() => ToggleLikePostUseCase(locator()));
  locator.registerLazySingleton(() => GetUserDataUseCase(locator()));
  locator.registerLazySingleton(() => GetCommentsUseCase(locator()));
  locator.registerLazySingleton(() => AddCommentUseCase(locator()));
  locator.registerLazySingleton(() => DeletePostUseCase(locator()));
  locator.registerLazySingleton(() => GetUserPostsUseCase(locator()));
  locator.registerLazySingleton(() => SearchUsersUseCase(locator()));
  locator.registerLazySingleton(() => ToggleLikeCommentUseCase(locator()));
  locator.registerLazySingleton(() => ToggleFollowUseCase(locator()));
  locator.registerLazySingleton<PostRemoteDataSource>(
    () => PostRemoteDataSourceImpl(firestore: locator(), cloudinary: locator()),
  );
  locator.registerLazySingleton(
    () => CloudinaryPublic(
      'djmb2pwzp', // <-- Cloud Name Anda (dari screenshot)
      'instagram_clone_unsigned', // <-- API Key yang Anda salin
      cache: false,
    ),
  );
  locator.registerLazySingleton<StoryRemoteDataSource>(
    () =>
        StoryRemoteDataSourceImpl(firestore: locator(), cloudinary: locator()),
  );
  locator.registerLazySingleton<StoryRepository>(
    () => StoryRepositoryImpl(remoteDataSource: locator()),
  );
  locator.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: locator()),
  );
  locator.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(firestore: locator(), cloudinary: locator()),
  );
  locator.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: locator()),
  );
  locator.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(firestore: locator()),
  );

  locator.registerLazySingleton(() => GetStoriesUseCase(locator()));
  locator.registerLazySingleton(() => GetStoryItemsUseCase(locator()));
  locator.registerLazySingleton(() => UploadStoryUseCase(locator()));
  locator.registerLazySingleton(() => DeleteStoryUseCase(locator()));
  locator.registerLazySingleton(() => DeleteCommentUseCase(locator()));
  locator.registerLazySingleton(() => ViewStoryUseCase(locator()));
  locator.registerLazySingleton(() => SendMessageUseCase(locator()));
  locator.registerLazySingleton(() => GetMessagesUseCase(locator()));
  locator.registerLazySingleton(() => GetChatRoomsUseCase(locator()));
  locator.registerLazySingleton(() => DeleteMessageUseCase(locator()));
  locator.registerLazySingleton(() => GetNotificationsUseCase(locator()));
  locator.registerLazySingleton(() => GetPostByIdUseCase(locator()));
  locator.registerLazySingleton(() => SendPasswordResetUseCase(locator()));
  locator.registerLazySingleton(() => SendEmailVerificationUseCase(locator()));
}
