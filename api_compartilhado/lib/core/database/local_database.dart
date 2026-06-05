// lib/core/database/local_database.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton que inicializa e expõe a instância do SQLite local.
/// Deve ser inicializado no main() antes do runApp().
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _db;

  Database get db {
    if (_db == null) throw StateError('LocalDatabase não inicializado. Chama init() no main().');
    return _db!;
  }

  // ── Inicialização ─────────────────────────────────────────────────

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'stech_pdv.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Adiciona coluna telefone à tabela usuario
    await db.execute(
      'ALTER TABLE usuario ADD COLUMN telefone TEXT',
    );
  }
}
  /// Activa foreign keys no SQLite (desactivadas por defeito).
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ── Criação das tabelas ───────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {

      // ── usuario ───────────────────────────────────────────────────
  await txn.execute('''
  CREATE TABLE usuario (
    id              INTEGER PRIMARY KEY,
    local_id        TEXT UNIQUE,
    nome            TEXT    NOT NULL,
    apelido         TEXT,
    telefone        TEXT,
    email           TEXT    NOT NULL,
    ativo           INTEGER NOT NULL DEFAULT 1,
    id_perfil       INTEGER NOT NULL,
    nome_perfil     TEXT    NOT NULL,
    primeira_senha  INTEGER NOT NULL DEFAULT 1,
    sync_status     TEXT    NOT NULL DEFAULT 'synced',
    updated_at      TEXT
  )
''');

      // ── cliente ───────────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE cliente (
          id            INTEGER PRIMARY KEY,
          local_id      TEXT UNIQUE,
          nome          TEXT,
          apelido       TEXT,
          email         TEXT,
          nuit          TEXT,
          contacto      TEXT,
          morada        TEXT,
          id_perfil     INTEGER NOT NULL,
          nome_perfil   TEXT    NOT NULL,
          sync_status   TEXT    NOT NULL DEFAULT 'synced',
          updated_at    TEXT
        )
      ''');

      // ── produto ───────────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE produto (
          id                  INTEGER PRIMARY KEY,
          local_id            TEXT UNIQUE,
          nome_produto        TEXT    NOT NULL,
          descricao           TEXT,
          preco               REAL    NOT NULL,
          preco_promocional   REAL,
          quantidade_estoque  INTEGER NOT NULL DEFAULT 0,
          ativo               INTEGER NOT NULL DEFAULT 1,
          sync_status         TEXT    NOT NULL DEFAULT 'synced',
          updated_at          TEXT
        )
      ''');

      // ── pedido ────────────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE pedido (
          id                INTEGER PRIMARY KEY,
          local_id          TEXT UNIQUE,
          referencia        TEXT,
          status_pedido     TEXT NOT NULL,
          total             REAL NOT NULL DEFAULT 0,
          valor_pago        REAL,
          troco             REAL,
          observacoes       TEXT,
          id_cliente        INTEGER,
          id_tipo_pagamento INTEGER,
          id_usuario        INTEGER NOT NULL,
          data_pedido       TEXT    NOT NULL,
          data_finalizacao  TEXT,
          sync_status       TEXT    NOT NULL DEFAULT 'synced',
          updated_at        TEXT
        )
      ''');

      // ── item_pedido ───────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE item_pedido (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          local_id        TEXT UNIQUE,
          id_pedido       INTEGER NOT NULL,
          pedido_local_id TEXT,
          id_produto      INTEGER NOT NULL,
          preco_unitario  REAL    NOT NULL,
          quantidade      INTEGER NOT NULL,
          subtotal        REAL    NOT NULL
        )
      ''');

      // ── tipo_pagamento ────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE tipo_pagamento (
          id              INTEGER PRIMARY KEY,
          tipo_pagamento  TEXT NOT NULL
        )
      ''');

      // ── categoria ─────────────────────────────────────────────────
await txn.execute('''
  CREATE TABLE categoria (
    id          INTEGER PRIMARY KEY,
    local_id    TEXT UNIQUE,
    nome        TEXT    NOT NULL,
    descricao   TEXT,
    sync_status TEXT    NOT NULL DEFAULT 'synced',
    updated_at  TEXT
  )
