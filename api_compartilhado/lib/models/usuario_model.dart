// PATCH para o ficheiro existente em:
// packages/api_compartilhado/lib/models/usuario_model.dart
//
// Adiciona ao UsuarioModel existente:
//   1. Campos syncStatus e localId
//   2. factory fromLocalDb
//   3. método toLocalDb
//   4. getter isPending, isSynced, isConflict, isOffline
//   5. _parseDate exposto como static público
//   6. UsuarioRequestDTO
//   7. AlterarSenhaDTO
//
// ─────────────────────────────────────────────────────────────────
// SUBSTITUI a classe UsuarioModel existente por esta versão completa
// ─────────────────────────────────────────────────────────────────

class UsuarioModel {
  final int      id;
  final String   nome;
  final String?  apelido;
  final String?  telefone;
  final String   email;
  final bool     ativo;
  final int      idPerfil;
  final String   nomePerfil;
  final bool     primeiraSenha;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  // ── Campos offline-first ──────────────────────────────────────────
  /// 'synced' | 'pending' | 'conflict'
  final String  syncStatus;

  /// UUID local atribuído quando criado offline.
  /// Null quando o registo veio do backend.
  final String? localId;

  const UsuarioModel({
    required this.id,
    required this.nome,
    this.apelido,
    this.telefone,
    required this.email,
    required this.ativo,
    required this.idPerfil,
    required this.nomePerfil,
    required this.primeiraSenha,
    required this.criadoEm,
    required this.atualizadoEm,
    this.syncStatus = 'synced',
    this.localId,
  });

