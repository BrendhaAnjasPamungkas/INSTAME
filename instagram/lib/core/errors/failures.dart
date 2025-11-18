import 'package:equatable/equatable.dart'; // Tambahkan equatable: ^2.0.5 di pubspec.yaml

// Ini adalah kelas dasar untuk semua kegagalan
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Kegagalan spesifik
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure(String message) : super(message);
}