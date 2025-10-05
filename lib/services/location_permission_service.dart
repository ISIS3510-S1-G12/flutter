import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class LocationPermissionService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> requestAndLogPermission() async {
    final status = await Permission.location.request();

    String permissionStatus;
    if (status.isGranted) {
      permissionStatus = 'granted';
    } else if (status.isDenied) {
      permissionStatus = 'denied';
    } else if (status.isPermanentlyDenied) {
      permissionStatus = 'permanently_denied';
    } else {
      permissionStatus = 'unknown';
    }

    await _analytics.logEvent(
      name: 'location_permission_granted',
      parameters: {'status': permissionStatus},
    );
  }
}