  // ── Deserialização — resposta HTTP do backend ─────────────────────

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id:            json['id']            as int,
      nome:          json['nome']          as String? ?? '',
      apelido:       json['apelido']       as String?,
      telefone:      json['telefone']      as String?,
      email:         json['email']         as String? ?? '',
      ativo:         json['ativo']         as bool?   ?? false,
      idPerfil:      json['idPerfil']      as int?    ?? 0,
      nomePerfil:    json['nomePerfil']    as String? ?? 'Sem perfil',
      primeiraSenha: json['primeiraSenha'] as bool?   ?? true,
      criadoEm:      DateTime.parse(json['criadoEm']     as String),
      atualizadoEm:  DateTime.parse(json['atualizadoEm'] as String),
      syncStatus:    'synced',
      localId:       null,
    );
  }

  // ── Deserialização — leitura do SQLite local ──────────────────────

  factory UsuarioModel.fromLocalDb(Map<String, dynamic> row) {
    return UsuarioModel(
      id:            row['id']              as int,
      nome:          row['nome']            as String? ?? '',
      apelido:       row['apelido']         as String?,
      telefone:      row['telefone']        as String?,
      email:         row['email']           as String? ?? '',
      ativo:         (row['ativo']          as int?    ?? 1) == 1,
      idPerfil:      row['id_perfil']       as int?    ?? 0,
      nomePerfil:    row['nome_perfil']     as String? ?? 'Sem perfil',
      primeiraSenha: (row['primeira_senha'] as int?    ?? 1) == 1,
      criadoEm:      parseDate(row['criado_em']  as String?),
      atualizadoEm:  parseDate(row['updated_at'] as String?),
      syncStatus:    row['sync_status']     as String? ?? 'synced',
      localId:       row['local_id']        as String?,
    );
  }

  // ── Serialização — envio ao backend (POST/PUT) ────────────────────

  Map<String, dynamic> toJson() => {
        'nome':     nome,
        'email':    email,
        'ativo':    ativo,
        'idPerfil': idPerfil,
        if (apelido  != null) 'apelido':  apelido,
        if (telefone != null) 'telefone': telefone,
      };

  // ── Serialização — escrita no SQLite local ────────────────────────

  Map<String, dynamic> toLocalDb() => {
        'id':             id,
        'local_id':       localId,
        'nome':           nome,
        'apelido':        apelido,
        'telefone':       telefone,
        'email':          email,
        'ativo':          ativo ? 1 : 0,
        'id_perfil':      idPerfil,
        'nome_perfil':    nomePerfil,
        'primeira_senha': primeiraSenha ? 1 : 0,
        'sync_status':    syncStatus,
        'updated_at':     DateTime.now().toIso8601String(),
      };

  // ── Utilitários ───────────────────────────────────────────────────

  bool get isAdmin    => nomePerfil.trim().toLowerCase() == 'administrador';
  bool get isPending  => syncStatus == 'pending';
  bool get isSynced   => syncStatus == 'synced';
  bool get isConflict => syncStatus == 'conflict';
  bool get isOffline  => localId != null && syncStatus == 'pending';

  String get nomeCompleto {
    final partes = [nome, apelido]
        .whereType<String>()
        .where((s) => s.isNotEmpty);
    return partes.isNotEmpty ? partes.join(' ') : 'Utilizador #$id';
  }

  String get iniciais {
    final n = nome.isNotEmpty              ? nome[0]        : '';
    final a = apelido?.isNotEmpty == true  ? apelido![0]    : '';
    final r = '$n$a'.toUpperCase();
    return r.isNotEmpty ? r : '#';
  }

  // Exposto como público para uso no Repository e noutros locais
  static DateTime parseDate(String? value) {
    if (value != null && value.isNotEmpty) {
      try { return DateTime.parse(value); } catch (_) {}
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  UsuarioModel copyWith({
    int?      id,
    String?   nome,
    String?   apelido,
    String?   telefone,
    String?   email,
    bool?     ativo,
    int?      idPerfil,
    String?   nomePerfil,
    bool?     primeiraSenha,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String?   syncStatus,
    String?   localId,
  }) => UsuarioModel(
        id:            id            ?? this.id,
        nome:          nome          ?? this.nome,
        apelido:       apelido       ?? this.apelido,
        telefone:      telefone      ?? this.telefone,
        email:         email         ?? this.email,
        ativo:         ativo         ?? this.ativo,
        idPerfil:      idPerfil      ?? this.idPerfil,
        nomePerfil:    nomePerfil    ?? this.nomePerfil,
        primeiraSenha: primeiraSenha ?? this.primeiraSenha,
        criadoEm:      criadoEm      ?? this.criadoEm,
        atualizadoEm:  atualizadoEm  ?? this.atualizadoEm,
        syncStatus:    syncStatus    ?? this.syncStatus,
        localId:       localId       ?? this.localId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UsuarioModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UsuarioModel(id: $id, nomeCompleto: $nomeCompleto, syncStatus: $syncStatus)';
}

// ─────────────────────────────────────────────────────────────────
// DTO de criação / edição
// ─────────────────────────────────────────────────────────────────

class UsuarioRequestDTO {
  final String  nome;
  final String  email;
  final int     idPerfil;
  final String? apelido;
  final String? telefone;

  const UsuarioRequestDTO({
    required this.nome,
    required this.email,
    required this.idPerfil,
    this.apelido,
    this.telefone,
  });

  Map<String, dynamic> toJson() => {
        'nome':     nome,
        'email':    email,
        'idPerfil': idPerfil,
        if (apelido  != null && apelido!.isNotEmpty)  'apelido':  apelido,
        if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
      };
}

// ─────────────────────────────────────────────────────────────────
// DTO de alteração de senha
// ─────────────────────────────────────────────────────────────────

class AlterarSenhaDTO {
  final String senhaAtual;
  final String novaSenha;

  const AlterarSenhaDTO({
    required this.senhaAtual,
    required this.novaSenha,
  });

  Map<String, dynamic> toJson() => {
        'senhaAtual': senhaAtual,
        'novaSenha':  novaSenha,
      };
}

// ─────────────────────────────────────────────────────────────────
// Excepção do service — usada no Repository
// ─────────────────────────────────────────────────────────────────

class UsuarioServiceException implements Exception {
  final String mensagem;
  const UsuarioServiceException(this.mensagem);

  @override
  String toString() => mensagem;
}