class FornecedorModel {
  final int? id;
  final String? nome;
  final String? email;
  final String? nuit;
  final String contacto;
  final String? morada;

  const FornecedorModel({
    this.id,
    this.nome,
    this.email,
    this.nuit,
    required this.contacto,
    this.morada,
  });

  factory FornecedorModel.fromJson(Map<String, dynamic> json) {
    return FornecedorModel(
      id: _parseIntOpt(json['id']),
      nome: _parseStringOpt(json['nome']),
      email: _parseStringOpt(json['email']),
      nuit: _parseStringOpt(json['nuit']),
      contacto: json['contacto']?.toString() ?? '',
      morada: _parseStringOpt(json['morada']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': _emptyToNull(nome),
      'email': _emptyToNull(email),
      'nuit': _emptyToNull(nuit),
      'contacto': contacto.trim(),
      'morada': _emptyToNull(morada),
    };
  }

  FornecedorModel copyWith({
    int? id,
    String? nome,
    String? email,
    String? nuit,
    String? contacto,
    String? morada,
  }) {
    return FornecedorModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      nuit: nuit ?? this.nuit,
      contacto: contacto ?? this.contacto,
      morada: morada ?? this.morada,
    );
  }

  bool get contactoValido => contacto.trim().isNotEmpty;

  @override
  String toString() {
    return 'FornecedorModel(id: $id, nome: $nome, email: $email, nuit: $nuit, contacto: $contacto, morada: $morada)';
  }

  static int? _parseIntOpt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static String? _parseStringOpt(dynamic value) {
    if (value == null) return null;

    final texto = value.toString().trim();
    if (texto.isEmpty) return null;

    return texto;
  }

  static String? _emptyToNull(String? value) {
    if (value == null) return null;

    final texto = value.trim();
    if (texto.isEmpty) return null;

    return texto;
  }
}