''');

// ── marca ─────────────────────────────────────────────────────
await txn.execute('''
  CREATE TABLE marca (
    id          INTEGER PRIMARY KEY,
    local_id    TEXT UNIQUE,
    nome_marca  TEXT    NOT NULL,
    sync_status TEXT    NOT NULL DEFAULT 'synced',
    updated_at  TEXT
  )
''');

await txn.execute('''
  CREATE TABLE servico (
    id              INTEGER PRIMARY KEY,
    local_id        TEXT UNIQUE,
    nome_servico    TEXT    NOT NULL,
    descricao       TEXT,
    preco_unitario  REAL    NOT NULL,
    unidade         TEXT    NOT NULL DEFAULT 'página',
    ativo           INTEGER NOT NULL DEFAULT 1,
    sync_status     TEXT    NOT NULL DEFAULT 'synced',
    updated_at      TEXT
  )
''');

await txn.execute('''
  CREATE TABLE documento_fiscal (
    id              INTEGER PRIMARY KEY,
    id_tipo_doc     INTEGER NOT NULL,
    tipo_codigo     TEXT    NOT NULL DEFAULT '',
    tipo_nome       TEXT    NOT NULL DEFAULT '',
    tipo_prefixo    TEXT    NOT NULL DEFAULT '',
    id_pedido       INTEGER NOT NULL,
    referencia      TEXT,
    numero_seq      INTEGER,
    ano             INTEGER,
    codigo_at       TEXT,
    id_usuario      INTEGER NOT NULL,
    nome_usuario    TEXT    NOT NULL DEFAULT '',
    emitido_em      TEXT    NOT NULL,
    anulado         INTEGER NOT NULL DEFAULT 0,
    motivo_anulacao TEXT,
    sync_status     TEXT    NOT NULL DEFAULT 'synced',
    updated_at      TEXT
  )
''');


      // ── sync_queue ────────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE sync_queue (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          entidade    TEXT    NOT NULL,
          operacao    TEXT    NOT NULL,
          payload     TEXT    NOT NULL,
          tentativas  INTEGER NOT NULL DEFAULT 0,
          criado_em   TEXT    NOT NULL
        )
      ''');

      // ── índices para performance ──────────────────────────────────
      await txn.execute('CREATE INDEX idx_usuario_sync   ON usuario(sync_status)');
      await txn.execute('CREATE INDEX idx_cliente_sync   ON cliente(sync_status)');
      await txn.execute('CREATE INDEX idx_produto_sync   ON produto(sync_status)');
      await txn.execute('CREATE INDEX idx_pedido_sync    ON pedido(sync_status)');
      await txn.execute('CREATE INDEX idx_pedido_status  ON pedido(status_pedido)');
      await txn.execute('CREATE INDEX idx_item_pedido    ON item_pedido(id_pedido)');
      await txn.execute('CREATE INDEX idx_categoria_sync ON categoria(sync_status)');
      await txn.execute('CREATE INDEX idx_marca_sync     ON marca(sync_status)');
      await txn.execute('CREATE INDEX idx_servico_sync ON servico(sync_status)');
      await txn.execute('CREATE INDEX idx_documento_fiscal_sync ON documento_fiscal(sync_status)');
await txn.execute('CREATE INDEX idx_documento_fiscal_pedido ON documento_fiscal(id_pedido)');
      await txn.execute('CREATE INDEX idx_sync_queue     ON sync_queue(tentativas)');

    });
  }

  // ── Utilitários ───────────────────────────────────────────────────

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Limpa todos os dados locais (útil para logout ou reset).
  Future<void> clearAll() async {
    await db.transaction((txn) async {
      await txn.delete('item_pedido');
      await txn.delete('pedido');
      await txn.delete('cliente');
      await txn.delete('produto');
      await txn.delete('usuario');
      await txn.delete('tipo_pagamento');
      await txn.delete('sync_queue');
      await txn.delete('marca');
      await txn.delete('categoria');
      await txn.delete('servico');
      await txn.delete('documento_fiscal');
    });
  }
}