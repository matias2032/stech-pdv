// lib/screens/marca_form_screen.dart

import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

class MarcaFormScreen extends StatefulWidget {
  final MarcaModel? marca;

  const MarcaFormScreen({super.key, this.marca});

  @override
  State<MarcaFormScreen> createState() => _MarcaFormScreenState();
}

class _MarcaFormScreenState extends State<MarcaFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final MarcaService _marcaService = MarcaService();
  final CategoriaService _categoriaService = CategoriaService();

  late TextEditingController _nomeController;
  late TabController _tabController;

  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  bool _houveAlteracoes = false;
  bool get _isEditMode => widget.marca != null;

  List<CategoriaModel> _todasCategorias = [];
  Set<int> _categoriasSelecionadas = {};
  int? _marcaIdSalva;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nomeController = TextEditingController(
      text: widget.marca?.nomeMarca ?? '',
    );

    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await _carregarCategorias();
    if (_isEditMode) {
      _marcaIdSalva = widget.marca!.id;
      // MarcaModel não tem campo categorias embebido.
      // Inicia com set vazio — utilizador gere associações manualmente.
      // Quando o backend disponibilizar endpoint de categorias-por-marca,
      // substituir aqui pela chamada correspondente.
      setState(() => _categoriasSelecionadas = {});
    }
  }

  Future<void> _carregarCategorias() async {
    setState(() => _isLoadingCategorias = true);
    try {
      final categorias = await _categoriaService.listarCategorias();
      setState(() {
        _todasCategorias = categorias;
        _isLoadingCategorias = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategorias = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar categorias: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dto = MarcaRequestDTO(
        nomeMarca: _nomeController.text.trim(),
      );

      MarcaModel marcaSalva;

      if (_isEditMode) {
        marcaSalva = await _marcaService.atualizarMarca(
          widget.marca!.id,
          dto,
        );
      } else {
        marcaSalva = await _marcaService.criarMarca(dto);
      }

      _marcaIdSalva = marcaSalva.id;
      _houveAlteracoes = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Marca atualizada com sucesso'
                  : 'Marca criada com sucesso',
            ),
            backgroundColor: Colors.green,
          ),
        );

        if (!_isEditMode) {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleCategoria(int idCategoria, bool? valor) async {
    if (_marcaIdSalva == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salve a marca antes de associar categorias'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (valor == true) {
        await _marcaService.associarCategoria(_marcaIdSalva!, idCategoria);
        setState(() {
          _categoriasSelecionadas.add(idCategoria);
          _houveAlteracoes = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoria associada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _marcaService.desassociarCategoria(_marcaIdSalva!, idCategoria);
        setState(() {
          _categoriasSelecionadas.remove(idCategoria);
          _houveAlteracoes = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoria desassociada'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context, _houveAlteracoes);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Editar Marca' : 'Nova Marca'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _houveAlteracoes),
          ),
          actions: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.info), text: 'Informações'),
              Tab(icon: Icon(Icons.category), text: 'Categorias'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInformacoesTab(),
            _buildCategoriasTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInformacoesTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.label,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Informações da Marca',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Marca *',
                      hintText: 'Ex: Samsung, Apple, Xiaomi...',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, informe o nome da marca';
                      }
                      if (value.trim().length < 2) {
                        return 'O nome deve ter pelo menos 2 caracteres';
                      }
                      if (value.trim().length > 100) {
                        return 'O nome deve ter no máximo 100 caracteres';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_marcaIdSalva == null)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Salve a marca primeiro para poder associar categorias.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pop(context, _houveAlteracoes),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _salvar,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isEditMode ? 'Atualizar' : 'Salvar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriasTab() {
    if (_marcaIdSalva == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Salve a marca primeiro',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Volte para a aba "Informações" e clique em Salvar',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoadingCategorias) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todasCategorias.isEmpty) {
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
              'Cadastre categorias primeiro para associá-las',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category,
                        color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Categorias Disponíveis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecione as categorias nas quais esta marca pode operar',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const Divider(height: 24),
                ..._todasCategorias.map((categoria) {
                  final isSelected =
                      _categoriasSelecionadas.contains(categoria.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (valor) =>
                        _toggleCategoria(categoria.id, valor),
                    title: Text(categoria.nomeCategoria),
                    subtitle: categoria.descricao != null &&
                            categoria.descricao!.isNotEmpty
                        ? Text(
                            categoria.descricao!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    secondary: CircleAvatar(
                      backgroundColor: isSelected ? Colors.green : Colors.grey,
                      child: Text(
                        categoria.nomeCategoria[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    activeColor: Theme.of(context).primaryColor,
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.green[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Categorias selecionadas: ${_categoriasSelecionadas.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}