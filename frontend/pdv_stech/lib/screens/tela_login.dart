// lib/screens/tela_login.dart

import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';


// ──────────────────────────────────────────────
// Paleta STech
// ──────────────────────────────────────────────
const _navy   = Color(0xFF1B2A6B);
const _red    = Color(0xFFC8102E);
const _bg     = Color(0xFFF4F5F7);
const _border = Color(0xFFE2E5ED);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _credencialCtrl = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _authService    = ServicoAutenticacao();

  bool _isLoading      = false;
  bool _obscurePass    = true;
  String _errorMessage = '';

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, .08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _credencialCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── lógica ──────────────────────────────────
  Future<void> _handleLogin() async {
    final credencial = _credencialCtrl.text.trim();
    final password   = _passwordCtrl.text;

    if (credencial.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Preencha todos os campos.');
      return;
    }

    setState(() {
      _isLoading    = true;
      _errorMessage = '';
    });

    try {
      final result = await _authService.login(credencial, password);

      switch (result.status) {
        case StatusAutenticacao.primeiraSenha:
          if (result.usuario != null) {
            SessaoService.instance.iniciar(result.usuario!);
          }
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/primeira_troca_senha');
          }

        case StatusAutenticacao.sucesso:
          if (result.usuario != null) {
            SessaoService.instance.iniciar(result.usuario!);
          }
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }

        default:
          setState(() {
            _errorMessage = result.mensagem ?? 'Erro desconhecido.';
            _isLoading    = false;
          });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao conectar: $e';
        _isLoading    = false;
      });
    }
  }

  // ── UI ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 4),
                    _buildCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── cabeçalho ───────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 48),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // logo mark
Container(
  width: 100,
  height: 100,
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(.10),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.white.withOpacity(.25), width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.25),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Image.asset(
      'assets/icon/app_icon.png',
      width: 100,
      height: 100,
      fit: BoxFit.contain,   // contain em vez de cover — preserva margens do ícone
    ),
  ),
),
const SizedBox(height: 20),

          const Text(
            'Gestor STech',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Acesso ao sistema de gestão',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(.5),
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }

  // ── card de formulário ───────────────────────
  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            label:      'Credencial',
            hint:       'E-mail, telefone ou apelido',
            controller: _credencialCtrl,
            icon:       Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 16),
          _buildField(
            label:      'Senha',
            hint:       'Digite a sua senha',
            controller: _passwordCtrl,
            icon:       Icons.lock_outline_rounded,
            obscure:    _obscurePass,
            suffix: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            onSubmitted: (_) => _handleLogin(),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildErrorBanner(),
          ],
          const SizedBox(height: 22),
          _buildLoginButton(),
        ],
      ),
    );
  }

  // ── campo de input ───────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller:   controller,
          obscureText:  obscure,
          keyboardType: keyboardType,
          onSubmitted:  onSubmitted,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText:        hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            prefixIcon:      Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            suffixIcon:      suffix,
            filled:          true,
            fillColor:       const Color(0xFFF8F9FB),
            contentPadding:  const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _navy, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── banner de erro ───────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: Color(0xFFC8102E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF991B1B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── botão principal ──────────────────────────
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          disabledBackgroundColor: _navy.withOpacity(.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Entrar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
      ),
    );
  }
}

