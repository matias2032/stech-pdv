// lib/screens/servico_list_screen.dart

import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import '../widgets/app_sidebar.dart';
import 'servico_form_screen.dart';

// Cores seguindo o padrão fornecido
const _kVermelho = Color(0xFFC8102E);
const _kAzul = Color(0xFF1B2A6B);
const _kBranco = Colors.white;
const _kCinzaClaro = Color(0xFFF4F5F7);
const _kCinzaTexto = Color(0xFF6B7280);

class ServicoListScreen extends StatefulWidget {
  const ServicoListScreen({Key? key}) : super(key: key);

  @override
  State<ServicoListScreen> createState() => _ServicoListScreenState();
}

class _ServicoListScreenState extends State<ServicoListScreen> {
  final ServicoService _servicoService = ServicoService.instance;
  
  List<ServicoModel> _servicos = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarServicos();
  }

  Future<void> _carregarServicos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Lista todos (ativos e inativos) para a gestão
      final servicos = await _servicoService.listarTodos();
      
      setState(() {
        _servicos = servicos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar serviços: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(ServicoModel servico) async {
    try {
      final servicoAtualizado = await _servicoService.toggleAtivo(servico.idServico);
      
      setState(() {
        final index = _servicos.indexWhere((s) => s.idServico == servico.idServico);
        if (index != -1) {
          _servicos[index] = servicoAtualizado;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Serviço "${servico.nomeServico}" agora está ${servicoAtualizado.ativo ? 'Ativo' : 'Inativo'}'),
          backgroundColor: servicoAtualizado.ativo ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navegarParaFormulario({ServicoModel? servico}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServicoFormScreen(servico: servico),
      ),
    );

    // Se o formulário retornar true, atualizamos a lista
    if (resultado == true) {
      _carregarServicos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCinzaClaro,
      appBar: AppBar(
        title: const Text('Catálogo de Serviços'),
        backgroundColor: _kAzul,
        foregroundColor: _kBranco,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarServicos,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      drawer: const AppSidebar(currentRoute: '/gerenciar_servicos'),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarParaFormulario(),
        backgroundColor: _kVermelho,
        foregroundColor: _kBranco,
        icon: const Icon(Icons.add),
        label: const Text('Novo Serviço'),
      ),
    );
  }

Widget _buildBody() {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator(color: _kAzul));
  }

  if (_errorMessage != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _kVermelho),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kCinzaTexto)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregarServicos,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kAzul, foregroundColor: _kBranco),
            ),
          ],
        ),
      ),
    );
  }

  if (_servicos.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.miscellaneous_services_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Nenhum serviço cadastrado',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: _carregarServicos,
    child: Column(
      children: [
        // Cabeçalho da tabela
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: _kAzul,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3,
                  child: Text('Serviço',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700))),
              Expanded(flex: 3,
                  child: Text('Descrição',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700))),
              Expanded(flex: 2,
                  child: Text('Preço',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700))),
              Expanded(flex: 1,
                  child: Text('Unidade',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700))),
              Expanded(flex: 1,
                  child: Text('Estado',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700))),
              SizedBox(width: 100),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            itemCount: _servicos.length,
            itemBuilder: (_, i) => _ServicoLinhaTabela(
              servico: _servicos[i],
              isAlternate: i.isOdd,
              onEditar: () => _navegarParaFormulario(servico: _servicos[i]),
              onToggle: () => _toggleStatus(_servicos[i]),
            ),
          ),
        ),
      ],
    ),
  );
}


}

class _ServicoLinhaTabela extends StatelessWidget {
  const _ServicoLinhaTabela({
    required this.servico,
    required this.isAlternate,
    required this.onEditar,
    required this.onToggle,
  });

  final ServicoModel servico;
  final bool         isAlternate;
  final VoidCallback onEditar;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ativo = servico.ativo;

    return Container(
      decoration: BoxDecoration(
        color: isAlternate ? const Color(0xFFF0F2FA) : Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE8EAF0)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Ícone + Nome
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ativo
                          ? _kAzul.withOpacity(0.08)
                          : Colors.grey.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      size: 16,
                      color: ativo ? _kAzul : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      servico.nomeServico,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ativo ? _kAzul : _kCinzaTexto,
                        decoration: ativo
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Descrição
            Expanded(
              flex: 3,
              child: Text(
                servico.descricao?.isNotEmpty == true
                    ? servico.descricao!
                    : '—',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[600]),
              ),
            ),

            // Preço
            Expanded(
              flex: 2,
              child: Text(
                'MZN ${servico.precoUnitario.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kAzul,
                ),
              ),
            ),

            // Unidade
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  servico.unidade,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Estado
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: ativo
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ativo ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Text(
                    ativo ? 'Ativo' : 'Inativo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ativo
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ),
            ),

            // Ações
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Toggle via switch compacto
                  Tooltip(
                    message: ativo ? 'Desativar' : 'Ativar',
                    child: Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: ativo,
                        onChanged: (_) => onToggle(),
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.orange,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Editar',
                    child: InkWell(
                      onTap: onEditar,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _kAzul.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            size: 16, color: _kAzul),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}