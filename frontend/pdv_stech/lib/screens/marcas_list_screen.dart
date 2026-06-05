// lib/screens/marcas_list_screen.dart

import 'package:flutter/material.dart';
import 'marca_form_screen.dart';
import '../widgets/app_sidebar.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

const _kVermelho = Color(0xFFC8102E);
const _kAzul = Color(0xFF1B2A6B);
const _kBranco = Colors.white;
const _kCinzaClaro = Color(0xFFF4F5F7);
const _kCinzaTexto = Color(0xFF6B7280);

class MarcasListScreen extends StatefulWidget {
  const MarcasListScreen({super.key});

  @override
  State<MarcasListScreen> createState() => _MarcasListScreenState();
}

class _MarcasListScreenState extends State<MarcasListScreen> {
  final MarcaService _marcaService = MarcaService();

  List<MarcaModel> _marcas = [];
  // Cache de categorias por marca — populado quando o backend
  // disponibilizar endpoint de categorias-por-marca.
  Map<int, List<CategoriaModel>> _categoriasPorMarca = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarMarcas();
  }

  Future<void> _carregarMarcas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final marcas = await _marcaService.listarMarcasComCategorias();
      setState(() {
        _marcas = marcas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar marcas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletarMarca(MarcaModel marca) async {
    // MarcaModel não tem campo categorias — usa mapa externo.
    // Quando o backend disponibilizar endpoint de categorias-por-marca,
    // popular _categoriasPorMarca em _carregarMarcas().
    final categorias = _categoriasPorMarca[marca.id] ?? [];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja realmente excluir a marca "${marca.nomeMarca}"?',
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
                      categorias.isEmpty
                          ? 'Esta marca não está associada a nenhuma categoria.'
                          : 'As ${categorias.length} categoria(s) associada(s) NÃO serão excluídas.',
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
        await _marcaService.deletarMarca(marca.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Marca "${marca.nomeMarca}" excluída'),
              backgroundColor: Colors.green,
            ),
          );
          _carregarMarcas();
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

  void _navegarParaFormulario({MarcaModel? marca}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarcaFormScreen(marca: marca),
      ),
    );

    if (resultado == true) {
      _carregarMarcas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarMarcas,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      drawer: const AppSidebar(currentRoute: '/gerenciar_marcas'),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarParaFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Marca'),
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
              onPressed: _carregarMarcas,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_marcas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.label_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma marca cadastrada',
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
      onRefresh: _carregarMarcas,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _marcas.length,
        itemBuilder: (context, index) {
          final marca = _marcas[index];
          return _buildMarcaCard(marca);
        },
      ),
    );
  }

  Widget _buildMarcaCard(MarcaModel marca) {
    // MarcaModel não tem campo categorias — usa mapa externo.
    final categorias = _categoriasPorMarca[marca.id] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            marca.nomeMarca[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          marca.nomeMarca,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          categorias.isEmpty
              ? 'Nenhuma categoria associada'
              : '${categorias.length} categoria(s) associada(s)',
          style: TextStyle(
            color: categorias.isEmpty ? Colors.grey : Colors.blue[700],
            fontSize: 13,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _navegarParaFormulario(marca: marca),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletarMarca(marca),
              tooltip: 'Excluir',
            ),
          ],
        ),
        children: [
          if (categorias.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.category_outlined,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Esta marca ainda não está associada a nenhuma categoria',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _navegarParaFormulario(marca: marca),
                    icon: const Icon(Icons.add),
                    label: const Text('Associar Categorias'),
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
                      Icon(Icons.category, size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Categorias Associadas:',
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
                    children: categorias.map((categoria) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            categoria.nomeCategoria[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        label: Text(categoria.nomeCategoria),
                        backgroundColor: Colors.blue[50],
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