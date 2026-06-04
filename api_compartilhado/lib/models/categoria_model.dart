// lib/models/categoria_model.dart

class Categoria {
  final int? idCategoria;
  final String nomeCategoria;
  final String? descricao;

  Categoria({
    this.idCategoria,
    required this.nomeCategoria,
    this.descricao,
  });

  // Converter de JSON para Modelo
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: json['idCategoria'],
      nomeCategoria: json['nomeCategoria'],
      descricao: json['descricao'],
    );
  }

  // Converter de Modelo para JSON
  Map<String, dynamic> toJson() {
    return {
      if (idCategoria != null) 'idCategoria': idCategoria,
      'nomeCategoria': nomeCategoria,
      'descricao': descricao,
    };
  }

  // Para criar/editar (sem ID)
  Map<String, dynamic> toJsonCreate() {
    return {
      'nomeCategoria': nomeCategoria,
      'descricao': descricao,
    };
  }

  // Copiar com modificações
  Categoria copyWith({
    int? idCategoria,
    String? nomeCategoria,
    String? descricao,
  }) {
    return Categoria(
      idCategoria: idCategoria ?? this.idCategoria,
      nomeCategoria: nomeCategoria ?? this.nomeCategoria,
      descricao: descricao ?? this.descricao,
    );
  }

  @override
  String toString() {
    return 'Categoria{idCategoria: $idCategoria, nomeCategoria: $nomeCategoria, descricao: $descricao}';
  }
}