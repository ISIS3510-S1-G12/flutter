import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class LocationPermissionService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> requestAndLogPermission() async {
    PermissionStatus status;

    if (Platform.isIOS) {
      // En iOS se debe pedir explícitamente "WhenInUse"
      status = await Permission.locationWhenInUse.request();
    } else {
      // En Android funciona el alias "location"
      status = await Permission.location.request();
    }

    String permissionStatus;
    if (status.isGranted) {
      permissionStatus = 'granted';
    } else if (status.isDenied) {
      permissionStatus = 'denied';
    } else if (status.isPermanentlyDenied) {
      permissionStatus = 'permanently_denied';
    } else if (status.isRestricted) {
      // Solo iOS: control parental u otras restricciones del sistema
      permissionStatus = 'restricted';
    } else {
      permissionStatus = 'unknown';
    }

    // Log en Firebase Analytics
    await _analytics.logEvent(
      name: 'location_permission',
      parameters: {'status': permissionStatus},
    );

    print('Location permission logged: $permissionStatus');
  }

  /// Paso adicional si en algún momento quieres pedir "Always" en iOS.
  Future<void> requestAlwaysPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.locationAlways.request();
      print('Location Always permission: $status');
    }
  }
}
