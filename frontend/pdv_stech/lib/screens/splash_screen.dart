import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:api_compartilhado/api_compartilhado.dart';
// import 'package:http/http.dart' as http;

// ── Paleta STech (idêntica à tela de login) ─────────────────────────
const _navy   = Color(0xFF1B2A6B);
const _navyDk = Color(0xFF111A42);
const _red    = Color(0xFFC8102E);
const _bg     = Color(0xFFF4F5F7);

// ── Timeout do health-check ─────────────────────────────────────────
// const _kHealthTimeout = Duration(seconds: 10);

// ── Endpoint de verificação ─────────────────────────────────────────
// Mude para o caminho real do seu backend:
//   Spring Boot: GET /actuator/health  →  { "status": "UP" }
//   Ou endpoint customizado:            →  qualquer 2xx
// const _kHealthPath = '/api/health';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── animações ────────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _barCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double>  _logoScale;
  late final Animation<double>  _logoFade;
  late final Animation<double>  _textFade;
  late final Animation<Offset>  _textSlide;
  late final Animation<double>  _pulse;

  // ── estado ───────────────────────────────────────────────────────
  _SplashState _state       = _SplashState.iniciando;
  String       _statusMsg   = 'A iniciar…';
  String?      _errorDetail;
  double       _barProgress = 0;   // 0.0 → 1.0 (barra manual)
  String       _resolvedUrl = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  // ── setup de animações ───────────────────────────────────────────
  void _setupAnimations() {
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: .6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, .3),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _pulse = Tween<double>(begin: .85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  // ── sequência principal ─────────────────────────────────────────
Future<void> _startSequence() async {
  // Entrada do logo
  await _logoCtrl.forward();
  await Future.delayed(const Duration(milliseconds: 100));
  await _textCtrl.forward();

  // Simulação de carregamento
  final steps = [
    ['A iniciar módulos...', 0.15],
    ['A verificar sistema...', 0.30],
    ['A carregar interface...', 0.50],
    ['A sincronizar recursos...', 0.70],
    ['A preparar dashboard...', 0.90],
    ['Pronto!', 1.0],
  ];

  for (final step in steps) {
    _setStep(step[0] as String, step[1] as double);
    await Future.delayed(
      Duration(milliseconds: step[1] == 1.0 ? 500 : 700),
    );
  }

  // Navegação
  if (mounted) {
    Navigator.of(context).pushReplacementNamed('/');
  }
}

  // ── health-check ────────────────────────────────────────────────
  // Future<bool> _healthCheck() async {
  //   try {
  //     final uri = Uri.parse('$_resolvedUrl$_kHealthPath');
  //     final response = await http
  //         .get(uri, headers: ApiConfig.defaultHeaders)
  //         .timeout(_kHealthTimeout);

  //     if (response.statusCode >= 200 && response.statusCode < 300) {
  //       return true;
  //     }

  //     _setError(
  //       'Servidor respondeu com erro ${response.statusCode}.',
  //       'Verifique se o backend está em execução em $_resolvedUrl',
  //     );
  //     return false;
  //   } on TimeoutException {
  //     _setError(
  //       'Tempo limite excedido.',
  //       'O servidor em $_resolvedUrl não respondeu em ${_kHealthTimeout.inSeconds}s.\n'
  //       'Verifique a ligação ou as configurações de rede.',
  //     );
  //     return false;
  //   } catch (e) {
  //     _setError(
  //       'Não foi possível ligar ao servidor.',
  //       'Endereço: $_resolvedUrl\nDetalhe: $e\n\n'
  //       'Em produção, configure API_BASE_URL via --dart-define.',
  //     );
  //     return false;
  //   }
  // }

  // ── helpers de estado ────────────────────────────────────────────
  void _setStep(String msg, double progress) {
    if (!mounted) return;
    setState(() {
      _state       = _SplashState.carregando;
      _statusMsg   = msg;
      _barProgress = progress;
    });
  }

  void _setError(String msg, String detail) {
    if (!mounted) return;
    setState(() {
      _state       = _SplashState.erro;
      _statusMsg   = msg;
      _errorDetail = detail;
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _barCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildLogo(),
                const SizedBox(height: 28),
                _buildTitle(),
                const Spacer(flex: 2),
                _buildStatusArea(),
                const Spacer(flex: 1),
                _buildFooter(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── logo ─────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: ScaleTransition(
          scale: _state == _SplashState.carregando ? _pulse : AlwaysStoppedAnimation(1.0),
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: _navy.withOpacity(.35),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(.12),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 110,
                height: 110,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── título e subtítulo ───────────────────────────────────────────
  Widget _buildTitle() {
    return FadeTransition(
      opacity: _textFade,
      child: SlideTransition(
        position: _textSlide,
        child: Column(
          children: [
            const Text(
              'Gestor STech',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _navy,
                letterSpacing: .4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sistema de Gestão de Pedidos',
              style: TextStyle(
                fontSize: 13,
                color: _navy.withOpacity(.5),
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── área de status / erro ────────────────────────────────────────
  Widget _buildStatusArea() {
    if (_state == _SplashState.erro) return _buildErrorArea();
    return _buildProgressArea();
  }

  Widget _buildProgressArea() {
    return Column(
      children: [
        // barra de progresso
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: _navy.withOpacity(.10),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (_, constraints) => Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: constraints.maxWidth * _barProgress,
                  decoration: BoxDecoration(
                    color: _barProgress == 1.0 ? Colors.green[600] : _red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // mensagem de status
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Row(
            key: ValueKey(_statusMsg),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_state == _SplashState.carregando && _barProgress < 1.0)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: _red,
                  ),
                ),
              if (_barProgress == 1.0)
                const Icon(Icons.check_circle_outline,
                    size: 14, color: Colors.green),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _statusMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _navy.withOpacity(.6),
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorArea() {
    return Column(
      children: [
        // ícone de erro
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: _red, size: 28),
              const SizedBox(height: 10),
              Text(
                _statusMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF991B1B),
                ),
              ),
              if (_errorDetail != null) ...[
                const SizedBox(height: 6),
                Text(
                  _errorDetail!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red[400],
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        // botão tentar novamente
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _state       = _SplashState.iniciando;
                _statusMsg   = 'A iniciar…';
                _errorDetail = null;
                _barProgress = 0;
              });
              _startSequence();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Tentar novamente',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── rodapé ───────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Text(
      'STech Engenharia © ${DateTime.now().year}',
      style: TextStyle(
        fontSize: 11,
        color: _navy.withOpacity(.3),
        letterSpacing: .4,
      ),
    );
  }
}

// ── estados internos ────────────────────────────────────────────────
enum _SplashState { iniciando, carregando, erro }

