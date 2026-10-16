import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ssal_provider.dart';
import '../models/exchange_record_model.dart';
import '../theme/app_theme.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({Key? key}) : super(key: key);

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final _amountCtrl = TextEditingController(text: '10000');
  final _rateCtrl = TextEditingController(text: '10.0'); // 1개당 KRW (예: 1다이아 = 10원)
  final _platformFeeCtrl = TextEditingController(text: '0.0'); // 거래/중개 수수료율(%)
  final _withdrawFeeCtrl = TextEditingController(text: '1000'); // 기본 출금 수수료 (1,000원)
  final _memoCtrl = TextEditingController();

  bool _isWithdrawFeeApplied = true; // 출금 수수료 체크박스 기본 체크

  int _grossAmount = 0;
  int _platformFeeAmount = 0;
  int _netAmount = 0;

  final NumberFormat _nf = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_recalculate);
    _rateCtrl.addListener(_recalculate);
    _platformFeeCtrl.addListener(_recalculate);
    _withdrawFeeCtrl.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _platformFeeCtrl.dispose();
    _withdrawFeeCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  void _recalculate() {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0.0;
    final feeRate = double.tryParse(_platformFeeCtrl.text.trim()) ?? 0.0;
    final withdrawFee = int.tryParse(_withdrawFeeCtrl.text.replaceAll(',', '').trim()) ?? 1000;

    final gross = ExchangeRecordModel.calculateGross(amount, rate);
    final feeAmount = (gross * (feeRate / 100.0)).round();
    final net = ExchangeRecordModel.calculateNet(
      gross: gross,
      feeRate: feeRate,
      isWithdrawFeeApplied: _isWithdrawFeeApplied,
      withdrawFee: withdrawFee,
    );

    setState(() {
      _grossAmount = gross;
      _platformFeeAmount = feeAmount;
      _netAmount = net;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SsalProvider>();
    final server = provider.selectedServer;
    final char = provider.selectedCharacter;

    final records = provider.exchangeRecords;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 환전 계산기 상단 카드
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderDark),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.currency_exchange, color: AppTheme.primaryGold),
                            SizedBox(width: 8),
                            Text(
                              '재화 ➔ 현금(KRW) 환전 계산기',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (char != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderDark),
                            ),
                            child: Text(
                              '${char.name} (${server?.name ?? ''})',
                              style: const TextStyle(fontSize: 11, color: AppTheme.primaryGoldLight),
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: AppTheme.borderDark, height: 24),

                    // 1. 판매 재화 수량 & 환율 입력
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '판매한 재화 수량 *',
                              hintText: '예: 10000',
                              suffixText: '개',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: '1개당 원화(KRW) *',
                              hintText: '예: 10.0',
                              suffixText: '원',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. 플랫폼/중개 수수료율 & 출금 수수료 체크박스
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _platformFeeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: '중개/플랫폼 수수료율',
                              hintText: '0.0',
                              suffixText: '%',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 핵심 요구사항: 환전 화면 옆에 '출금 수수료' 체크박스 추가 (-1000원 등 차감)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isWithdrawFeeApplied
                                  ? AppTheme.accentGreen.withOpacity(0.12)
                                  : AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isWithdrawFeeApplied ? AppTheme.accentGreen : AppTheme.borderDark,
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isWithdrawFeeApplied,
                                  activeColor: AppTheme.accentGreen,
                                  onChanged: (val) {
                                    setState(() {
                                      _isWithdrawFeeApplied = val ?? false;
                                    });
                                    _recalculate();
                                  },
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '출금 수수료',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _isWithdrawFeeApplied ? '-${_withdrawFeeCtrl.text}원 적용중' : '미적용',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _isWithdrawFeeApplied ? AppTheme.accentGreen : AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isWithdrawFeeApplied) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('출금 수수료 금액 조정: ',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _withdrawFeeCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                suffixText: '원',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    TextField(
                      controller: _memoCtrl,
                      decoration: const InputDecoration(
                        labelText: '환전 메모 (선택)',
                        hintText: '예: 통장 입금 확인 완료, 바로템 거래 등',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. 최종 정산 내역 및 실수령액 하이라이트
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.bgDark,
                            AppTheme.cardDark.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('기본 환전 총액:', style: TextStyle(color: AppTheme.textMuted)),
                              Text('${_nf.format(_grossAmount)} 원',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (_platformFeeAmount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('플랫폼 수수료 (${_platformFeeCtrl.text}%):',
                                    style: const TextStyle(color: AppTheme.accentRed)),
                                Text('- ${_nf.format(_platformFeeAmount)} 원',
                                    style: const TextStyle(
                                        color: AppTheme.accentRed, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                          if (_isWithdrawFeeApplied) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('계좌 출금 수수료:', style: TextStyle(color: AppTheme.accentRed)),
                                Text(
                                  '- ${_nf.format(int.tryParse(_withdrawFeeCtrl.text.replaceAll(',', '')) ?? 1000)} 원',
                                  style: const TextStyle(
                                      color: AppTheme.accentRed, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                          const Divider(color: AppTheme.borderDark, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '➔ 최종 실수령 금액:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGoldLight,
                                ),
                              ),
                              Text(
                                '₩ ${_nf.format(_netAmount)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 저장 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveExchangeRecord,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('환전 기록 로컬 저장', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 지난 환전 기록 목록
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: AppTheme.primaryGoldLight, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '환전 히스토리 (${records.length}건)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (records.isNotEmpty)
                  Text(
                    '총 실수령: ₩ ${_nf.format(records.fold<int>(0, (sum, r) => sum + r.netKrwAmount))}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGreen,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (records.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('저장된 환전 내역이 없습니다.', style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final date = record.createdAt.split('T').first;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.paid, color: AppTheme.primaryGold, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${_nf.format(record.currencyAmount)} ${record.currencyName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '[$date]',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${record.characterName} (${record.serverName}) | 1개당 ${record.exchangeRate}원 | 출금수수료: ${record.isWithdrawFeeApplied ? "적용(${_nf.format(record.withdrawFee)}원)" : "미적용"}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                                if (record.memo != null && record.memo!.isNotEmpty)
                                  Text(
                                    record.memo!,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryGoldLight),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₩ ${_nf.format(record.netKrwAmount)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.accentRed),
                                tooltip: '기록 삭제',
                                onPressed: () => provider.deleteExchangeRecord(record.id!),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _saveExchangeRecord() {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0.0;
    final feeRate = double.tryParse(_platformFeeCtrl.text.trim()) ?? 0.0;
    final withdrawFee = int.tryParse(_withdrawFeeCtrl.text.replaceAll(',', '').trim()) ?? 1000;

    if (amount <= 0 || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재화 수량과 환율을 올바르게 입력해 주세요.')),
      );
      return;
    }

    final provider = context.read<SsalProvider>();
    final charName = provider.selectedCharacter?.name ?? '캐릭터 미지정';
    final serverName = provider.selectedServer?.name ?? '서버 미지정';

    final record = ExchangeRecordModel(
      characterId: provider.selectedCharacter?.id,
      characterName: charName,
      serverName: serverName,
      currencyName: '다이아',
      currencyAmount: amount,
      exchangeRate: rate,
      grossAmount: _grossAmount,
      feeRate: feeRate,
      feeAmount: _platformFeeAmount,
      isWithdrawFeeApplied: _isWithdrawFeeApplied,
      withdrawFee: withdrawFee,
      netKrwAmount: _netAmount,
      memo: _memoCtrl.text.trim().isNotEmpty ? _memoCtrl.text.trim() : null,
    );

    provider.addExchangeRecord(record);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✔ 환전 기록이 로컬 저장소에 안전하게 저장되었습니다.'),
        backgroundColor: AppTheme.surfaceDark,
      ),
    );

    _memoCtrl.clear();
  }
}
