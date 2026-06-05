// lib/screens/categoria/categorias_list_screen.dart

import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'categoria_form_screen.dart';
import '../widgets/app_sidebar.dart';

const _kVermelho = Color(0xFFC8102E);
const _kAzul = Color(0xFF1B2A6B);
const _kBranco = Colors.white;
const _kCinzaClaro = Color(0xFFF4F5F7);
const _kCinzaTexto = Color(0xFF6B7280);

class CategoriasListScreen extends StatefulWidget {
  const CategoriasListScreen({super.key});

  @override
  State<CategoriasListScreen> createState() => _CategoriasListScreenState();
}

class _CategoriasListScreenState extends State<CategoriasListScreen> {
  final CategoriaService _categoriaService = CategoriaService();
  final MarcaService _marcaService = MarcaService();

  List<CategoriaModel> _categorias = [];
  Map<int, List<MarcaModel>> _marcasPorCategoria = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categorias = await _categoriaService.listarCategorias();
      setState(() {
        _categorias = categorias;
        _isLoading = false;
      });

      // Carregar marcas de cada categoria
      _carregarMarcasDeTodasCategorias();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar categorias: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _carregarMarcasDeTodasCategorias() async {
    // listarMarcasDaCategoria não existe no CategoriaService.
    // Carregamos todas as marcas mas não conseguimos filtrar por categoria
    // sem endpoint dedicado. O mapa fica vazio até o backend disponibilizar
    // esse endpoint — a UI trata o caso de lista vazia correctamente.
    try {
      await _marcaService.listarMarcas();
      // Sem endpoint de marcas-por-categoria, mapa permanece vazio.
      // Quando o endpoint existir, substituir aqui por lógica de filtragem.
    } catch (e) {
      debugPrint('Erro ao carregar marcas: $e');
    }
  }

  Future<void> _deletarCategoria(CategoriaModel categoria) async {
    final marcas = _marcasPorCategoria[categoria.id] ?? [];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja realmente excluir a categoria "${categoria.nomeCategoria}"?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      marcas.isEmpty
                          ? 'Esta categoria não está associada a nenhuma marca.'
                          : 'As ${marcas.length} marca(s) associada(s) e os produtos NÃO serão excluídos.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _categoriaService.deletarCategoria(categoria.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Categoria "${categoria.nomeCategoria}" excluída'),
              backgroundColor: Colors.green,
            ),
          );
          _carregarCategorias();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navegarParaFormulario({CategoriaModel? categoria}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriaFormScreen(categoria: categoria),
      ),
    );

    if (resultado == true) {
      _carregarCategorias();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarCategorias,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      drawer: const AppSidebar(currentRoute: '/gerenciar_categorias'),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarParaFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregarCategorias,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_categorias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma categoria cadastrada',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão + para adicionar',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarCategorias,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final categoria = _categorias[index];
          return _buildCategoriaCard(categoria);
        },
      ),
    );
  }

  Widget _buildCategoriaCard(CategoriaModel categoria) {
    final marcas = _marcasPorCategoria[categoria.id] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            categoria.nomeCategoria[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          categoria.nomeCategoria,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (categoria.descricao != null && categoria.descricao!.isNotEmpty)
              Text(
                categoria.descricao!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              )
            else
              const Text(
                'Sem descrição',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              marcas.isEmpty
                  ? 'Nenhuma marca associada'
                  : '${marcas.length} marca(s) associada(s)',
              style: TextStyle(
                color: marcas.isEmpty ? Colors.grey : Colors.orange[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _navegarParaFormulario(categoria: categoria),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletarCategoria(categoria),
              tooltip: 'Excluir',
            ),
          ],
        ),
        children: [
          if (marcas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.label_off_outlined,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Esta categoria ainda não está associada a nenhuma marca',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        _navegarParaFormulario(categoria: categoria),
                    icon: const Icon(Icons.add),
                    label: const Text('Associar Marcas'),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.label, size: 20, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Marcas Associadas:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: marcas.map((marca) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(
                            marca.nomeMarca[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        label: Text(marca.nomeMarca),
                        backgroundColor: Colors.orange[50],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}