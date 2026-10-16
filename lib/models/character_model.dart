class CharacterModel {
  final int? id;
  final int serverId;
  final String name;
  final String accountInfo; // 연동된 계정 정보 (예: 구글계정A, 카카오1, 게스트 등)
  final String? note;
  final String createdAt;

  CharacterModel({
    this.id,
    required this.serverId,
    required this.name,
    required this.accountInfo,
    this.note,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'name': name,
      'account_info': accountInfo,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory CharacterModel.fromMap(Map<String, dynamic> map) {
    return CharacterModel(
      id: map['id'] as int?,
      serverId: map['server_id'] as int,
      name: map['name'] as String,
      accountInfo: map['account_info'] as String? ?? '',
      note: map['note'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  CharacterModel copyWith({
    int? id,
    int? serverId,
    String? name,
    String? accountInfo,
    String? note,
    String? createdAt,
  }) {
    return CharacterModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      accountInfo: accountInfo ?? this.accountInfo,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
