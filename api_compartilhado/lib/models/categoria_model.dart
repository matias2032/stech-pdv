// lib/features/categoria/model/categoria_model.dart

class CategoriaModel {
  final int id;
  final String nomeCategoria;
  final String? descricao;
  final String syncStatus;
  final String? localId;
  final String? updatedAt;

  const CategoriaModel({
    required this.id,
    required this.nomeCategoria,
    this.descricao,
    this.syncStatus = 'synced',
    this.localId,
    this.updatedAt,
  });

  bool get isPending  => syncStatus == 'pending';
  bool get isSynced   => syncStatus == 'synced';
  bool get isConflict => syncStatus == 'conflict';
  bool get isOffline  => isPending;

  factory CategoriaModel.fromJson(Map<String, dynamic> json) => CategoriaModel(
        id:            json['idCategoria']   as int,
        nomeCategoria: json['nomeCategoria'] as String,
        descricao:     json['descricao']     as String?,
        syncStatus:    (json['syncStatus'] as String?)?.toLowerCase() ?? 'synced',
        updatedAt:     json['updatedAt']     as String?,
      );

  factory CategoriaModel.fromLocalDb(Map<String, dynamic> row) => CategoriaModel(
        id:            row['id']             as int,
        nomeCategoria: row['nome_categoria'] as String,
        descricao:     row['descricao']      as String?,
        syncStatus:    row['sync_status']    as String? ?? 'synced',
        localId:       row['local_id']       as String?,
        updatedAt:     row['updated_at']     as String?,
      );

  Map<String, dynamic> toJson() => {
        'nomeCategoria': nomeCategoria,
        if (descricao != null) 'descricao': descricao,
      };

  Map<String, dynamic> toLocalDb() => {
        'id':             id,
        'local_id':       localId,
        'nome_categoria': nomeCategoria,
        'descricao':      descricao,
        'sync_status':    syncStatus,
        'updated_at':     updatedAt,
      };

  CategoriaModel copyWith({
    int?    id,
    String? nomeCategoria,
    String? descricao,
    String? syncStatus,
    String? localId,
    String? updatedAt,
  }) => CategoriaModel(
        id:            id            ?? this.id,
        nomeCategoria: nomeCategoria ?? this.nomeCategoria,
        descricao:     descricao     ?? this.descricao,
        syncStatus:    syncStatus    ?? this.syncStatus,
        localId:       localId       ?? this.localId,
        updatedAt:     updatedAt     ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) => other is CategoriaModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CategoriaModel{id: $id, nomeCategoria: $nomeCategoria, syncStatus: $syncStatus}';
}

class CategoriaRequestDTO {
  final String nomeCategoria;
  final String? descricao;
  const CategoriaRequestDTO({required this.nomeCategoria, this.descricao});
  Map<String, dynamic> toJson() => {
        'nomeCategoria': nomeCategoria,
        if (descricao != null) 'descricao': descricao,
      };
}