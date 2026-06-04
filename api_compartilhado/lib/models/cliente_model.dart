// lib/features/cliente/model/cliente_model.dart

class ClienteModel {
  final int id;
  final String? nome;
  final String? apelido;
  final String? email;
  final String? nuit;
  final String? contacto;
  final String? morada;
  final int idPerfil;
  final String nomePerfil;

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
  });

  // ── Deserialização ────────────────────────────────────────────────

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
    );
  }

  // ── Serialização (para POST/PUT) ──────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      if (nome     != null) 'nome':      nome,
      if (apelido  != null) 'apelido':   apelido,
      if (email    != null) 'email':     email,
      if (nuit     != null) 'nuit':      nuit,
      if (contacto != null) 'contacto':  contacto,
      if (morada   != null) 'morada':    morada,
      'idPerfil': idPerfil,
    };
  }

  // ── Utilitários ───────────────────────────────────────────────────

  /// Nome completo ou fallback para exibição em listas
  String get nomeCompleto {
    final partes = [nome, apelido].whereType<String>().where((s) => s.isNotEmpty);
    return partes.isNotEmpty ? partes.join(' ') : 'Cliente #$id';
  }

  /// Iniciais para avatar
  String get iniciais {
    final n = nome?.isNotEmpty == true ? nome![0] : '';
    final a = apelido?.isNotEmpty == true ? apelido![0] : '';
    final resultado = '$n$a'.toUpperCase();
    return resultado.isNotEmpty ? resultado : '#';
  }

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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ClienteModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ClienteModel(id: $id, nomeCompleto: $nomeCompleto)';
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