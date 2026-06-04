import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/produto_model.dart';

/// Espelha ProdutoService + ProdutoController do Java.
///
/// Endpoints cobertos:
///   POST   /api/produtos                              → criar
///   PUT    /api/produtos/{id}                         → atualizar
///   PATCH  /api/produtos/{id}/toggle-ativo            → toggleAtivo
///   GET    /api/produtos                              → listar
///   GET    /api/produtos/ativos                       → listarAtivos
///   GET    /api/produtos/{id}                         → buscarPorId
///   POST   /api/produtos/{id}/categorias/{idCat}      → associarCategoria
///   DELETE /api/produtos/{id}/categorias/{idCat}      → desassociarCategoria
///   GET    /api/produtos/{id}/categorias              → listarCategorias
///   POST   /api/produtos/{id}/marcas/{idMarca}        → associarMarca
///   DELETE /api/produtos/{id}/marcas/{idMarca}        → desassociarMarca
///   GET    /api/produtos/{id}/marcas                  → listarMarcas
///   GET    /api/produtos/marcas/{idMarca}/produtos    → listarProdutosDaMarca
///   POST   /api/produtos/{id}/imagens                 → adicionarImagem (multipart)
///   GET    /api/produtos/{id}/imagens                 → listarImagens
///   PATCH  /api/produtos/{id}/imagens/{idImg}/principal → definirImagemPrincipal
///   DELETE /api/produtos/imagens/{idImagem}           → removerImagem
class ProdutoService {
  ProdutoService._();
  static final ProdutoService instance = ProdutoService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD BÁSICO
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST /api/produtos
  /// Espelha ProdutoService.criar()
  Future<ProdutoModel> criar(ProdutoRequestModel dto) async {
    final url = Uri.parse(ApiConfig.produtosUrl);
    debugPrint('POST $url');

    final response = await http
        .post(url, headers: _headers, body: jsonEncode(dto.toJson()))
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 201, 'criar produto');
    return ProdutoModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// PUT /api/produtos/{id}
  /// Espelha ProdutoService.atualizar()
  Future<ProdutoModel> atualizar(int id, ProdutoRequestModel dto) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/$id');
    debugPrint('PUT $url');

