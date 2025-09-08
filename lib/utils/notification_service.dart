import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 로컬 알림을 관리하는 서비스 클래스입니다.
///
/// 이 앱에서는 Windows 플랫폼에 대한 알림을 처리합니다.
class NotificationService {
  /// `flutter_local_notifications` 플러그인의 싱글톤 인스턴스입니다.
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 알림 서비스를 초기화합니다.
  ///
  /// 앱 시작 시 `main` 함수에서 호출되어야 합니다.
  /// 현재는 Windows 플랫폼에 대한 초기화 설정만 포함되어 있습니다.
  static Future<void> initializeNotifications() async {
    // Windows 초기화 설정
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: 'My Chat App',
      appUserModelId: 'com.example.mychatapp',
      guid: '12345678-1234-5678-1234-567812345678', // 실제 배포 시에는 고유한 GUID로 변경 필요
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      windows: initializationSettingsWindows,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// 사용자에게 로컬 알림을 표시합니다.
  ///
  /// [notificationId] 알림을 식별하는 고유 ID입니다. 동일한 ID로 다시 호출하면 이전 알림이 업데이트됩니다.
  /// [title] 알림의 제목입니다.
  /// [body] 알림의 내용입니다.
  static Future<void> showNotification({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      windows: WindowsNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x', // 페이로드는 현재 사용되지 않음
    );
  }
}
