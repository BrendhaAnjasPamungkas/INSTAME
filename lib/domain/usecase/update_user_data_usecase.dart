import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/auth_repository.dart';

class UpdateUserDataParams {
  final String uid;
  final String newUsername;
  final String newBio;
  final String? newProfileImageUrl;

  UpdateUserDataParams({
    required this.uid,
    required this.newUsername,
    required this.newBio,
    required this.newProfileImageUrl
  });
}

class UpdateUserDataUseCase implements UseCase<void, UpdateUserDataParams> {
  final AuthRepository repository;

  UpdateUserDataUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserDataParams params) async {
    return await repository.updateUserData(
      params.uid,
      params.newUsername,
      params.newBio,
      params.newProfileImageUrl
    );
  }
}