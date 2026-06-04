// lib/models/marca_model.dart

import 'categoria_model.dart';

class Marca {
  final int? idMarca;
  final String nomeMarca;
  final List<Categoria>? categorias; // NOVO

  Marca({
    this.idMarca,
    required this.nomeMarca,
    this.categorias, // NOVO
  });

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(
      idMarca: json['idMarca'],
      nomeMarca: json['nomeMarca'],
      categorias: json['categorias'] != null
          ? (json['categorias'] as List)
              .map((cat) => Categoria.fromJson(cat))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMarca != null) 'idMarca': idMarca,
      'nomeMarca': nomeMarca,
      if (categorias != null)
        'categorias': categorias!.map((c) => c.toJson()).toList(),
    };
  }

  Map<String, dynamic> toJsonCreate() {
    return {
      'nomeMarca': nomeMarca,
    };
  }

  Marca copyWith({
    int? idMarca,
    String? nomeMarca,
    List<Categoria>? categorias,
  }) {
    return Marca(
      idMarca: idMarca ?? this.idMarca,
      nomeMarca: nomeMarca ?? this.nomeMarca,
      categorias: categorias ?? this.categorias,
    );
  }

  @override
  String toString() {
    return 'Marca{idMarca: $idMarca, nomeMarca: $nomeMarca, categorias: ${categorias?.length ?? 0}}';
  }
}