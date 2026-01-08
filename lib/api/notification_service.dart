import '../models/notificationmodel.dart';

class NotificationService {
  // Mock data representing what your API will eventually return
  static List<NotificationModel> mockNotifications = [
    NotificationModel(
      id: '1',
      title: 'New Update',
      message: 'Version 2.0 is now live!',
      createdAt: DateTime.now(),
    ),
    NotificationModel(
      id: '2',
      title: 'Welcome!',
      message: 'Thanks for joining our platform.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  static Future<List<NotificationModel>> fetchNotifications() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return mockNotifications;
  }
}