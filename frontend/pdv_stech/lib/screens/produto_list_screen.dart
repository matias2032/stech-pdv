// lib/screens/produto_list_screen.dart

import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:api_compartilhado/api_config.dart';
import 'package:intl/intl.dart';
import '../widgets/app_sidebar.dart';
import 'produto_form_screen.dart';

class ProdutoListScreen extends StatefulWidget {
  const ProdutoListScreen({Key? key}) : super(key: key);

  @override
  State<ProdutoListScreen> createState() => _ProdutoListScreenState();
}

class _ProdutoListScreenState extends State<ProdutoListScreen> {
  final ProdutoService _produtoService = ProdutoService.instance;

  List<ProdutoModel> _produtos = [];
  bool _isLoading = true;
  String? _errorMessage;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_PT',
    symbol: 'MZN',
  );

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final produtos = await _produtoService.listar();
      setState(() {
        _produtos = produtos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar produtos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(ProdutoModel produto) async {
    final novoStatus = produto.estaAtivo ? 'desativar' : 'ativar';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${produto.estaAtivo ? 'Desativar' : 'Ativar'} Produto'),
        content: Text(
            'Tem certeza que deseja $novoStatus o produto "${produto.nomeProduto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  produto.estaAtivo ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(produto.estaAtivo ? 'Desativar' : 'Ativar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _produtoService.toggleAtivo(produto.idProduto);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status do produto atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _carregarProdutos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navegarParaFormulario([ProdutoModel? produto]) async {
    final houveAlteracao = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProdutoFormScreen(produto: produto),
      ),
    );

    if (houveAlteracao == true) {
      _carregarProdutos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        backgroundColor: const Color(0xFF1B2A6B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarProdutos,
          ),
        ],
      ),
      drawer: const AppSidebar(currentRoute: '/gerenciar_produtos'),
      backgroundColor: const Color(0xFFF4F5F7),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarParaFormulario(),
        backgroundColor: const Color(0xFFC8102E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

Widget _buildBody() {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_errorMessage != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _carregarProdutos,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  if (_produtos.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Nenhum produto encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: _carregarProdutos,
    child: Column(
      children: [
        // Cabeçalho da tabela
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF1B2A6B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3,
                  child: Text('Produto',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700))),
              Expanded(flex: 2,
                  child: Text('Preço',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700))),
              Expanded(flex: 2,
                  child: Text('Promoção',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700))),
              Expanded(flex: 2,
                  child: Text('Estoque',
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
            itemCount: _produtos.length,
            itemBuilder: (_, i) => _ProdutoLinhaTabela(
              produto: _produtos[i],
              currencyFmt: _currencyFormat,
              isAlternate: i.isOdd,
              onEditar: () => _navegarParaFormulario(_produtos[i]),
              onToggle: () => _toggleStatus(_produtos[i]),
            ),
          ),
        ),
      ],
    ),
  );
}



}

class _ProdutoLinhaTabela extends StatelessWidget {
  const _ProdutoLinhaTabela({
    required this.produto,
    required this.currencyFmt,
    required this.isAlternate,
    required this.onEditar,
    required this.onToggle,
  });

  final ProdutoModel produto;
  final NumberFormat currencyFmt;
  final bool isAlternate;
  final VoidCallback onEditar;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final temPromo   = produto.precoPromocional != null;
    final semEstoque = produto.quantidadeEstoque <= 0;

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
            // Nome
            Expanded(
              flex: 3,
              child: Text(
                produto.nomeProduto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B2A6B),
                ),
              ),
            ),

            // Preço normal
            Expanded(
              flex: 2,
              child: Text(
                currencyFmt.format(produto.preco),
                style: TextStyle(
                  fontSize: 12,
                  color: temPromo ? Colors.grey : const Color(0xFF1B2A6B),
                  fontWeight: FontWeight.w500,
                  decoration: temPromo ? TextDecoration.lineThrough : null,
                ),
              ),
            ),

            // Promoção
            Expanded(
              flex: 2,
              child: temPromo
                  ? Row(children: [
                      Text(
                        currencyFmt.format(produto.precoPromocional),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC8102E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8102E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('PROMO',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800)),
                      ),
                    ])
                  : Text('—',
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 12)),
            ),

            // Estoque
            Expanded(
              flex: 2,
              child: Row(children: [
                Icon(
                  semEstoque
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  size: 14,
                  color: semEstoque ? Colors.red : Colors.green[600],
                ),
                const SizedBox(width: 4),
                Text(
                  semEstoque ? 'Esgotado' : '${produto.quantidadeEstoque}',
                  style: TextStyle(
                    fontSize: 12,
                    color: semEstoque ? Colors.red : Colors.grey[700],
                    fontWeight: semEstoque
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ]),
            ),

            // Estado
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: produto.estaAtivo
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: produto.estaAtivo
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  produto.estaAtivo ? 'Ativo' : 'Inativo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: produto.estaAtivo
                        ? Colors.green[700]
                        : Colors.red[700],
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
                  Tooltip(
                    message: 'Editar',
                    child: InkWell(
                      onTap: onEditar,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2A6B).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            size: 16, color: Color(0xFF1B2A6B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: produto.estaAtivo ? 'Desativar' : 'Ativar',
                    child: InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (produto.estaAtivo
                                  ? Colors.orange
                                  : Colors.green)
                              .withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          produto.estaAtivo
                              ? Icons.block_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 16,
                          color: produto.estaAtivo
                              ? Colors.orange
                              : Colors.green[700],
                        ),
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