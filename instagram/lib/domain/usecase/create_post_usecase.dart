import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';

// Kita buat class Params agar rapi
class CreatePostParams {
  final Uint8List imageBytes;
  final String caption;
  final String authorId;
  final String authorUsername; // <-- TAMBAHKAN
  final String? authorProfileUrl;
  final PostType type;

  CreatePostParams({
    required this.imageBytes,
    required this.caption,
    required this.authorId,
    required this.authorUsername, // <-- TAMBAHKAN
    this.authorProfileUrl,
    required this.type,
  });
}

class CreatePostUseCase implements UseCase<void, CreatePostParams> {
  final PostRepository repository;

  CreatePostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CreatePostParams params) async {
    return await repository.createPost(
      params.imageBytes,
      params.caption,
      params.authorId,
      params.authorUsername, // <-- TAMBAHKAN
      params.authorProfileUrl,
      params.type,
    );
  }
}
