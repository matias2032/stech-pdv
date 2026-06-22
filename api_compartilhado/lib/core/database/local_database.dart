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
  version: 11,       
  onCreate:    _onCreate,
  onUpgrade:   _onUpgrade,
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

  if (oldVersion < 3) {
    await db.execute('DROP TABLE IF EXISTS categoria');
    await db.execute('''
      CREATE TABLE categoria (
        id             INTEGER PRIMARY KEY,
        local_id       TEXT UNIQUE,
        nome_categoria TEXT    NOT NULL DEFAULT '',
        descricao      TEXT,
        sync_status    TEXT    NOT NULL DEFAULT 'synced',
        updated_at     TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_categoria_sync ON categoria(sync_status)');
  }

  if (oldVersion < 4) {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS item_pedido_servico (
      id              INTEGER PRIMARY KEY,
      id_pedido       INTEGER NOT NULL,
      id_servico      INTEGER NOT NULL,
      preco_unitario  REAL    NOT NULL DEFAULT 0,
      quantidade      INTEGER NOT NULL DEFAULT 1,
      subtotal        REAL    NOT NULL DEFAULT 0,
      observacoes     TEXT
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_item_pedido_servico ON item_pedido_servico(id_pedido)'
  );
}

if (oldVersion < 5) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cotacao (
        id                            INTEGER PRIMARY KEY,
        local_id                      TEXT UNIQUE,
        referencia                    TEXT,
        id_cliente                    INTEGER,
        nome_cliente                  TEXT,
        id_usuario                    INTEGER NOT NULL,
        nome_usuario                  TEXT,
        status_cotacao                TEXT    NOT NULL DEFAULT 'ABERTA',
        total                         REAL    NOT NULL DEFAULT 0,
        validade_ate                  TEXT,
        observacoes                   TEXT,
        id_pedido_convertido          INTEGER,
        referencia_pedido_convertido  TEXT,
        created_at                    TEXT,
        deleted                       INTEGER NOT NULL DEFAULT 0,
        sync_status                   TEXT    NOT NULL DEFAULT 'synced',
        updated_at                    TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cotacao_item_produto (
        id              INTEGER PRIMARY KEY,
        id_cotacao      INTEGER NOT NULL,
        id_produto      INTEGER NOT NULL,
        nome_produto    TEXT,
        preco_unitario  REAL    NOT NULL DEFAULT 0,
        quantidade      INTEGER NOT NULL DEFAULT 1,
        subtotal        REAL    NOT NULL DEFAULT 0,
        observacoes     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cotacao_item_servico (
        id              INTEGER PRIMARY KEY,
        id_cotacao      INTEGER NOT NULL,
        id_servico      INTEGER NOT NULL,
        nome_servico    TEXT,
        preco_unitario  REAL    NOT NULL DEFAULT 0,
        quantidade      INTEGER NOT NULL DEFAULT 1,
        subtotal        REAL    NOT NULL DEFAULT 0,
        observacoes     TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cotacao_sync ON cotacao(sync_status)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cotacao_status ON cotacao(status_cotacao)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cotacao_item_produto ON cotacao_item_produto(id_cotacao)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cotacao_item_servico ON cotacao_item_servico(id_cotacao)');
  }

  if (oldVersion < 6) {
  // ── Campos de crédito em pedido ─────────────────────────────
  await db.execute(
    "ALTER TABLE pedido ADD COLUMN tipo_venda TEXT NOT NULL DEFAULT 'IMEDIATA'",
  );

  await db.execute(
    'ALTER TABLE pedido ADD COLUMN modalidade_credito TEXT',
  );

  await db.execute(
    "ALTER TABLE pedido ADD COLUMN status_pagamento TEXT NOT NULL DEFAULT 'PENDENTE'",
  );

  await db.execute(
    'ALTER TABLE pedido ADD COLUMN id_documento_factura_credito INTEGER',
  );

  await db.execute(
    'ALTER TABLE pedido ADD COLUMN data_abertura_credito TEXT',
  );

  await db.execute(
    'ALTER TABLE pedido ADD COLUMN data_vencimento_credito TEXT',
  );

  await db.execute(
    'ALTER TABLE pedido ADD COLUMN data_liquidacao_credito TEXT',
  );

  await db.execute(
    'ALTER TABLE pedido ADD COLUMN observacoes_credito TEXT',
  );

  await db.execute(
    'ALTER TABLE pedido ADD COLUMN saldo_devedor_credito REAL',
  );

  // ── Parcelas de crédito ─────────────────────────────────────
  await db.execute('''
    CREATE TABLE IF NOT EXISTS pedido_credito_parcela (
      id               INTEGER PRIMARY KEY,
      id_pedido        INTEGER NOT NULL,
      numero_parcela   INTEGER NOT NULL,
      valor_parcela    REAL    NOT NULL DEFAULT 0,
      valor_pago       REAL    NOT NULL DEFAULT 0,
      saldo_parcela    REAL,
      data_vencimento  TEXT    NOT NULL,
      data_pagamento   TEXT,
      status_parcela   TEXT    NOT NULL DEFAULT 'PENDENTE',
      observacoes      TEXT,
      deleted          INTEGER NOT NULL DEFAULT 0,
      sync_status      TEXT    NOT NULL DEFAULT 'synced',
      updated_at       TEXT
    )
  ''');

  // ── Pagamentos de crédito ───────────────────────────────────
  await db.execute('''
    CREATE TABLE IF NOT EXISTS pedido_credito_pagamento (
      id                    INTEGER PRIMARY KEY,
      referencia            TEXT,
      id_pedido             INTEGER NOT NULL,
      id_parcela            INTEGER,
      id_tipo_pagamento     INTEGER NOT NULL,
      id_usuario            INTEGER NOT NULL,
      id_documento_recibo   INTEGER,
      valor_pago            REAL    NOT NULL DEFAULT 0,
      data_pagamento        TEXT    NOT NULL,
      observacoes           TEXT,
      deleted               INTEGER NOT NULL DEFAULT 0,
      sync_status           TEXT    NOT NULL DEFAULT 'synced',
      updated_at            TEXT
    )
  ''');

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_pedido_credito_parcela_pedido '
    'ON pedido_credito_parcela(id_pedido)',
  );

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_pedido_credito_pagamento_pedido '
    'ON pedido_credito_pagamento(id_pedido)',
  );

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_pedido_credito_parcela_sync '
    'ON pedido_credito_parcela(sync_status)',
  );

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_pedido_credito_pagamento_sync '
    'ON pedido_credito_pagamento(sync_status)',
  );
}

if (oldVersion < 7) {
  await db.execute(
    "ALTER TABLE pedido "
    "ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0"
  );
}

if (oldVersion < 8) {
  await db.execute(
    'ALTER TABLE pedido ADD COLUMN nome_cliente_singular TEXT',
  );
  await db.execute(
    'ALTER TABLE pedido ADD COLUMN apelido_cliente_singular TEXT',
  );
}
if (oldVersion < 9) {
  await db.execute(
    'ALTER TABLE cotacao ADD COLUMN nome_cliente_singular TEXT',
  );
  await db.execute(
    'ALTER TABLE cotacao ADD COLUMN apelido_cliente_singular TEXT',
  );
}

if (oldVersion < 10) {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS fornecedor (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT,
      email TEXT,
      nuit TEXT,
      contacto TEXT NOT NULL UNIQUE,
      morada TEXT,
      deleted INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT
    )
  ''');
}
if (oldVersion < 11) {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS despesa (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      id_fornecedor INTEGER,
      nome_fornecedor TEXT,
      nuit_fornecedor TEXT,
      descricao TEXT NOT NULL,
      valor_gasto REAL NOT NULL DEFAULT 0,
      data_despesa TEXT NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0,
      sync_status TEXT NOT NULL DEFAULT 'synced',
      updated_at TEXT
    )
  ''');

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_despesa_fornecedor ON despesa(id_fornecedor)',
  );

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_despesa_data ON despesa(data_despesa)',
  );

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_despesa_sync ON despesa(sync_status)',
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

      await db.execute('''
  CREATE TABLE IF NOT EXISTS fornecedor (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT,
    email TEXT,
    nuit TEXT,
    contacto TEXT NOT NULL UNIQUE,
    morada TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT
  )
''');

await txn.execute('''
  CREATE TABLE IF NOT EXISTS despesa (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_fornecedor INTEGER,
    nome_fornecedor TEXT,
    nuit_fornecedor TEXT,
    descricao TEXT NOT NULL,
    valor_gasto REAL NOT NULL DEFAULT 0,
    data_despesa TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    updated_at TEXT
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
    id                              INTEGER PRIMARY KEY,
    local_id                        TEXT UNIQUE,
    referencia                      TEXT,
    status_pedido                   TEXT NOT NULL,
    total                           REAL NOT NULL DEFAULT 0,
    valor_pago                      REAL,
    troco                           REAL,
    observacoes                     TEXT,
    id_cliente                      INTEGER,
    nome_cliente_singular           TEXT,
    apelido_cliente_singular        TEXT,
    id_tipo_pagamento               INTEGER,
    id_usuario                      INTEGER NOT NULL,
    data_pedido                     TEXT NOT NULL,
    data_finalizacao                TEXT,

    tipo_venda                      TEXT NOT NULL DEFAULT 'IMEDIATA',
    modalidade_credito              TEXT,
    status_pagamento                TEXT NOT NULL DEFAULT 'PENDENTE',
    id_documento_factura_credito    INTEGER,
    data_abertura_credito           TEXT,
    data_vencimento_credito         TEXT,
    data_liquidacao_credito         TEXT,
    observacoes_credito             TEXT,
    saldo_devedor_credito           REAL,
    deleted INTEGER NOT NULL DEFAULT 0,

    sync_status                     TEXT NOT NULL DEFAULT 'synced',
    updated_at                      TEXT
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

      await txn.execute('''
  CREATE TABLE IF NOT EXISTS item_pedido_servico (
    id              INTEGER PRIMARY KEY,
    id_pedido       INTEGER NOT NULL,
    id_servico      INTEGER NOT NULL,
    preco_unitario  REAL    NOT NULL DEFAULT 0,
    quantidade      INTEGER NOT NULL DEFAULT 1,
    subtotal        REAL    NOT NULL DEFAULT 0,
    observacoes     TEXT
  )
''');

await txn.execute('''
  CREATE TABLE pedido_credito_parcela (
    id               INTEGER PRIMARY KEY,
    id_pedido        INTEGER NOT NULL,
    numero_parcela   INTEGER NOT NULL,
    valor_parcela    REAL    NOT NULL DEFAULT 0,
    valor_pago       REAL    NOT NULL DEFAULT 0,
    saldo_parcela    REAL,
    data_vencimento  TEXT    NOT NULL,
    data_pagamento   TEXT,
    status_parcela   TEXT    NOT NULL DEFAULT 'PENDENTE',
    observacoes      TEXT,
    deleted          INTEGER NOT NULL DEFAULT 0,
    sync_status      TEXT    NOT NULL DEFAULT 'synced',
    updated_at       TEXT
  )
''');

await txn.execute('''
  CREATE TABLE pedido_credito_pagamento (
    id                    INTEGER PRIMARY KEY,
    referencia            TEXT,
    id_pedido             INTEGER NOT NULL,
    id_parcela            INTEGER,
    id_tipo_pagamento     INTEGER NOT NULL,
    id_usuario            INTEGER NOT NULL,
    id_documento_recibo   INTEGER,
    valor_pago            REAL    NOT NULL DEFAULT 0,
    data_pagamento        TEXT    NOT NULL,
    observacoes           TEXT,
    deleted               INTEGER NOT NULL DEFAULT 0,
    sync_status           TEXT    NOT NULL DEFAULT 'synced',
    updated_at            TEXT
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
    id             INTEGER PRIMARY KEY,
    local_id       TEXT UNIQUE,
    nome_categoria TEXT    NOT NULL DEFAULT '',
    descricao      TEXT,
    sync_status    TEXT    NOT NULL DEFAULT 'synced',
    updated_at     TEXT
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

await txn.execute('''
  CREATE TABLE cotacao (
    id                            INTEGER PRIMARY KEY,
    local_id                      TEXT UNIQUE,
    referencia                    TEXT,
    id_cliente                    INTEGER,
    nome_cliente                  TEXT,
    nome_cliente_singular         TEXT,
    apelido_cliente_singular      TEXT,
    id_usuario                    INTEGER NOT NULL,
    nome_usuario                  TEXT,
    status_cotacao                TEXT    NOT NULL DEFAULT 'ABERTA',
    total                         REAL    NOT NULL DEFAULT 0,
    validade_ate                  TEXT,
    observacoes                   TEXT,
    id_pedido_convertido          INTEGER,
    referencia_pedido_convertido  TEXT,
    created_at                    TEXT,
    deleted                       INTEGER NOT NULL DEFAULT 0,
    sync_status                   TEXT    NOT NULL DEFAULT 'synced',
    updated_at                    TEXT
  )
''');

await txn.execute('''
  CREATE TABLE cotacao_item_produto (
    id              INTEGER PRIMARY KEY,
    id_cotacao      INTEGER NOT NULL,
    id_produto      INTEGER NOT NULL,
    nome_produto    TEXT,
    preco_unitario  REAL    NOT NULL DEFAULT 0,
    quantidade      INTEGER NOT NULL DEFAULT 1,
    subtotal        REAL    NOT NULL DEFAULT 0,
    observacoes     TEXT
  )
''');

await txn.execute('''
  CREATE TABLE cotacao_item_servico (
    id              INTEGER PRIMARY KEY,
    id_cotacao      INTEGER NOT NULL,
    id_servico      INTEGER NOT NULL,
    nome_servico    TEXT,
    preco_unitario  REAL    NOT NULL DEFAULT 0,
    quantidade      INTEGER NOT NULL DEFAULT 1,
    subtotal        REAL    NOT NULL DEFAULT 0,
    observacoes     TEXT
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
      await txn.execute(
  'CREATE INDEX idx_pedido_tipo_venda ON pedido(tipo_venda)',
);

await txn.execute(
  'CREATE INDEX idx_pedido_status_pagamento ON pedido(status_pagamento)',
);

await txn.execute(
  'CREATE INDEX idx_pedido_credito_parcela_pedido '
  'ON pedido_credito_parcela(id_pedido)',
);

await txn.execute(
  'CREATE INDEX idx_pedido_credito_pagamento_pedido '
  'ON pedido_credito_pagamento(id_pedido)',
);

await txn.execute(
  'CREATE INDEX idx_pedido_credito_parcela_sync '
  'ON pedido_credito_parcela(sync_status)',
);

await txn.execute(
  'CREATE INDEX idx_pedido_credito_pagamento_sync '
  'ON pedido_credito_pagamento(sync_status)',
);
      await txn.execute('CREATE INDEX idx_item_pedido    ON item_pedido(id_pedido)');
      await txn.execute('CREATE INDEX idx_item_pedido_servico ON item_pedido_servico(id_pedido)');
      await txn.execute('CREATE INDEX idx_categoria_sync ON categoria(sync_status)');
      await txn.execute('CREATE INDEX idx_marca_sync     ON marca(sync_status)');
      await txn.execute('CREATE INDEX idx_servico_sync ON servico(sync_status)');
      await txn.execute('CREATE INDEX idx_documento_fiscal_sync ON documento_fiscal(sync_status)');
await txn.execute('CREATE INDEX idx_documento_fiscal_pedido ON documento_fiscal(id_pedido)');
await txn.execute('CREATE INDEX idx_cotacao_sync   ON cotacao(sync_status)');
await txn.execute('CREATE INDEX idx_cotacao_status ON cotacao(status_cotacao)');
await txn.execute('CREATE INDEX idx_cotacao_item_produto ON cotacao_item_produto(id_cotacao)');
await txn.execute('CREATE INDEX idx_cotacao_item_servico ON cotacao_item_servico(id_cotacao)');
      await txn.execute('CREATE INDEX idx_sync_queue     ON sync_queue(tentativas)');
      await txn.execute(
  'CREATE INDEX idx_despesa_fornecedor ON despesa(id_fornecedor)',
);

await txn.execute(
  'CREATE INDEX idx_despesa_data ON despesa(data_despesa)',
);

await txn.execute(
  'CREATE INDEX idx_despesa_sync ON despesa(sync_status)',
);

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
      await txn.delete('item_pedido_servico');
      await txn.delete('pedido_credito_pagamento');
await txn.delete('pedido_credito_parcela');
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
      await txn.delete('cotacao_item_produto');
await txn.delete('cotacao_item_servico');
await txn.delete('cotacao');
await txn.delete('despesa');
    });
  }
}