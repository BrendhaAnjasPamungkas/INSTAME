import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/repositories/auth_repository.dart';

// Asumsi Anda punya base class

// Kita buat class Params agar rapi
class SignUpParams {
  final String username;
  final String fullName;
  final String email;
  final String password;
  SignUpParams({required this.username,
    required this.fullName,required this.email, required this.password});
}

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    return await repository.signUp(params.username,params.fullName,params.email, params.password);
  }
}