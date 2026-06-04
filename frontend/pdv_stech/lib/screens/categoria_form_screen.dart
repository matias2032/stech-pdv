
import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';


class CategoriaFormScreen extends StatefulWidget {
  final Categoria? categoria;

  const CategoriaFormScreen({Key? key, this.categoria}) : super(key: key);

  @override
  State<CategoriaFormScreen> createState() => _CategoriaFormScreenState();
}

class _CategoriaFormScreenState extends State<CategoriaFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final CategoriaService _categoriaService = CategoriaService();
  final MarcaService _marcaService = MarcaService();

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TabController _tabController;

  bool _isLoading = false;
  bool _isLoadingMarcas = false;
  bool get _isEditMode => widget.categoria != null;

  // Marcas
  List<Marca> _todasMarcas = [];
  Set<int> _marcasSelecionadas = {};
  int? _categoriaIdSalva; // Guarda o ID após salvar

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nomeController = TextEditingController(
      text: widget.categoria?.nomeCategoria ?? '',
    );
    _descricaoController = TextEditingController(
      text: widget.categoria?.descricao ?? '',
    );

    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await _carregarMarcas();
    if (_isEditMode && widget.categoria!.idCategoria != null) {
      _categoriaIdSalva = widget.categoria!.idCategoria;
      await _carregarMarcasDaCategoria(widget.categoria!.idCategoria!);
    }
  }

  Future<void> _carregarMarcas() async {
    setState(() => _isLoadingMarcas = true);
    try {
      final marcas = await _marcaService.listarMarcas();
      setState(() {
        _todasMarcas = marcas;
        _isLoadingMarcas = false;
      });
    } catch (e) {
      setState(() => _isLoadingMarcas = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar marcas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _carregarMarcasDaCategoria(int idCategoria) async {
    try {
      final marcasIds =
          await _categoriaService.listarMarcasDaCategoria(idCategoria);
      setState(() {
        _marcasSelecionadas = marcasIds.toSet();
      });
    } catch (e) {
      print('Erro ao carregar marcas da categoria: $e');
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final categoria = Categoria(
        idCategoria: widget.categoria?.idCategoria,
        nomeCategoria: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
      );

      Categoria categoriaSalva;

      if (_isEditMode) {
        categoriaSalva = await _categoriaService.atualizarCategoria(
          widget.categoria!.idCategoria!,
          categoria,
        );
      } else {
        categoriaSalva = await _categoriaService.criarCategoria(categoria);
      }

      // Guarda o ID para usar na aba de marcas
      _categoriaIdSalva = categoriaSalva.idCategoria;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Categoria atualizada com sucesso'
                  : 'Categoria criada com sucesso',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Se for criação, permite associar marcas
        if (!_isEditMode) {
          setState(() {
            // Força rebuild para habilitar aba de marcas
          });
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

  Future<void> _toggleMarca(int idMarca, bool? valor) async {
    if (_categoriaIdSalva == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salve a categoria antes de associar marcas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (valor == true) {
        // Associar
        await _categoriaService.associarMarca(_categoriaIdSalva!, idMarca);
        setState(() {
          _marcasSelecionadas.add(idMarca);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Marca associada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Desassociar
        await _categoriaService.desassociarMarca(_categoriaIdSalva!, idMarca);
        setState(() {
          _marcasSelecionadas.remove(idMarca);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Marca desassociada'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Categoria' : 'Nova Categoria'),
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
            Tab(icon: Icon(Icons.label), text: 'Marcas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInformacoesTab(),
          _buildMarcasTab(),
        ],
      ),
    );
  }

  // ===== ABA 1: INFORMAÇÕES =====
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
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Informações Básicas',
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
                      labelText: 'Nome da Categoria *',
                      hintText: 'Ex: Smartphones, Eletrônicos...',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, informe o nome da categoria';
                      }
                      if (value.trim().length < 3) {
                        return 'O nome deve ter pelo menos 3 caracteres';
                      }
                      if (value.trim().length > 100) {
                        return 'O nome deve ter no máximo 100 caracteres';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (Opcional)',
                      hintText: 'Descreva esta categoria...',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value != null && value.trim().length > 500) {
                        return 'A descrição deve ter no máximo 500 caracteres';
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
          if (_categoriaIdSalva == null)
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
                        'Salve a categoria primeiro para poder associar marcas.',
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
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
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

  // ===== ABA 2: MARCAS =====
  Widget _buildMarcasTab() {
    if (_categoriaIdSalva == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Salve a categoria primeiro',
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

    if (_isLoadingMarcas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todasMarcas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.label_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma marca cadastrada',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre marcas primeiro para associá-las',
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
                    Icon(Icons.label, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Marcas Permitidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecione as marcas que podem operar nesta categoria',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const Divider(height: 24),
                ..._todasMarcas.map((marca) {
                  final isSelected =
                      _marcasSelecionadas.contains(marca.idMarca);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (valor) => _toggleMarca(marca.idMarca!, valor),
                    title: Text(marca.nomeMarca),
                    secondary: CircleAvatar(
                      backgroundColor: isSelected ? Colors.green : Colors.grey,
                      child: Text(
                        marca.nomeMarca[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    activeColor: Theme.of(context).primaryColor,
                  );
                }).toList(),
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
                    'Marcas selecionadas: ${_marcasSelecionadas.length}',
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