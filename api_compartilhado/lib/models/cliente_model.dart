// lib/features/cliente/model/cliente_model.dart

class ClienteModel {
  final int     id;
  final String? nome;
  final String? apelido;
  final String? email;
  final String? nuit;
  final String? contacto;
  final String? morada;
  final int     idPerfil;
  final String  nomePerfil;

  // ── Campos offline-first ──────────────────────────────────────────
  /// 'synced' | 'pending' | 'conflict'
  final String  syncStatus;

  /// UUID local atribuído quando criado offline.
  /// Null quando o registo veio do backend.
  final String? localId;

  const ClienteModel({
    required this.id,
    this.nome,
    this.apelido,
    this.email,
    this.nuit,
    this.contacto,
    this.morada,
    required this.idPerfil,
    required this.nomePerfil,
    this.syncStatus = 'synced',
    this.localId,
  });

  // ── Deserialização — resposta HTTP do backend ─────────────────────

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id:         json['id']         as int,
      nome:       json['nome']       as String?,
      apelido:    json['apelido']    as String?,
      email:      json['email']      as String?,
      nuit:       json['nuit']       as String?,
      contacto:   json['contacto']   as String?,
      morada:     json['morada']     as String?,
      idPerfil:   json['idPerfil']   as int,
      nomePerfil: json['nomePerfil'] as String? ?? 'Sem perfil',
      syncStatus: 'synced',
      localId:    null,
    );
  }

  // ── Deserialização — leitura do SQLite local ──────────────────────

  factory ClienteModel.fromLocalDb(Map<String, dynamic> row) {
    return ClienteModel(
      id:         row['id']          as int,
      nome:       row['nome']        as String?,
      apelido:    row['apelido']     as String?,
      email:      row['email']       as String?,
      nuit:       row['nuit']        as String?,
      contacto:   row['contacto']    as String?,
      morada:     row['morada']      as String?,
      idPerfil:   row['id_perfil']   as int,
      nomePerfil: row['nome_perfil'] as String? ?? 'Sem perfil',
      syncStatus: row['sync_status'] as String? ?? 'synced',
      localId:    row['local_id']    as String?,
    );
  }

  // ── Serialização — envio ao backend (POST/PUT) ────────────────────

  Map<String, dynamic> toJson() {
    return {
      if (nome     != null) 'nome':     nome,
      if (apelido  != null) 'apelido':  apelido,
      if (email    != null) 'email':    email,
      if (nuit     != null) 'nuit':     nuit,
      if (contacto != null) 'contacto': contacto,
      if (morada   != null) 'morada':   morada,
      'idPerfil': idPerfil,
    };
  }

  // ── Serialização — escrita no SQLite local ────────────────────────

  Map<String, dynamic> toLocalDb() {
    return {
      'id':          id,
      'local_id':    localId,
      'nome':        nome,
      'apelido':     apelido,
      'email':       email,
      'nuit':        nuit,
      'contacto':    contacto,
      'morada':      morada,
      'id_perfil':   idPerfil,
      'nome_perfil': nomePerfil,
      'sync_status': syncStatus,
      'updated_at':  DateTime.now().toIso8601String(),
    };
  }

  // ── Utilitários ───────────────────────────────────────────────────

  String get nomeCompleto {
    final partes = [nome, apelido].whereType<String>().where((s) => s.isNotEmpty);
    return partes.isNotEmpty ? partes.join(' ') : 'Cliente #$id';
  }

  String get iniciais {
    final n = nome?.isNotEmpty    == true ? nome![0]    : '';
    final a = apelido?.isNotEmpty == true ? apelido![0] : '';
    final resultado = '$n$a'.toUpperCase();
    return resultado.isNotEmpty ? resultado : '#';
  }

  bool get isPending  => syncStatus == 'pending';
  bool get isSynced   => syncStatus == 'synced';
  bool get isConflict => syncStatus == 'conflict';
  bool get isOffline  => localId != null && syncStatus == 'pending';

  ClienteModel copyWith({
    int?    id,
    String? nome,
    String? apelido,
    String? email,
    String? nuit,
    String? contacto,
    String? morada,
    int?    idPerfil,
    String? nomePerfil,
    String? syncStatus,
    String? localId,
  }) {
    return ClienteModel(
      id:         id         ?? this.id,
      nome:       nome       ?? this.nome,
      apelido:    apelido    ?? this.apelido,
      email:      email      ?? this.email,
      nuit:       nuit       ?? this.nuit,
      contacto:   contacto   ?? this.contacto,
      morada:     morada     ?? this.morada,
      idPerfil:   idPerfil   ?? this.idPerfil,
      nomePerfil: nomePerfil ?? this.nomePerfil,
      syncStatus: syncStatus ?? this.syncStatus,
      localId:    localId    ?? this.localId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ClienteModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ClienteModel(id: $id, nomeCompleto: $nomeCompleto, syncStatus: $syncStatus)';
}

// ─────────────────────────────────────────────────────────────────
// DTO de criação / edição — enviado ao backend
// ─────────────────────────────────────────────────────────────────

class ClienteRequestDTO {
  final String? nome;
  final String? apelido;
  final String? email;
  final String? nuit;
  final String? contacto;
  final String? morada;
  final int     idPerfil;

  const ClienteRequestDTO({
    this.nome,
    this.apelido,
    this.email,
    this.nuit,
    this.contacto,
    this.morada,
    required this.idPerfil,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nome     != null && nome!.isNotEmpty)     'nome':     nome,
      if (apelido  != null && apelido!.isNotEmpty)  'apelido':  apelido,
      if (email    != null && email!.isNotEmpty)     'email':    email,
      if (nuit     != null && nuit!.isNotEmpty)      'nuit':     nuit,
      if (contacto != null && contacto!.isNotEmpty)  'contacto': contacto,
      if (morada   != null && morada!.isNotEmpty)    'morada':   morada,
      'idPerfil': idPerfil,
    };
  }
}