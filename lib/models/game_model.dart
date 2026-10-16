class GameModel {
  final int? id;
  final String name;
  final String? memo;
  final String createdAt;

  GameModel({
    this.id,
    required this.name,
    this.memo,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'memo': memo,
      'created_at': createdAt,
    };
  }

  factory GameModel.fromMap(Map<String, dynamic> map) {
    return GameModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      memo: map['memo'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  GameModel copyWith({
    int? id,
    String? name,
    String? memo,
    String? createdAt,
  }) {
    return GameModel(
      id: id ?? this.id,
      name: name ?? this.name,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
