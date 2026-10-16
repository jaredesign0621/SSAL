class ExchangeRecordModel {
  final int? id;
  final int? characterId;
  final String characterName;
  final String serverName;
  final String currencyName;
  final int currencyAmount; // 판매 재화 수량
  final double exchangeRate; // 재화 1단위당 KRW 금액 (또는 100개당 등)
  final int grossAmount; // 기본 환전 결과 금액 (KRW) = currencyAmount * exchangeRate
  final double feeRate; // 환전/중개 수수료율 (%)
  final int feeAmount; // 차감된 수수료 (KRW)
  final bool isWithdrawFeeApplied; // 출금 수수료 적용 여부 (체크박스)
  final int withdrawFee; // 출금 수수료 금액 (기본 1,000원)
  final int netKrwAmount; // 최종 실수령 금액 (KRW)
  final String? memo;
  final String createdAt;

  ExchangeRecordModel({
    this.id,
    this.characterId,
    required this.characterName,
    required this.serverName,
    required this.currencyName,
    required this.currencyAmount,
    required this.exchangeRate,
    required this.grossAmount,
    this.feeRate = 0.0,
    required this.feeAmount,
    this.isWithdrawFeeApplied = false,
    this.withdrawFee = 1000,
    required this.netKrwAmount,
    this.memo,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  static int calculateGross(int amount, double rate) {
    return (amount * rate).round();
  }

  static int calculateNet({
    required int gross,
    required double feeRate,
    required bool isWithdrawFeeApplied,
    required int withdrawFee,
  }) {
    final fee = (gross * (feeRate / 100.0)).round();
    final afterFee = gross - fee;
    final finalAmount = isWithdrawFeeApplied ? (afterFee - withdrawFee) : afterFee;
    return finalAmount > 0 ? finalAmount : 0;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'character_id': characterId,
      'character_name': characterName,
      'server_name': serverName,
      'currency_name': currencyName,
      'currency_amount': currencyAmount,
      'exchange_rate': exchangeRate,
      'gross_amount': grossAmount,
      'fee_rate': feeRate,
      'fee_amount': feeAmount,
      'is_withdraw_fee_applied': isWithdrawFeeApplied ? 1 : 0,
      'withdraw_fee': withdrawFee,
      'net_krw_amount': netKrwAmount,
      'memo': memo,
      'created_at': createdAt,
    };
  }

  factory ExchangeRecordModel.fromMap(Map<String, dynamic> map) {
    return ExchangeRecordModel(
      id: map['id'] as int?,
      characterId: map['character_id'] as int?,
      characterName: map['character_name'] as String? ?? '캐릭터 미지정',
      serverName: map['server_name'] as String? ?? '서버 미지정',
      currencyName: map['currency_name'] as String? ?? '재화',
      currencyAmount: map['currency_amount'] as int? ?? 0,
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      grossAmount: map['gross_amount'] as int? ?? 0,
      feeRate: (map['fee_rate'] as num?)?.toDouble() ?? 0.0,
      feeAmount: map['fee_amount'] as int? ?? 0,
      isWithdrawFeeApplied: (map['is_withdraw_fee_applied'] as int? ?? 0) == 1,
      withdrawFee: map['withdraw_fee'] as int? ?? 1000,
      netKrwAmount: map['net_krw_amount'] as int? ?? 0,
      memo: map['memo'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
