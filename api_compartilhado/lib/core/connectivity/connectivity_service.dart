// lib/core/connectivity/connectivity_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Detecta e expõe o estado de conectividade da rede.
/// Inicializar no main() antes do runApp():
///
///   await ConnectivityService.instance.init();
///
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  StreamSubscription? _subscription;

  // ── Getters públicos ──────────────────────────────────────────────

  /// Estado actual — síncrono, disponível imediatamente.
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// Stream para reagir a mudanças de conectividade.
  Stream<bool> get isOnlineStream => _controller.stream;

  // ── Inicialização ─────────────────────────────────────────────────

  Future<void> init() async {
    // Estado inicial
    final results = await _connectivity.checkConnectivity();
    _isOnline = _avaliar(results);

    // Subscrever a mudanças futuras
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _avaliar(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
        debugPrint(
          _isOnline
              ? '🟢 ConnectivityService — online'
              : '🔴 ConnectivityService — offline',
        );
      }
    });

    debugPrint(
      '📡 ConnectivityService iniciado — ${_isOnline ? "online" : "offline"}',
    );
  }

  // ── Helper — interpreta lista de resultados ───────────────────────

  bool _avaliar(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi   ||
        r == ConnectivityResult.ethernet);
  }

  // ── Limpeza ───────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}