    final response = await http
        .put(url, headers: _headers, body: jsonEncode(dto.toJson()))
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'atualizar produto');
    return ProdutoModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// PATCH /api/produtos/{id}/toggle-ativo
  /// Espelha ProdutoService.toggleAtivo()
  Future<void> toggleAtivo(int id) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/$id/toggle-ativo');
    debugPrint('PATCH $url');

    final response = await http
        .patch(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 204, 'toggleAtivo produto');
  }

  /// GET /api/produtos
  /// Espelha ProdutoService.listar()
  Future<List<ProdutoModel>> listar() async {
    final url = Uri.parse(ApiConfig.produtosUrl);
    debugPrint('GET $url');

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'listar produtos');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ProdutoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/produtos/ativos
  /// Espelha ProdutoService.listarAtivos()
  Future<List<ProdutoModel>> listarAtivos() async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/ativos');
    debugPrint('GET $url');

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'listar produtos ativos');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ProdutoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/produtos/{id}
  /// Espelha ProdutoService.buscarPorId()
  Future<ProdutoModel> buscarPorId(int id) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/$id');
    debugPrint('GET $url');

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'buscar produto por id');
    return ProdutoModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORIAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST /api/produtos/{idProduto}/categorias/{idCategoria}
  /// Espelha ProdutoService.associarCategoria()
  Future<void> associarCategoria(int idProduto, int idCategoria) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/$idProduto/categorias/$idCategoria');
    debugPrint('POST $url');

    final response = await http
        .post(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 201, 'associar categoria ao produto');
  }

  /// DELETE /api/produtos/{idProduto}/categorias/{idCategoria}
  /// Espelha ProdutoService.desassociarCategoria()
  Future<void> desassociarCategoria(int idProduto, int idCategoria) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/$idProduto/categorias/$idCategoria');
    debugPrint('DELETE $url');

    final response = await http
        .delete(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 204, 'desassociar categoria do produto');
  }

  /// GET /api/produtos/{idProduto}/categorias
  /// Espelha ProdutoService.listarCategoriasDoProduto()
  Future<List<int>> listarCategoriasDoProduto(int idProduto) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/$idProduto/categorias');
    debugPrint('GET $url');

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'listar categorias do produto');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => e as int).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MARCAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST /api/produtos/{idProduto}/marcas/{idMarca}
  /// Espelha ProdutoService.associarMarca()
  Future<void> associarMarca(int idProduto, int idMarca) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/$idProduto/marcas/$idMarca');
    debugPrint('POST $url');

    final response = await http
        .post(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 201, 'associar marca ao produto');
  }

  /// DELETE /api/produtos/{idProduto}/marcas/{idMarca}
  /// Espelha ProdutoService.desassociarMarca()
  Future<void> desassociarMarca(int idProduto, int idMarca) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/$idProduto/marcas/$idMarca');
    debugPrint('DELETE $url');

    final response = await http
        .delete(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 204, 'desassociar marca do produto');
  }

  /// GET /api/produtos/{idProduto}/marcas
  /// Espelha ProdutoService.listarMarcasDoProduto()
  Future<List<int>> listarMarcasDoProduto(int idProduto) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/$idProduto/marcas');
    debugPrint('GET $url');

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'listar marcas do produto');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => e as int).toList();
  }

  /// GET /api/produtos/marcas/{idMarca}/produtos
  /// Espelha ProdutoService.listarProdutosDaMarca()
  Future<List<int>> listarProdutosDaMarca(int idMarca) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/marcas/$idMarca/produtos');
    debugPrint('GET $url');

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'listar produtos da marca');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => e as int).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGENS
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST /api/produtos/{idProduto}/imagens   (multipart/form-data)
  /// Espelha ProdutoService.adicionarImagem()
  ///
  /// [imagemFile]     — ficheiro de imagem (Web: não suportado; use [imagemBytes])
  /// [imagemBytes]    — bytes da imagem (útil para Web/Flutter Web)
  /// [nomeArquivo]    — nome original do ficheiro
  /// [legenda]        — legenda opcional
  /// [imagemPrincipal] — 1 = principal, 0 = secundária
  Future<void> adicionarImagem({
    required int idProduto,
    File? imagemFile,
    Uint8List? imagemBytes,
    required String nomeArquivo,
    String? legenda,
    int imagemPrincipal = 0,
  }) async {
    assert(imagemFile != null || imagemBytes != null,
        'Forneça imagemFile ou imagemBytes');

    final url = Uri.parse('${ApiConfig.produtosUrl}/$idProduto/imagens');
    debugPrint('POST (multipart) $url');

    final request = http.MultipartRequest('POST', url);

    if (imagemBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'imagem',
        imagemBytes,
        filename: nomeArquivo,
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'imagem',
        imagemFile!.path,
        filename: nomeArquivo,
      ));
    }

    if (legenda != null) request.fields['legenda'] = legenda;
    request.fields['imagemPrincipal'] = imagemPrincipal.toString();

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);
    _assertStatus(response, 201, 'adicionar imagem ao produto');
  }

  /// GET /api/produtos/{idProduto}/imagens
  /// Espelha ProdutoService.listarImagensDoProduto()
  Future<List<ProdutoImagemModel>> listarImagens(int idProduto) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/$idProduto/imagens');
    debugPrint('GET $url');

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'listar imagens do produto');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ProdutoImagemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /api/produtos/{idProduto}/imagens/{idImagem}/principal
  /// Espelha ProdutoService.alterarImagemPrincipal()
  Future<void> definirImagemPrincipal(int idProduto, int idImagem) async {
    final url = Uri.parse(
        '${ApiConfig.produtosUrl}/$idProduto/imagens/$idImagem/principal');
    debugPrint('PATCH $url');

    final response = await http
        .patch(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 204, 'definir imagem principal');
  }

  /// DELETE /api/produtos/imagens/{idImagem}
  /// Espelha ProdutoService.removerImagem()
  Future<void> removerImagem(int idImagem) async {
    final url = Uri.parse('${ApiConfig.produtosUrl}/imagens/$idImagem');
    debugPrint('DELETE $url');

    final response = await http
        .delete(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 204, 'remover imagem');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, String> get _headers => ApiConfig.defaultHeaders;

  void _assertStatus(http.Response response, int expected, String operacao) {
    if (response.statusCode != expected) {
      debugPrint('❌ $operacao — esperado $expected, recebido ${response.statusCode}');
      debugPrint('   body: ${response.body}');
      throw HttpException(
        'Erro em "$operacao": HTTP ${response.statusCode} — ${response.body}',
      );
    }
  }
}