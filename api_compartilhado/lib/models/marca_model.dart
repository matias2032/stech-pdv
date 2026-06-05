// lib/features/marca/model/marca_model.dart

class MarcaModel {
  final int id;
  final String nomeMarca;
  final String syncStatus;
  final String? localId;
  final String? updatedAt;

  const MarcaModel({
    required this.id,
    required this.nomeMarca,
    this.syncStatus = 'synced',
    this.localId,
    this.updatedAt,
  });

  bool get isPending  => syncStatus == 'pending';
  bool get isSynced   => syncStatus == 'synced';
  bool get isConflict => syncStatus == 'conflict';
  bool get isOffline  => isPending;

  factory MarcaModel.fromJson(Map<String, dynamic> json) => MarcaModel(
        id:         json['idMarca']   as int,
        nomeMarca:  json['nomeMarca'] as String,
        syncStatus: (json['syncStatus'] as String?)?.toLowerCase() ?? 'synced',
        updatedAt:  json['updatedAt']  as String?,
      );

  factory MarcaModel.fromLocalDb(Map<String, dynamic> row) => MarcaModel(
        id:         row['id']          as int,
        nomeMarca:  row['nome_marca']  as String,
        syncStatus: row['sync_status'] as String? ?? 'synced',
        localId:    row['local_id']    as String?,
        updatedAt:  row['updated_at']  as String?,
      );

  Map<String, dynamic> toJson() => {
        'nomeMarca': nomeMarca,
      };

  Map<String, dynamic> toLocalDb() => {
        'id':          id,
        'local_id':    localId,
        'nome_marca':  nomeMarca,
        'sync_status': syncStatus,
        'updated_at':  updatedAt,
      };

  MarcaModel copyWith({
    int?    id,
    String? nomeMarca,
    String? syncStatus,
    String? localId,
    String? updatedAt,
  }) => MarcaModel(
        id:         id         ?? this.id,
        nomeMarca:  nomeMarca  ?? this.nomeMarca,
        syncStatus: syncStatus ?? this.syncStatus,
        localId:    localId    ?? this.localId,
        updatedAt:  updatedAt  ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) => other is MarcaModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MarcaModel{id: $id, nomeMarca: $nomeMarca, syncStatus: $syncStatus}';
}

class MarcaRequestDTO {
  final String nomeMarca;
  const MarcaRequestDTO({required this.nomeMarca});
  Map<String, dynamic> toJson() => {'nomeMarca': nomeMarca};
}