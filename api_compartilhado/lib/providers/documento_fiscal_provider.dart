// lib/providers/documento_fiscal_provider.dart

import 'package:flutter/foundation.dart';
import '../models/documento_fiscal_model.dart';
import '../services/documento_fiscal_service.dart';

class DocumentoFiscalProvider extends ChangeNotifier {
  final DocumentoFiscalService _service;

  DocumentoFiscalProvider({DocumentoFiscalService? service})
      : _service = service ?? DocumentoFiscalService();

  // ─── Estado ───────────────────────────────────────────────────────────────

  List<DocumentoFiscalModel> _documentos = [];
  List<TipoDocumentoModel> _tipos = [];
  bool _carregando = false;
  bool _emitindo = false;
  String? _erro;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<DocumentoFiscalModel> get documentos => List.unmodifiable(_documentos);
  List<TipoDocumentoModel> get tipos => List.unmodifiable(_tipos);
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

  Future<void> carregarTipos() async {
    _setCarregando(true);
    _erro = null;
    try {
      _tipos = await _service.listarTipos();
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
      _documentos = await _service.listarTodos();
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
      _documentos = await _service.listarPorPedido(idPedido);
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
      _documentos = await _service.listarPorTipo(idTipoDoc);
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    } finally {
      _setCarregando(false);
    }
  }

  // ─── BUSCA INDIVIDUAL ────────────────────────────────────────────────────

  Future<DocumentoFiscalModel?> buscarPorId(int id) async {
    _erro = null;
    try {
      return await _service.buscarPorId(id);
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<DocumentoFiscalModel?> buscarPorReferencia(String referencia) async {
    _erro = null;
    try {
      return await _service.buscarPorReferencia(referencia);
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ─── EMITIR ───────────────────────────────────────────────────────────────

  Future<DocumentoFiscalModel?> emitir({
    required int idPedido,
    required String codigoTipo,
    required int idUsuario,
    required String codigoAt,
  }) async {
    _emitindo = true;
    _erro = null;
    notifyListeners();
    try {
      final novo = await _service.emitir(
        idPedido: idPedido,
        codigoTipo: codigoTipo,
        idUsuario: idUsuario,
        codigoAt: codigoAt,
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
    required int id,
    required String motivoAnulacao,
  }) async {
    _erro = null;
    try {
      final atualizado = await _service.anular(
        id: id,
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
      await _service.eliminar(id);
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
  required String codigoTipo,
  required int idUsuario,
  required String codigoAt,
}) async {
  try {
    _carregando = true;
    notifyListeners();

    final doc = await _service.emitirMultiplos(
      idsPedido:  idsPedido,
      codigoTipo: codigoTipo,
      idUsuario:  idUsuario,
      codigoAt:   codigoAt,
    );

    // Adiciona à lista local se existir
    _documentos.add(doc);
    notifyListeners();
    return doc;
  } catch (e) {
    _erro = e.toString();
    notifyListeners();
    return null;
  } finally {
    _carregando = false;
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