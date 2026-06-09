// lib/core/connectivity/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart'; // ajusta o import ao teu caminho

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller   = StreamController<bool>.broadcast();

  bool _isOnline        = false; // rede E backend disponíveis
  bool _redeDisponivel  = false; // só rede
  bool _backendDisponivel = false; // só backend

  bool         get isOnline       => _isOnline;
  bool         get isOffline      => !_isOnline;
  Stream<bool> get isOnlineStream => _controller.stream;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _backendPollTimer;

  // ── Inicialização ──────────────────────────────────────────────────

  Future<void> init() async {
    // 1. Verifica rede imediatamente
    final result = await _connectivity.checkConnectivity();
    _redeDisponivel = _resolve(result);

    // 2. Verifica backend imediatamente (não bloqueia o init)
    if (_redeDisponivel) {
      _backendDisponivel = await _pingBackend();
    }
    _atualizar();

    // 3. Escuta mudanças de rede
    _sub = _connectivity.onConnectivityChanged.listen((results) async {
      final rede = _resolve(results);
      _redeDisponivel = rede;

      if (rede) {
        // Rede voltou — verifica backend imediatamente
        _backendDisponivel = await _pingBackend();
      } else {
        _backendDisponivel = false;
      }
      _atualizar();
    });

    // 4. Poll periódico ao backend (detecta quando Spring Boot fica disponível
    //    sem que a rede tenha mudado — ex: iniciou offline, backend sobe depois)
    _backendPollTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!_redeDisponivel) return; // sem rede, não tenta
      final backendAntes = _backendDisponivel;
      _backendDisponivel = await _pingBackend();
      if (_backendDisponivel != backendAntes) {
        _atualizar(); // só notifica se mudou
      }
    });
  }

  // ── Ping ao backend ────────────────────────────────────────────────

  Future<bool> _pingBackend() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/wake-up'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Atualiza estado e notifica se mudou ────────────────────────────

  void _atualizar() {
    final novoEstado = _redeDisponivel && _backendDisponivel;
    if (novoEstado == _isOnline) return;
    _isOnline = novoEstado;
    debugPrint('🌐 ConnectivityService: ${_isOnline ? "ONLINE" : "OFFLINE"} '
        '(rede: $_redeDisponivel, backend: $_backendDisponivel)');
    _controller.add(_isOnline);
  }

  // ── Verificação manual (ex: botão retry) ──────────────────────────

  Future<bool> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    _redeDisponivel = _resolve(result);
    if (_redeDisponivel) {
      _backendDisponivel = await _pingBackend();
    } else {
      _backendDisponivel = false;
    }
    _atualizar();
    return _isOnline;
  }

  // ── Helpers ────────────────────────────────────────────────────────

  bool _resolve(List<ConnectivityResult> r) => r.any((e) =>
      e == ConnectivityResult.wifi ||
      e == ConnectivityResult.mobile ||
      e == ConnectivityResult.ethernet);

  void dispose() {
    _sub?.cancel();
    _backendPollTimer?.cancel();
    _controller.close();
  }
}