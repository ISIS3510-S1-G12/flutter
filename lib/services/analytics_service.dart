import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService with WidgetsBindingObserver {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  DateTime? _startTime;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalytics get analytics => _analytics;

  /// Inicializa el observador de ciclo de vida
Future<void> init() async {
  WidgetsBinding.instance.addObserver(this);
  _startTime = DateTime.now();
  await _analytics.logEvent(name: 'app_started');
}


  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _logSessionDuration();
    }
    if (state == AppLifecycleState.resumed) {
      _startTime = DateTime.now(); // reinicia conteo al volver
    }
  }

  Future<void> _logSessionDuration() async {
    if (_startTime == null) return;
    final duration = DateTime.now().difference(_startTime!).inSeconds;

    await _analytics.logEvent(
      name: "session_duration",
      parameters: {
        "duration_seconds": duration,
      },
    );

    print("Sesión registrada: $duration segundos");
  }
 /// 🔹 NUEVO: registrar uso de funcionalidades
  Future<void> logFeatureUsed(String featureName) async {
    await _analytics.logEvent(
      name: "feature_used",
      parameters: {"feature_name": featureName},
    );
    print("Funcionalidad usada: $featureName");
  }

  /// 🔹 (Opcional) registrar vistas de pantalla
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
    print("Vista registrada: $screenName");
  }
}
