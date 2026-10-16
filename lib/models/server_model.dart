class ServerModel {
  final int? id;
  final int gameId;
  final String name;
  final double feeRate; // 거래소 수수료율 (%) (예: 5.0, 10.0)
  final String? memo;
  final String createdAt;

  ServerModel({
    this.id,
    required this.gameId,
    required this.name,
    this.feeRate = 5.0,
    this.memo,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'game_id': gameId,
      'name': name,
      'fee_rate': feeRate,
      'memo': memo,
      'created_at': createdAt,
    };
  }

  factory ServerModel.fromMap(Map<String, dynamic> map) {
    return ServerModel(
      id: map['id'] as int?,
      gameId: map['game_id'] as int,
      name: map['name'] as String,
      feeRate: (map['fee_rate'] as num?)?.toDouble() ?? 5.0,
      memo: map['memo'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  ServerModel copyWith({
    int? id,
    int? gameId,
    String? name,
    double? feeRate,
    String? memo,
    String? createdAt,
  }) {
    return ServerModel(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      name: name ?? this.name,
      feeRate: feeRate ?? this.feeRate,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
