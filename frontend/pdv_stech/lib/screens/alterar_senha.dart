import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

const _kPrimary    = Color.fromARGB(255, 27, 42, 107);
const _kAccent     = Color.fromARGB(255, 200, 16, 46);
const _kBackground = Color(0xFFF4F5F7);
const _kCardBg     = Colors.white;

class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({super.key});

  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();

final _usuarioService = UsuarioService();
  final TextEditingController _senhaAtualController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmacaoSenhaController =
      TextEditingController();

  bool _obscureSenhaAtual = true;
  bool _obscureNovaSenha = true;
  bool _obscureConfirmacao = true;
  bool _isLoading = false;

  String? _errorMessage;


  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmacaoSenhaController.dispose();
    super.dispose();
  }

  Future<void> _alterarSenha() async {
  setState(() => _errorMessage = null);
  if (!_formKey.currentState!.validate()) return;

  if (_novaSenhaController.text != _confirmacaoSenhaController.text) {
    setState(() => _errorMessage = 'A nova senha e a confirmação não coincidem.');
    return;
  }

  setState(() => _isLoading = true);
  try {
    final usuario = SessaoService.instance.usuarioAtual;
    if (usuario == null) throw Exception('Usuário não encontrado na sessão.');

    await _usuarioService.alterarSenha(
      usuario.id,
      _senhaAtualController.text,
      _novaSenhaController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha alterada com sucesso! Você será deslogado.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        SessaoService.instance.limparSessao();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      }
    }
  } catch (e) {
    setState(() => _errorMessage = e.toString());
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alterar Senha'),
        backgroundColor:  Color.fromARGB(255, 27, 42, 107),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header decorativo
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color:  Color.fromARGB(255, 27, 42, 107),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Segurança da Conta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mantenha sua senha sempre segura',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Formulário
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info card
                    Card(
                      elevation: 0,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Para sua segurança, você não poderá usar senhas anteriormente utilizadas.',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Mensagem de erro
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color:  Color.fromARGB(255, 20, 32, 82)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color:   Color.fromARGB(255, 200, 16, 46),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Senha Atual
                    Text(
                      'Senha Atual',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _senhaAtualController,
                      obscureText: _obscureSenhaAtual,
                      decoration: InputDecoration(
                        hintText: 'Digite sua senha atual',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureSenhaAtual
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscureSenhaAtual = !_obscureSenhaAtual),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Por favor, insira a senha atual.'
                          : null,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Nova Senha',
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500)),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Nova Senha
                    Text(
                      'Nova Senha',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _novaSenhaController,
                      obscureText: _obscureNovaSenha,
                      decoration: InputDecoration(
                        hintText: 'Digite a nova senha',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNovaSenha
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscureNovaSenha = !_obscureNovaSenha),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a nova senha.';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Confirmação
                    Text(
                      'Confirmar Nova Senha',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmacaoSenhaController,
                      obscureText: _obscureConfirmacao,
                      decoration: InputDecoration(
                        hintText: 'Confirme a nova senha',
                        prefixIcon: const Icon(Icons.lock_clock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmacao
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscureConfirmacao = !_obscureConfirmacao),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Por favor, confirme a nova senha.'
                          : null,
                    ),

                    const SizedBox(height: 30),

                    // Requisitos
                    Card(
                      elevation: 0,
                      color: Colors.grey[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Requisitos da Senha:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            _buildRequirement('Mínimo de 6 caracteres'),
                            _buildRequirement(
                                'Diferente de senhas anteriores'),
                            _buildRequirement(
                                'Nova senha e confirmação devem ser iguais'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _alterarSenha,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:  Color.fromARGB(255, 27, 42, 107),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'ALTERAR SENHA',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}