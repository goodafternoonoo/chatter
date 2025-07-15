import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    // Windows 초기화 설정
    const WindowsInitializationSettings initializationSettingsWindows = WindowsInitializationSettings(
      appName: 'My Chat App',
      appUserModelId: 'com.example.mychatapp',
      guid: '12345678-1234-5678-1234-567812345678', // 실제 배포 시에는 고유한 GUID로 변경 필요
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      windows: initializationSettingsWindows,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      windows: WindowsNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }
}
