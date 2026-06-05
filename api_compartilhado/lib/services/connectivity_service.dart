// lib/core/connectivity/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller   = StreamController<bool>.broadcast();

  bool _isOnline = false;

  // Nomes consistentes usados em TODA a app
  bool               get isOnline       => _isOnline;
  bool               get isOffline      => !_isOnline;
  Stream<bool>       get isOnlineStream => _controller.stream;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _resolve(result);

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = _resolve(results);
      if (online == _isOnline) return;
      _isOnline = online;
      _controller.add(online);
    });
  }

  bool _resolve(List<ConnectivityResult> r) => r.any((e) =>
      e == ConnectivityResult.wifi ||
      e == ConnectivityResult.mobile ||
      e == ConnectivityResult.ethernet);

  Future<bool> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _resolve(result);
    _controller.add(_isOnline);
    return _isOnline;
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}