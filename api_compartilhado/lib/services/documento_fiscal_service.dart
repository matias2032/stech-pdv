// lib/services/documento_fiscal_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_compartilhado.dart';
import '../models/documento_fiscal_model.dart';

class DocumentoFiscalService {
  final http.Client _client;

  DocumentoFiscalService({http.Client? client})
      : _client = client ?? http.Client();

  // ─── URL base do módulo ───────────────────────────────────────────────────

  static String get _baseUrl => '${ApiConfig.baseUrl}/api/documentos-fiscais';

  // ─── TIPOS DE DOCUMENTO ───────────────────────────────────────────────────

  /// GET /api/documentos-fiscais/tipos
  Future<List<TipoDocumentoModel>> listarTipos() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/tipos'),
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => TipoDocumentoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/documentos-fiscais/tipos/{id}
  Future<TipoDocumentoModel> buscarTipoPorId(int id) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/tipos/$id'),
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
    return TipoDocumentoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ─── DOCUMENTOS ───────────────────────────────────────────────────────────

  /// GET /api/documentos-fiscais
  Future<List<DocumentoFiscalModel>> listarTodos() async {
    final response = await _client.get(
      Uri.parse(_baseUrl),
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => DocumentoFiscalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/documentos-fiscais/{id}
  Future<DocumentoFiscalModel> buscarPorId(int id) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
    return DocumentoFiscalModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// GET /api/documentos-fiscais/referencia/{referencia}
  Future<DocumentoFiscalModel> buscarPorReferencia(String referencia) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/referencia/$referencia'),
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
    return DocumentoFiscalModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// GET /api/documentos-fiscais/pedido/{idPedido}
  Future<List<DocumentoFiscalModel>> listarPorPedido(int idPedido) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/pedido/$idPedido'),
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => DocumentoFiscalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/documentos-fiscais/tipo/{idTipoDoc}
  Future<List<DocumentoFiscalModel>> listarPorTipo(int idTipoDoc) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/tipo/$idTipoDoc'),
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => DocumentoFiscalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/documentos-fiscais/emitir
  /// [codigoTipo] ex: "FAT","REC", "NCO"
  Future<DocumentoFiscalModel> emitir({
    required int idPedido,
    required String codigoTipo,
    required int idUsuario,
    required String codigoAt,
  }) async {
    final body = jsonEncode({
      'idPedido': idPedido,
      'codigoTipo': codigoTipo,
      'idUsuario': idUsuario,
      'codigoAt': codigoAt,
    });
    final response = await _client.post(
      Uri.parse('$_baseUrl/emitir'),
      headers: ApiConfig.defaultHeaders,
      body: body,
    );
    _checkStatus(response);
    return DocumentoFiscalModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// PATCH /api/documentos-fiscais/{id}/anular
  Future<DocumentoFiscalModel> anular({
    required int id,
    required String motivoAnulacao,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/$id/anular'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({'motivoAnulacao': motivoAnulacao}),
    );
    _checkStatus(response);
    return DocumentoFiscalModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// DELETE /api/documentos-fiscais/{id}
  Future<void> eliminar(int id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
  }

Future<DocumentoFiscalModel> emitirMultiplos({
  required List<int> idsPedido,
  required String codigoTipo,
  required int idUsuario,
  required String codigoAt,
}) async {
  final body = jsonEncode({
    'idsPedido':  idsPedido,
    'codigoTipo': codigoTipo,
    'idUsuario':  idUsuario,
    'codigoAt':   codigoAt,
  });
  final response = await _client.post(
    Uri.parse('$_baseUrl/emitir-multiplos'),
    headers: ApiConfig.defaultHeaders,
    body: body,
  );
  _checkStatus(response);
  return DocumentoFiscalModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>);
}

Future<Map<String, dynamic>> extractoDocumentalCliente(int idCliente) async {
  final response = await _client.get(
    Uri.parse('$_baseUrl/clientes/$idCliente/extracto'),
    headers: ApiConfig.defaultHeaders,
  );
  _checkStatus(response);
  return jsonDecode(response.body) as Map<String, dynamic>;
}

  /// POST /api/documentos-fiscais/{idDocumentoOrigem}/nota-retificativa
  /// [codigoTipo] "NCR" (Nota de Crédito) ou "NDB" (Nota de Débito)
  /// [motivo] ERRO_PREENCHIMENTO | TROCA_PRODUTO | DEVOLUCAO | IVA_INCORRETO | OUTRO
  Future<NotaRetificativaResponseModel> emitirNotaRetificativa({
    required int idDocumentoOrigem,
    required String codigoTipo,
    required int idUsuario,
    required String codigoAt,
    required String motivo,
    required double valor,
    String? observacoes,
  }) async {
    final body = jsonEncode({
      'codigoTipo': codigoTipo,
      'idUsuario': idUsuario,
      'codigoAt': codigoAt,
      'motivo': motivo,
      'valor': valor,
      'observacoes': observacoes,
    });
    final response = await _client.post(
      Uri.parse('$_baseUrl/$idDocumentoOrigem/nota-retificativa'),
      headers: ApiConfig.defaultHeaders,
      body: body,
    );
    _checkStatus(response);
    return NotaRetificativaResponseModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Erro na requisição: ${response.statusCode} — ${response.body}');
    }
  }
}