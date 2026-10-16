class CurrencyModel {
  final int? id;
  final int characterId;
  final String name; // 재화 명 (예: 다이아, 골드, 쌀 등)
  final int amount; // 보유 수량
  final String updatedAt;

  CurrencyModel({
    this.id,
    required this.characterId,
    required this.name,
    required this.amount,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'character_id': characterId,
      'name': name,
      'amount': amount,
      'updated_at': updatedAt,
    };
  }

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      id: map['id'] as int?,
      characterId: map['character_id'] as int,
      name: map['name'] as String,
      amount: map['amount'] as int? ?? 0,
      updatedAt: map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  CurrencyModel copyWith({
    int? id,
    int? characterId,
    String? name,
    int? amount,
    String? updatedAt,
  }) {
    return CurrencyModel(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
