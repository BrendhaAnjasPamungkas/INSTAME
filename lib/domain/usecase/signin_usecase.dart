import 'package:dartz/dartz.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/auth_repository.dart';
 // Kita pakai ulang SignUpParams
 class SignInParams {
  final String email;
  final String password;
  SignInParams({required this.email, required this.password});
}

class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;

  SignInUseCase(this.repository);

@override
  // 'params' sekarang adalah SignInParams
  Future<Either<Failure, UserEntity>> call(SignInParams params) async { 
    return await repository.signIn(params.email, params.password);
  }
}