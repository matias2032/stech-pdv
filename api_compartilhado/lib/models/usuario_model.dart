// lib/features/usuario/models/usuario_model.dart

class UsuarioModel {
  final int id;
  final String nome;
  final String? apelido;
  final String? telefone;
  final String email;
  final bool ativo;
  final String nomePerfil;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final bool primeiraSenha;
  bool get isAdmin => nomePerfil.trim().toLowerCase() == 'administrador';

  const UsuarioModel({
    required this.id,
    required this.nome,
    this.apelido,
    this.telefone,
    required this.email,
    required this.ativo,
    required this.nomePerfil,
    required this.criadoEm,
    required this.atualizadoEm,
  required this.primeiraSenha,
  });

factory UsuarioModel.fromJson(Map<String, dynamic> json) {
  return UsuarioModel(
    id: json['id'] as int,
    nome: json['nome'] as String? ?? '',
    apelido: json['apelido'] as String?,
    telefone: json['telefone'] as String?,
    email: json['email'] as String? ?? '',
    ativo: json['ativo'] as bool? ?? false,
    nomePerfil: json['nomePerfil'] as String? ?? 'Sem perfil',
    criadoEm: DateTime.parse(json['criadoEm'] as String),
    atualizadoEm: DateTime.parse(json['atualizadoEm'] as String),
    primeiraSenha: json['primeiraSenha'] as bool? ?? true,
  );
}
  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'apelido': apelido,
        'telefone': telefone,
        'email': email,
        'ativo': ativo,
        'nomePerfil': nomePerfil,
        'criadoEm': criadoEm.toIso8601String(),
        'atualizadoEm': atualizadoEm.toIso8601String(),
        'primeiraSenha': primeiraSenha,
      };

  UsuarioModel copyWith({
    int? id,
    String? nome,
    String? apelido,
    String? telefone,
    String? email,
    bool? ativo,
    String? nomePerfil,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    bool? primeiraSenha,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      apelido: apelido ?? this.apelido,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      ativo: ativo ?? this.ativo,
      nomePerfil: nomePerfil ?? this.nomePerfil,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      primeiraSenha: primeiraSenha ?? this.primeiraSenha,
    );
  }
}