// lib/core/usecase/usecase.dart

import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:equatable/equatable.dart'; // Impor Equatable jika Anda menggunakannya untuk NoParams

// Kelas dasar untuk semua Use Case
// 'Type' adalah tipe data sukses (generic)
// 'Params' adalah parameter (generic)
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Ini dipakai jika use case tidak butuh parameter
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}