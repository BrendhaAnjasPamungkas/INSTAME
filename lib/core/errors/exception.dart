// Ini adalah error teknis yang dilempar oleh Data Source
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {
   final String message;
  CacheException(this.message);
}