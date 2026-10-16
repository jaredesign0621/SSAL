class MarketItemModel {
  final int? id;
  final int characterId;
  final String itemName;
  final int price; // 아이템 가격 (재화 단위)
  final int quantity; // 수량 (기본 1)
  final double feeRate; // 적용된 서버 수수료율 (%)
  final int netAmount; // 실수령액 = (price * quantity) * (1 - feeRate / 100)
  final String status; // '판매중', '판매완료', '취소'
  final String createdAt;

  MarketItemModel({
    this.id,
    required this.characterId,
    required this.itemName,
    required this.price,
    this.quantity = 1,
    required this.feeRate,
    int? netAmount,
    this.status = '판매중',
    String? createdAt,
  })  : netAmount = netAmount ?? calculateNetAmount(price, quantity, feeRate),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  static int calculateNetAmount(int price, int quantity, double feeRate) {
    final total = price * quantity;
    final fee = (total * (feeRate / 100.0)).round();
    return total - fee;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'character_id': characterId,
      'item_name': itemName,
      'price': price,
      'quantity': quantity,
      'fee_rate': feeRate,
      'net_amount': netAmount,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory MarketItemModel.fromMap(Map<String, dynamic> map) {
    return MarketItemModel(
      id: map['id'] as int?,
      characterId: map['character_id'] as int,
      itemName: map['item_name'] as String,
      price: map['price'] as int,
      quantity: map['quantity'] as int? ?? 1,
      feeRate: (map['fee_rate'] as num?)?.toDouble() ?? 0.0,
      netAmount: map['net_amount'] as int,
      status: map['status'] as String? ?? '판매중',
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  MarketItemModel copyWith({
    int? id,
    int? characterId,
    String? itemName,
    int? price,
    int? quantity,
    double? feeRate,
    int? netAmount,
    String? status,
    String? createdAt,
  }) {
    return MarketItemModel(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      feeRate: feeRate ?? this.feeRate,
      netAmount: netAmount ?? (price != null || quantity != null || feeRate != null
          ? calculateNetAmount(price ?? this.price, quantity ?? this.quantity, feeRate ?? this.feeRate)
          : this.netAmount),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
