// lib/providers/documento_fiscal_provider.dart

import 'package:flutter/foundation.dart';
import '../models/documento_fiscal_model.dart';
import '../repository/documento_fiscal_repository.dart';

class DocumentoFiscalProvider extends ChangeNotifier {
  final DocumentoFiscalRepository _repository;

  DocumentoFiscalProvider({required DocumentoFiscalRepository repository})
      : _repository = repository;

  // ─── Estado ───────────────────────────────────────────────────────────────

  List<DocumentoFiscalModel> _documentos = [];
  List<TipoDocumentoModel> _tipos = [];
  Map<String, dynamic> _extractoDocumentalCliente = {};
  bool _carregando = false;
  bool _emitindo = false;
  String? _erro;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<DocumentoFiscalModel> get documentos => List.unmodifiable(_documentos);
  List<TipoDocumentoModel> get tipos => List.unmodifiable(_tipos);
  Map<String, dynamic> get extractoDocumentalCliente =>
    Map.unmodifiable(_extractoDocumentalCliente);
  bool get carregando => _carregando;
  bool get emitindo => _emitindo;
  String? get erro => _erro;

  /// Documentos activos (não anulados)
  List<DocumentoFiscalModel> get documentosActivos =>
      _documentos.where((d) => !d.anulado).toList();

  /// Documentos anulados
  List<DocumentoFiscalModel> get documentosAnulados =>
      _documentos.where((d) => d.anulado).toList();

  // ─── TIPOS ────────────────────────────────────────────────────────────────

// SUBSTITUIR: carregarTipos

  Future<void> carregarTipos() async {
    _setCarregando(true);
    _erro = null;
    try {
      _tipos = await _repository.listarTipos();
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    } finally {
      _setCarregando(false);
    }
  }

  // ─── LISTAGEM ─────────────────────────────────────────────────────────────

  Future<void> carregarTodos() async {
    _setCarregando(true);
    _erro = null;
    try {
final lista = await _repository.listarTodos();

_documentos = lista
    .where((d) => d.tipoVenda == 'IMEDIATA')
    .toList();
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    } finally {
      _setCarregando(false);
    }
  }

  Future<void> carregarPorPedido(int idPedido) async {
    _setCarregando(true);
    _erro = null;
    try {
      _documentos = await _repository.listarPorPedido(idPedido);
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    } finally {
      _setCarregando(false);
    }
  }

  Future<void> carregarPorTipo(int idTipoDoc) async {
    _setCarregando(true);
    _erro = null;
    try {
      _documentos = await _repository.listarPorTipo(idTipoDoc);
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    } finally {
      _setCarregando(false);
    }
  }

// ─── BUSCA INDIVIDUAL ────────────────────────────────────────────────────

  /// Busca os documentos de um pedido SEM alterar o estado `_documentos`
  /// (usado para localizar a FAT/VD de origem de uma NCR/NDB a partir da
  /// listagem geral, onde `_documentos` já está a mostrar outra coisa).
  Future<List<DocumentoFiscalModel>> buscarDocumentosPorPedido(
      int idPedido) async {
    try {
      return await _repository.listarPorPedido(idPedido);
    } catch (e) {
      debugPrint('⚠️ buscarDocumentosPorPedido falhou: $e');
      return [];
    }
  }

  Future<DocumentoFiscalModel?> buscarPorId(int id) async {
    _erro = null;
    try {
      return await _repository.buscarPorId(id);
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<DocumentoFiscalModel?> buscarPorReferencia(String referencia) async {
    _erro = null;
    try {
      return await _repository.buscarPorReferencia(referencia);
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ─── EMITIR ───────────────────────────────────────────────────────────────

// SUBSTITUIR: emitir

  Future<DocumentoFiscalModel?> emitir({
    required int    idPedido,
    required String codigoTipo,
    required int    idUsuario,
    required String codigoAt,
  }) async {
    _emitindo = true;
    _erro = null;
    notifyListeners();
    try {
      final novo = await _repository.emitir(
        idPedido:   idPedido,
        codigoTipo: codigoTipo,
        idUsuario:  idUsuario,
        codigoAt:   codigoAt,
      );
      _documentos.add(novo);
      notifyListeners();
      return novo;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _emitindo = false;
      notifyListeners();
    }
  }

  // ─── ANULAR ───────────────────────────────────────────────────────────────

  Future<DocumentoFiscalModel?> anular({
    required int    id,
    required String motivoAnulacao,
  }) async {
    _erro = null;
    try {
      final atualizado = await _repository.anular(
        id:             id,
        motivoAnulacao: motivoAnulacao,
      );
      final idx = _documentos.indexWhere((d) => d.id == id);
      if (idx != -1) {
        _documentos[idx] = atualizado;
        notifyListeners();
      }
      return atualizado;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ─── ELIMINAR ─────────────────────────────────────────────────────────────

  Future<void> eliminar(int id) async {
    _erro = null;
    try {
      await _repository.eliminar(id);
      _documentos.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Em DocumentoFiscalProvider — adicionar:

 Future<DocumentoFiscalModel?> emitirMultiplos({
    required List<int> idsPedido,
    required String    codigoTipo,
    required int       idUsuario,
    required String    codigoAt,
  }) async {
    _emitindo = true;
    _erro = null;
    notifyListeners();
    try {
      final doc = await _repository.emitirMultiplos(
        idsPedido:  idsPedido,
        codigoTipo: codigoTipo,
        idUsuario:  idUsuario,
        codigoAt:   codigoAt,
      );
      _documentos.add(doc);
      notifyListeners();
      return doc;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return null;
    } finally {
      _emitindo = false;
      notifyListeners();
    }
  }

  Future<void> carregarExtractoDocumentalCliente(int idCliente) async {
  _setCarregando(true);
  _erro = null;
  try {
    _extractoDocumentalCliente =
        await _repository.extractoDocumentalCliente(idCliente);
    notifyListeners();
  } catch (e) {
    _erro = e.toString();
    notifyListeners();
  } finally {
    _setCarregando(false);
  }
}

  // ─── NOTA DE CRÉDITO / DÉBITO ──────────────────────────────────────────────

  Future<NotaRetificativaResponseModel?> emitirNotaRetificativa({
    required int    idDocumentoOrigem,
    required String codigoTipo,
    required int    idUsuario,
    required String codigoAt,
    required String motivo,
    required double valor,
    String? observacoes,
  }) async {
    _emitindo = true;
    _erro = null;
    notifyListeners();
    try {
      final resposta = await _repository.emitirNotaRetificativa(
        idDocumentoOrigem: idDocumentoOrigem,
        codigoTipo:        codigoTipo,
        idUsuario:         idUsuario,
        codigoAt:          codigoAt,
        motivo:            motivo,
        valor:             valor,
        observacoes:       observacoes,
      );
      _documentos.add(resposta.documento);
      notifyListeners();
      return resposta;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _emitindo = false;
      notifyListeners();
    }
  }


  // ─── Helper ───────────────────────────────────────────────────────────────

  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  void _setCarregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }
}