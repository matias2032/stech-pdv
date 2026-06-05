// lib/screens/produto_form_screen.dart

import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:api_compartilhado/api_config.dart';

class ProdutoFormScreen extends StatefulWidget {
  final ProdutoModel? produto;

  const ProdutoFormScreen({super.key, this.produto});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProdutoService _produtoService = ProdutoService.instance;
  final MarcaService _marcaService = MarcaService();
  final CategoriaService _categoriaService = CategoriaService();

  // ── Controllers ────────────────────────────────────────────────────────────
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;
  late TextEditingController _precoPromoController;
  late TextEditingController _estoqueController;

  // ── Estado geral ───────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isSaving = false;
  bool _houveAlteracoes = false;
  bool get _isEditMode => widget.produto != null;

  // ── Marcas e Categorias ────────────────────────────────────────────────────
  List<MarcaModel> _todasMarcas = [];
  List<CategoriaModel> _todasCategorias = [];
  List<MarcaModel> _marcasFiltradas = [];
  List<CategoriaModel> _categoriasFiltradas = [];
  List<int> _marcasSelecionadas = [];
  List<int> _categoriasSelecionadas = [];

  // ── Imagens ────────────────────────────────────────────────────────────────
  List<ProdutoImagemModel> _imagensExistentes = [];
  List<File> _novasImagens = [];
  bool _isLoadingImagens = false;
  bool _isDragging = false;
  final ImagePicker _picker = ImagePicker();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initControllers();
    _carregarDados();
    if (_isEditMode) _carregarImagensExistentes();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _precoPromoController.dispose();
    _estoqueController.dispose();
    super.dispose();
  }

  void _initControllers() {
    _nomeController =
        TextEditingController(text: widget.produto?.nomeProduto ?? '');
    _descricaoController =
        TextEditingController(text: widget.produto?.descricao ?? '');
    _precoController = TextEditingController(
        text: widget.produto?.preco.toStringAsFixed(2) ?? '');
    _precoPromoController = TextEditingController(
        text: widget.produto?.precoPromocional?.toStringAsFixed(2) ?? '');
    _estoqueController = TextEditingController(
        text: widget.produto?.quantidadeEstoque.toString() ?? '0');

    if (_isEditMode) {
      _marcasSelecionadas = List.from(widget.produto?.marcas ?? []);
      _categoriasSelecionadas = List.from(widget.produto?.categorias ?? []);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DADOS (marcas + categorias)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final marcas = await _marcaService.listarMarcasComCategorias();
      final categorias = await _categoriaService.listarCategorias();
      setState(() {
        _todasMarcas = marcas;
        _todasCategorias = categorias;
        _isLoading = false;
      });
      _inicializarFiltros();
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarErro('Erro ao carregar dados: $e');
    }
  }

  void _inicializarFiltros() {
    if (_isEditMode) {
      _aplicarFiltros();
    } else {
      setState(() {
        _marcasFiltradas = List.from(_todasMarcas);
        _categoriasFiltradas = List.from(_todasCategorias);
      });
    }
  }

  void _aplicarFiltros() {
    setState(() {
      if (_marcasSelecionadas.isEmpty && _categoriasSelecionadas.isEmpty) {
        _marcasFiltradas = List.from(_todasMarcas);
        _categoriasFiltradas = List.from(_todasCategorias);
      } else if (_marcasSelecionadas.isNotEmpty &&
          _categoriasSelecionadas.isEmpty) {
        // MarcaModel não tem campo categorias embebido — sem filtragem cruzada.
        // Quando o backend disponibilizar o campo, substituir por
        // _filtrarCategoriasPorMarcas() aqui.
        _marcasFiltradas = List.from(_todasMarcas);
        _categoriasFiltradas = List.from(_todasCategorias);
      } else if (_categoriasSelecionadas.isNotEmpty &&
          _marcasSelecionadas.isEmpty) {
        // Idem para filtragem de marcas por categoria.
        _marcasFiltradas = List.from(_todasMarcas);
        _categoriasFiltradas = List.from(_todasCategorias);
      } else {
        _marcasFiltradas = List.from(_todasMarcas);
        _categoriasFiltradas = List.from(_todasCategorias);
      }
    });
  }

  void _onMarcaSelecionada(int id, bool selecionado) {
    setState(() {
      if (selecionado) {
        if (_marcasSelecionadas.isNotEmpty) return;
        _marcasSelecionadas = [id];
      } else {
        _marcasSelecionadas.clear();
      }
      _aplicarFiltros();
    });
  }

  void _onCategoriaSelecionada(int id, bool selecionado) {
    setState(() {
      if (selecionado) {
        if (_categoriasSelecionadas.isNotEmpty) return;
        _categoriasSelecionadas = [id];
      } else {
        _categoriasSelecionadas.clear();
      }
      _aplicarFiltros();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGENS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _carregarImagensExistentes() async {
    if (widget.produto?.idProduto == null) return;
    setState(() => _isLoadingImagens = true);
    try {
      final imagens =
          await _produtoService.listarImagens(widget.produto!.idProduto);
      setState(() {
        _imagensExistentes = imagens;
        _isLoadingImagens = false;
      });
    } catch (e) {
      setState(() => _isLoadingImagens = false);
      debugPrint('Erro ao carregar imagens: $e');
    }
  }

  Future<void> _selecionarImagem() async {
    try {
      final XFile? img = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85);
      if (img != null) setState(() => _novasImagens.add(File(img.path)));
    } catch (e) {
      _mostrarErro('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _tirarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85);
      if (foto != null) setState(() => _novasImagens.add(File(foto.path)));
    } catch (e) {
      _mostrarErro('Erro ao tirar foto: $e');
    }
  }

  Future<void> _processarArquivosArrastados(List<XFile> files) async {
    final validas = <File>[];
    for (final f in files) {
      final ext = f.path.toLowerCase();
      if (ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.png') ||
          ext.endsWith('.gif') ||
          ext.endsWith('.webp') ||
          ext.endsWith('.jfif')) {
        validas.add(File(f.path));
      }
    }
    if (validas.isEmpty) {
      _mostrarErro('Nenhuma imagem válida. Use JPG, PNG, GIF, JFIF ou WEBP.');
      return;
    }
    setState(() => _novasImagens.addAll(validas));
    _mostrarSucesso('${validas.length} imagem(ns) adicionada(s)');
  }

  void _removerNovaImagem(int index) =>
      setState(() => _novasImagens.removeAt(index));

  Future<void> _removerImagemExistente(ProdutoImagemModel imagem) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('Deseja realmente remover esta imagem?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Remover', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar == true && imagem.idImagem != null) {
      try {
        await _produtoService.removerImagem(imagem.idImagem!);
        setState(() => _imagensExistentes
            .removeWhere((img) => img.idImagem == imagem.idImagem));
        _mostrarSucesso('Imagem removida');
      } catch (e) {
        _mostrarErro('Erro ao remover imagem: $e');
      }
    }
  }

  Future<void> _definirImagemPrincipal(ProdutoImagemModel imagem) async {
    if (widget.produto?.idProduto == null || imagem.idImagem == null) return;
    try {
      await _produtoService.definirImagemPrincipal(
          widget.produto!.idProduto, imagem.idImagem!);
      await _carregarImagensExistentes();
      _mostrarSucesso('Imagem principal definida');
    } catch (e) {
      _mostrarErro('Erro ao definir imagem principal: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SALVAR
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_marcasSelecionadas.isEmpty) {
      _mostrarErro('Selecione pelo menos uma marca');
      return;
    }
    if (_categoriasSelecionadas.isEmpty) {
      _mostrarErro('Selecione pelo menos uma categoria');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final preco = double.parse(
          _precoController.text.trim().replaceAll(',', '.'));
      double? precoPromo;
      if (_precoPromoController.text.trim().isNotEmpty) {
        precoPromo = double.parse(
            _precoPromoController.text.trim().replaceAll(',', '.'));
      }

      final dto = ProdutoRequestModel(
        nomeProduto: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        preco: preco,
        quantidadeEstoque: int.parse(_estoqueController.text.trim()),
        precoPromocional: precoPromo,
        categorias: _categoriasSelecionadas,
        marcas: _marcasSelecionadas,
      );

      ProdutoModel produtoSalvo;
      if (_isEditMode) {
        produtoSalvo =
            await _produtoService.atualizar(widget.produto!.idProduto, dto);
        _mostrarSucesso('Produto atualizado com sucesso');
      } else {
        produtoSalvo = await _produtoService.criar(dto);
        _mostrarSucesso('Produto criado com sucesso');
      }

      // Upload das novas imagens após salvar o produto
      if (_novasImagens.isNotEmpty) {
        for (int i = 0; i < _novasImagens.length; i++) {
          await _produtoService.adicionarImagem(
            idProduto: produtoSalvo.idProduto,
            imagemFile: _novasImagens[i],
            nomeArquivo: _novasImagens[i].path.split('/').last,
            imagemPrincipal: (i == 0 && _imagensExistentes.isEmpty) ? 1 : 0,
          );
        }
      }

      _houveAlteracoes = true;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mostrarErro('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context, _houveAlteracoes);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Editar Produto' : 'Novo Produto'),
          backgroundColor: const Color(0xFF1B2A6B),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _houveAlteracoes),
          ),
        ),
        backgroundColor: const Color(0xFFF4F5F7),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Dados básicos ──────────────────────────────────
                      _buildCardDadosBasicos(),
                      const SizedBox(height: 16),

                      // ── Marcas ────────────────────────────────────────
                      _buildSecaoMarcas(),
                      const SizedBox(height: 16),

                      // ── Categorias ────────────────────────────────────
                      _buildSecaoCategorias(),
                      const SizedBox(height: 16),

                      // ── Imagens ───────────────────────────────────────
                      _buildSecaoImagens(),
                      const SizedBox(height: 24),

                      // ── Botão salvar ──────────────────────────────────
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _salvar,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: Text(
                            _isEditMode
                                ? 'SALVAR ALTERAÇÕES'
                                : 'CRIAR PRODUTO',
                            style: const TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8102E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── Card de dados básicos ────────────────────────────────────────────────
  Widget _buildCardDadosBasicos() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dados do Produto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),

            // Nome
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Produto *',
                prefixIcon: Icon(Icons.inventory_2),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),

            // Preço + Estoque
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precoController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Preço *',
                      prefixText: 'MZN ',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarPreco,
                    enabled: !_isSaving,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _estoqueController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Estoque *',
                      prefixIcon: Icon(Icons.layers),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarEstoque,
                    enabled: !_isSaving,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preço promocional
            TextFormField(
              controller: _precoPromoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Preço Promocional (Opcional)',
                prefixText: 'MZN ',
                prefixIcon:
                    const Icon(Icons.local_offer, color: Colors.orange),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.orange[50],
              ),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) return _validarPreco(v);
                return null;
              },
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descricaoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isSaving,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Marcas ───────────────────────────────────────────────────────────────
  Widget _buildSecaoMarcas() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Marca *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Selecione uma marca. As categorias serão filtradas automaticamente.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_marcasFiltradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Nenhuma marca disponível para as categorias selecionadas',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _marcasFiltradas.map((marca) {
                  final sel = _marcasSelecionadas.contains(marca.id);
                  return FilterChip(
                    label: Text(marca.nomeMarca),
                    selected: sel,
                    onSelected: sel || _marcasSelecionadas.isEmpty
                        ? (v) => _onMarcaSelecionada(marca.id, v)
                        : null,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Categorias ───────────────────────────────────────────────────────────
  Widget _buildSecaoCategorias() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Categoria *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Selecione uma categoria. As marcas serão filtradas automaticamente.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_categoriasFiltradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Nenhuma categoria disponível para as marcas selecionadas',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _categoriasFiltradas.map((cat) {
                  final sel = _categoriasSelecionadas.contains(cat.id);
                  return FilterChip(
                    label: Text(cat.nomeCategoria),
                    selected: sel,
                    onSelected: sel || _categoriasSelecionadas.isEmpty
                        ? (v) => _onCategoriaSelecionada(cat.id, v)
                        : null,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Imagens ──────────────────────────────────────────────────────────────
  Widget _buildSecaoImagens() {
    return DropTarget(
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        await _processarArquivosArrastados(details.files);
      },
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      child: Card(
        elevation: _isDragging ? 8 : 2,
        color: _isDragging ? Colors.blue[50] : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _isDragging
              ? const BorderSide(color: Colors.blue, width: 3)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Imagens do Produto (Opcional)',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _tirarFoto,
                        tooltip: 'Tirar foto',
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library),
                        onPressed: _selecionarImagem,
                        tooltip: 'Escolher da galeria',
                      ),
                    ],
                  ),
                ],
              ),

              // Banner instrução
              if (!_isDragging) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.upload_file,
                          size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Arraste imagens do explorador de arquivos para cá',
                          style: TextStyle(
                              fontSize: 12, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Overlay drag ativo
              if (_isDragging) ...[
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload,
                            size: 48, color: Colors.blue[700]),
                        const SizedBox(height: 8),
                        Text(
                          'Solte as imagens aqui',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Imagens salvas
              if (_isLoadingImagens)
                const Center(child: CircularProgressIndicator())
              else if (_imagensExistentes.isNotEmpty) ...[
                const Text('Imagens salvas:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagensExistentes.length,
                    itemBuilder: (_, i) =>
                        _buildImagemExistente(_imagensExistentes[i]),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Novas imagens
              if (_novasImagens.isNotEmpty) ...[
                const Text('Novas imagens:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _novasImagens.length,
                    itemBuilder: (_, i) =>
                        _buildNovaImagem(_novasImagens[i], i),
                  ),
                ),
              ],

              // Estado vazio
              if (_imagensExistentes.isEmpty &&
                  _novasImagens.isEmpty &&
                  !_isDragging)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Nenhuma imagem adicionada',
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(
                          'Arraste imagens ou clique nos botões acima',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagemExistente(ProdutoImagemModel imagem) {
    final bool isPrincipal = imagem.imagemPrincipal == 1;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: isPrincipal ? Colors.blue : Colors.grey[300]!,
          width: isPrincipal ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              '${ApiConfig.baseUrl}${imagem.caminhoImagem}',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 48),
              ),
            ),
          ),
          if (isPrincipal)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('PRINCIPAL',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (_) => [
                if (!isPrincipal)
                  PopupMenuItem(
                    child: const Text('Definir como principal'),
                    onTap: () => Future.delayed(
                        Duration.zero, () => _definirImagemPrincipal(imagem)),
                  ),
                PopupMenuItem(
                  child: const Text('Remover',
                      style: TextStyle(color: Colors.red)),
                  onTap: () => Future.delayed(
                      Duration.zero, () => _removerImagemExistente(imagem)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNovaImagem(File imagem, int index) {
    final bool isNovaPrincipal = index == 0 && _imagensExistentes.isEmpty;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 120,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(imagem,
                width: 120, height: 120, fit: BoxFit.cover),
          ),
          if (isNovaPrincipal)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('NOVA PRINCIPAL',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removerNovaImagem(index),
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Validadores ──────────────────────────────────────────────────────────
  String? _validarPreco(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obrigatório';
    final p = double.tryParse(v.replaceAll(',', '.'));
    if (p == null || p < 0) return 'Valor inválido';
    return null;
  }

  String? _validarEstoque(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obrigatório';
    final p = int.tryParse(v);
    if (p == null || p < 0) return 'Número inteiro inválido';
    return null;
  }

  // ─── Snackbars ────────────────────────────────────────────────────────────
  void _mostrarSucesso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}