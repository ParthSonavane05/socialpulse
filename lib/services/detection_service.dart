import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native backend bridge via MethodChannel.
class NativeBackend {
  static const _channel = MethodChannel('com.socialpulse/backend');

  static Future<Map<String, dynamic>> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod('checkPermissions');
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return {'usage_stats': false, 'notification_listener': false, 'bluetooth': false};
    }
  }

  static Future<void> openUsageStatsSettings() async {
    try { await _channel.invokeMethod('openUsageStatsSettings'); } catch (_) {}
  }

  static Future<void> openNotificationListenerSettings() async {
    try { await _channel.invokeMethod('openNotificationListenerSettings'); } catch (_) {}
  }

  static Future<Map<String, dynamic>> getUsageStats() async {
    try {
      final result = await _channel.invokeMethod('getUsageStats');
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return {'error': 'platform_error'};
    }
  }

  static Future<Map<String, dynamic>> scanBluetooth() async {
    try {
      final result = await _channel.invokeMethod('scanBluetooth');
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return {'device_count': 0, 'social_context': 'solo'};
    }
  }

  static Future<Map<String, dynamic>> getNotificationLog() async {
    try {
      final result = await _channel.invokeMethod('getNotificationLog');
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return {'recent': [], 'notification_triggered_unlocks': 0};
    }
  }

  static Future<Map<String, dynamic>> detectPhubbing({int? bluetoothCount}) async {
    try {
      final args = bluetoothCount != null ? {'bluetooth_count': bluetoothCount} : null;
      final result = await _channel.invokeMethod('detectPhubbing', args);
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return {'is_phubbing': false, 'severity': 'none'};
    }
  }

  static Future<Map<String, dynamic>> getDailyAnalysis() async {
    try {
      final result = await _channel.invokeMethod('getDailyAnalysis');
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getBaselineStatus() async {
    try {
      final result = await _channel.invokeMethod('getBaselineStatus');
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return {'started': false, 'is_learning': false};
    }
  }

  static Future<Map<String, dynamic>> sendNudge({String type = 'awareness'}) async {
    try {
      final result = await _channel.invokeMethod('sendNudge', {'type': type});
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return {'sent': false};
    }
  }
}

/// Simulated + native detection service for phone usage patterns & social context.
class DetectionService extends ChangeNotifier {
  double _presenceScore = 78.0;
  String _socialContext = 'Neutral';
  int _unlockCount = 12;
  int _checkCount = 8;
  bool _socialAwarenessEnabled = false;
  bool _focusSessionActive = false;
  DateTime? _focusSessionStart;
  final List<NudgeMessage> _nudgeHistory = [];
  List<DailyInsight> _weeklyInsights = [];
  bool _microphoneEnabled = false;

  // Native backend state
  bool _nativeAvailable = false;
  Map<String, dynamic> _permissions = {};
  Map<String, dynamic> _lastDetection = {};

  double get presenceScore => _presenceScore;
  String get socialContext => _socialContext;
  int get unlockCount => _unlockCount;
  int get checkCount => _checkCount;
  bool get socialAwarenessEnabled => _socialAwarenessEnabled;
  bool get focusSessionActive => _focusSessionActive;
  DateTime? get focusSessionStart => _focusSessionStart;
  List<NudgeMessage> get nudgeHistory => _nudgeHistory;
  List<DailyInsight> get weeklyInsights => _weeklyInsights;
  bool get microphoneEnabled => _microphoneEnabled;
  bool get nativeAvailable => _nativeAvailable;
  Map<String, dynamic> get permissions => _permissions;
  Map<String, dynamic> get lastDetection => _lastDetection;

  bool get hasUsageStatsPermission => _permissions['usage_stats'] == true;
  bool get hasNotificationPermission => _permissions['notification_listener'] == true;

  DetectionService() {
    _generateMockInsights();
    _initNative();
  }

  Future<void> _initNative() async {
    try {
      _permissions = await NativeBackend.checkPermissions();
      _nativeAvailable = true;
      await _refreshFromNative();
    } catch (_) {
      _nativeAvailable = false;
    }
    notifyListeners();
  }

  Future<void> refreshPermissions() async {
    _permissions = await NativeBackend.checkPermissions();
    notifyListeners();
  }

  Future<void> _refreshFromNative() async {
    if (!_nativeAvailable) return;
    try {
      if (hasUsageStatsPermission) {
        final stats = await NativeBackend.getUsageStats();
        if (stats['error'] == null) {
          _unlockCount = (stats['unlock_count_24h'] as num?)?.toInt() ?? _unlockCount;
          _checkCount = (stats['unlock_count_1h'] as num?)?.toInt() ?? _checkCount;
        }
      }
      final analysis = await NativeBackend.getDailyAnalysis();
      if (analysis.containsKey('presence_score')) {
        _presenceScore = (analysis['presence_score'] as num).toDouble();
      }
    } catch (_) {}
  }

  void toggleSocialAwareness() {
    _socialAwarenessEnabled = !_socialAwarenessEnabled;
    if (_socialAwarenessEnabled) {
      _socialContext = 'Social Mode Likely';
      _runDetection();
    } else {
      _socialContext = 'Neutral';
    }
    notifyListeners();
  }

  Future<void> _runDetection() async {
    if (_nativeAvailable) {
      // Trigger BT scan + phubbing detection
      final bt = await NativeBackend.scanBluetooth();
      final btCount = (bt['device_count'] as num?)?.toInt() ?? 0;
      _lastDetection = await NativeBackend.detectPhubbing(bluetoothCount: btCount);

      if (btCount >= 3) {
        _socialContext = 'Social Mode Likely';
      }
      await _refreshFromNative();
    } else {
      _simulateDetection();
    }
    notifyListeners();
  }

  void startFocusSession() {
    _focusSessionActive = true;
    _focusSessionStart = DateTime.now();
    notifyListeners();
  }

  void stopFocusSession() {
    _focusSessionActive = false;
    _focusSessionStart = null;
    _presenceScore = min(100, _presenceScore + 5);
    notifyListeners();
  }

  void toggleMicrophone() {
    _microphoneEnabled = !_microphoneEnabled;
    if (_microphoneEnabled) {
      _socialContext = 'Social Mode Likely';
    }
    notifyListeners();
  }

  void dismissNudge() {
    notifyListeners();
  }

  NudgeMessage? getActiveNudge() {
    if (_checkCount > 5 && _socialAwarenessEnabled) {
      return NudgeMessage(
        message: _nudgeMessages[Random().nextInt(_nudgeMessages.length)],
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  void simulatePhoneCheck() {
    _checkCount++;
    _unlockCount++;
    _presenceScore = max(0, _presenceScore - 2);
    if (_checkCount % 3 == 0) {
      _nudgeHistory.insert(0, NudgeMessage(
        message: _nudgeMessages[Random().nextInt(_nudgeMessages.length)],
        timestamp: DateTime.now(),
      ));
      // Also send native nudge
      if (_nativeAvailable) {
        NativeBackend.sendNudge(type: 'awareness');
      }
    }
    notifyListeners();
  }

  void _simulateDetection() {
    final rand = Random();
    _checkCount = 5 + rand.nextInt(10);
    _unlockCount = 8 + rand.nextInt(15);
    _presenceScore = 50 + rand.nextDouble() * 40;
  }

  void _generateMockInsights() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final rand = Random();
    _weeklyInsights = days.map((day) {
      return DailyInsight(
        day: day,
        unlocks: 10 + rand.nextInt(25),
        presenceScore: 50 + rand.nextDouble() * 45,
        socialMinutes: 30 + rand.nextInt(120),
      );
    }).toList();
  }

  Map<int, double> getHeatmapData() {
    final rand = Random(42);
    return { for (int h = 6; h <= 23; h++) h: rand.nextDouble() };
  }

  static const _nudgeMessages = [
    'Stay with the moment.',
    'People around you matter.',
    'Take a mindful pause.',
    'Your presence is a gift.',
    'Look up. Connect.',
    'This moment won\'t come again.',
    'Be here. Fully.',
  ];
}

class NudgeMessage {
  final String message;
  final DateTime timestamp;
  NudgeMessage({required this.message, required this.timestamp});
}

class DailyInsight {
  final String day;
  final int unlocks;
  final double presenceScore;
  final int socialMinutes;
  DailyInsight({
    required this.day,
    required this.unlocks,
    required this.presenceScore,
    required this.socialMinutes,
  });
}
