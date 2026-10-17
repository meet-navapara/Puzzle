import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_config.dart';

/// Monitors link status and actual internet reachability.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({Connectivity? connectivity, http.Client? client})
    : _connectivity = connectivity ?? Connectivity(),
      _client = client ?? http.Client();

  final Connectivity _connectivity;
  final http.Client _client;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _poll;

  bool _hasLink = true;
  bool _hasInternet = true;
  bool _checking = false;
  String? _lastError;
  int _failStreak = 0;

  /// Consecutive failed reachability checks required before going offline.
  static const int _offlineAfterFails = 2;

  bool get hasLink => _hasLink;
  bool get hasInternet => _hasInternet;
  bool get isOnline => _hasInternet;
  bool get isChecking => _checking;
  String? get lastError => _lastError;

  Future<void> start() async {
    await checkNow();
    _sub = _connectivity.onConnectivityChanged.listen((results) async {
      _hasLink = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
      await checkNow();
    });
    _poll = Timer.periodic(AppConfig.connectivityCheckInterval, (_) {
      checkNow();
    });
  }

  Future<bool> checkNow() async {
    if (_checking) return _hasInternet;
    _checking = true;
    notifyListeners();
    try {
      final results = await _connectivity
          .checkConnectivity()
          .timeout(AppConfig.connectivityTimeout);
      _hasLink = results.any((r) => r != ConnectivityResult.none);
      if (!_hasLink) {
        _failStreak = _offlineAfterFails;
        _hasInternet = false;
        _lastError = 'No network connection';
        return false;
      }
      final uri = Uri.parse(AppConfig.reachabilityUrl);
      final response = await _client
          .get(uri)
          .timeout(AppConfig.connectivityTimeout);
      final ok = response.statusCode >= 200 && response.statusCode < 400;
      if (ok) {
        _failStreak = 0;
        _hasInternet = true;
        _lastError = null;
        return true;
      }
      _failStreak++;
      if (_failStreak >= _offlineAfterFails) {
        _hasInternet = false;
        _lastError = 'No internet access';
      }
      return _hasInternet;
    } catch (e) {
      _failStreak++;
      if (_failStreak >= _offlineAfterFails) {
        _hasInternet = false;
        _lastError = 'Reachability check failed';
      }
      // Grace: keep previous online state until streak threshold.
      return _hasInternet;
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    _client.close();
    super.dispose();
  }
}
