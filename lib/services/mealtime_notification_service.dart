import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MealtimeNotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Configuración Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Inicialización general
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notifications.initialize(initializationSettings);

    // 🔑 Permisos extra (Android 13+ e iOS)
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      print("📱 Android permissions requested");
    } else if (Platform.isIOS) {
      final iosPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
      print("📱 iOS permissions requested");
    }
  }

  /// 📌 Notificación de prueba manual
  Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Canal de prueba de notificaciones locales',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      0,
      '🔔 Test Notificación',
      'Si ves esto, ya funcionan las notificaciones 🎉',
      notificationDetails,
    );
  }

  /// 📌 Notificación según la hora
  Future<void> showMealtimeNotification() async {
    final now = DateTime.now();
    String mealtime;

    if (now.hour >= 6 && now.hour < 11) {
      mealtime = "desayuno 🥐";
    } else if (now.hour >= 11 && now.hour < 16) {
      mealtime = "almuerzo 🍲";
    } else if (now.hour >= 16 && now.hour < 21) {
      mealtime = "cena 🍽️";
    } else {
      mealtime = "un snack 🌙";
    }

    print("⏰ Hora actual: ${now.hour}:${now.minute} → Mealtime: $mealtime");

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'mealtime_channel',
      'Mealtime Notifications',
      channelDescription: 'Ofertas según el momento del día',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,   
        presentSound: true,   
        presentBadge: true,   
      ),
    );

    await _notifications.show(
      1,
      '🍴 Hora de $mealtime',
      'Mira las ofertas disponibles ahora mismo',
      notificationDetails,
    );

    print("✅ Notificación de $mealtime enviada (si tienes permisos)");
  }
}
