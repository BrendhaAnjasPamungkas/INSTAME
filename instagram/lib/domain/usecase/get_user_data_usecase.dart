import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/repositories/auth_repository.dart';

// Params akan berisi 'uid' dari user yang ingin kita lihat
class GetUserDataParams {
  final String uid;
  GetUserDataParams(this.uid);
}

class GetUserDataUseCase implements UseCase<UserEntity, GetUserDataParams> {
  final AuthRepository repository;

  GetUserDataUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(GetUserDataParams params) async {
    return await repository.getUserData(params.uid);
  }
}