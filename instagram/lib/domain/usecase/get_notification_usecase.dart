import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/notification.dart';
import 'package:instagram/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  // Tidak perlu Params class karena cuma butuh String userId
  Stream<Either<Failure, List<NotificationEntity>>> execute(String userId) {
    return repository.getNotifications(userId);
  }
}