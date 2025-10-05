import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService with WidgetsBindingObserver {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  DateTime? _startTime;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now(); 
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
      _startTime = DateTime.now(); 
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

  }
}
