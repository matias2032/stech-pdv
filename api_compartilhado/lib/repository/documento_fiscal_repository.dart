// lib/repository/documento_fiscal_repository.dart

import 'package:flutter/foundation.dart';

import 'package:api_compartilhado/api_compartilhado.dart';
import '../core/database/daos/documento_fiscal_dao.dart';
import '../core/connectivity/connectivity_service.dart';
import '../services/documento_fiscal_service.dart';
import 'dart:convert'; // ← faltava

import '../core/database/daos/sync_queue_dao.dart'; // ← faltava

class DocumentoFiscalRepository {
  DocumentoFiscalRepository({
    required DocumentoFiscalService  service,
    required DocumentoFiscalDao      dao,
    required ConnectivityService     connectivity,
    required SyncQueueDao            syncQueueDao, // ← adicionar
  })  : _service      = service,
        _dao          = dao,
        _connectivity = connectivity,
        _syncQueueDao = syncQueueDao; // ← adicionar

  final DocumentoFiscalService  _service;
  final DocumentoFiscalDao      _dao;
  final ConnectivityService     _connectivity;
  final SyncQueueDao            _syncQueueDao; // ← adicionar

  // ── Leitura ───────────────────────────────────────────────────────

  Future<List<TipoDocumentoModel>> listarTipos() async {
    // tipos são simples — sem cache dedicado, sempre online
    if (_connectivity.isOffline) {
      throw Exception('Sem ligação — tipos de documento requerem internet.');
    }
    return _service.listarTipos();
  }

  Future<TipoDocumentoModel> buscarTipoPorId(int id) async {
    _requireOnline('buscar tipo de documento');
    return _service.buscarTipoPorId(id);
  }

  Future<List<DocumentoFiscalModel>> listarTodos() async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarTodos();
        await _dao.upsertAll(lista.map((d) => d.toLocalDb()).toList());
        return lista;
      } catch (e) {
        debugPrint(
            '⚠️ DocumentoFiscalRepository.listarTodos HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getAll();
    return rows.map(DocumentoFiscalModel.fromLocalDb).toList();
  }

  Future<List<DocumentoFiscalModel>> listarPorPedido(int idPedido) async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarPorPedido(idPedido);
        await _dao.upsertAll(lista.map((d) => d.toLocalDb()).toList());
        return lista;
      } catch (e) {
        debugPrint(
            '⚠️ DocumentoFiscalRepository.listarPorPedido HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getByPedido(idPedido);
    return rows.map(DocumentoFiscalModel.fromLocalDb).toList();
  }

  Future<List<DocumentoFiscalModel>> listarPorTipo(int idTipoDoc) async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarPorTipo(idTipoDoc);
        await _dao.upsertAll(lista.map((d) => d.toLocalDb()).toList());
        return lista;
      } catch (e) {
        debugPrint(
            '⚠️ DocumentoFiscalRepository.listarPorTipo HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getByTipo(idTipoDoc);
    return rows.map(DocumentoFiscalModel.fromLocalDb).toList();
  }

  Future<DocumentoFiscalModel?> buscarPorId(int id) async {
    if (_connectivity.isOnline) {
      try {
        final doc = await _service.buscarPorId(id);
        await _dao.upsert(doc.toLocalDb());
        return doc;
      } catch (e) {
        debugPrint(
            '⚠️ DocumentoFiscalRepository.buscarPorId HTTP falhou — usando cache: $e');
      }
    }
    final row = await _dao.getById(id);
    return row == null ? null : DocumentoFiscalModel.fromLocalDb(row);
  }

  Future<DocumentoFiscalModel?> buscarPorReferencia(String referencia) async {
    if (_connectivity.isOnline) {
      try {
        final doc = await _service.buscarPorReferencia(referencia);
        await _dao.upsert(doc.toLocalDb());
        return doc;
      } catch (e) {
        debugPrint(
            '⚠️ DocumentoFiscalRepository.buscarPorReferencia HTTP falhou — usando cache: $e');
      }
    }
    final row = await _dao.getByReferencia(referencia);
    return row == null ? null : DocumentoFiscalModel.fromLocalDb(row);
  }

  // ── Escrita — todas requerem ligação ──────────────────────────────

  Future<DocumentoFiscalModel> emitir({
    required int    idPedido,
    required String codigoTipo,
    required int    idUsuario,
    required String codigoAt,
  }) async {
    _requireOnline('emitir documento fiscal');
    final doc = await _service.emitir(
      idPedido:   idPedido,
      codigoTipo: codigoTipo,
      idUsuario:  idUsuario,
      codigoAt:   codigoAt,
    );
    await _dao.upsert(doc.toLocalDb());
    return doc;
  }

  Future<DocumentoFiscalModel> emitirMultiplos({
    required List<int> idsPedido,
    required String    codigoTipo,
    required int       idUsuario,
    required String    codigoAt,
  }) async {
    _requireOnline('emitir documento fiscal múltiplo');
    final doc = await _service.emitirMultiplos(
      idsPedido:  idsPedido,
      codigoTipo: codigoTipo,
      idUsuario:  idUsuario,
      codigoAt:   codigoAt,
    );
    await _dao.upsert(doc.toLocalDb());
    return doc;
  }

Future<DocumentoFiscalModel> anular({
  required int    id,
  required String motivoAnulacao,
}) async {
  if (_connectivity.isOnline) {
    final doc = await _service.anular(id: id, motivoAnulacao: motivoAnulacao);
    await _dao.upsert(doc.toLocalDb());
    return doc;
  }

  // Offline: aplicar localmente e enfileirar
  final row = await _dao.getById(id);
  if (row == null) throw Exception('Documento $id não encontrado localmente.');

  final docAnulado = DocumentoFiscalModel.fromLocalDb(row).copyWith(
    anulado:        true,
    motivoAnulacao: motivoAnulacao,
  );
  await _dao.upsert(docAnulado.toLocalDb()
    ..['sync_status'] = 'pending');

await _syncQueueDao.enqueue(
  'documento_fiscal',
  'ANULAR',
  {'id': id, 'motivoAnulacao': motivoAnulacao}, // ← Map directo, sem jsonEncode
);

  return docAnulado;
}


  Future<void> eliminar(int id) async {
    _requireOnline('eliminar documento fiscal');
    await _service.eliminar(id);
    await _dao.delete(id);
  }


Future<Map<String, dynamic>> extractoDocumentalCliente(int idCliente) async {
  if (_connectivity.isOnline) {
    try {
      return await _service.extractoDocumentalCliente(idCliente);
    } catch (e) {
      debugPrint(
        '⚠️ DocumentoFiscalRepository.extractoDocumentalCliente falhou: $e',
      );
      rethrow; // extracto documental não tem fallback offline útil
    }
  }
  throw Exception(
    'Sem ligação — extracto documental requer internet.',
  );
}
  // ── Guard offline ─────────────────────────────────────────────────

  void _requireOnline(String operacao) {
    if (_connectivity.isOffline) {
      throw Exception('Sem ligação — "$operacao" requer internet.');
    }
  }
}