import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ssal_provider.dart';
import '../models/market_item_model.dart';
import '../theme/app_theme.dart';

class MarketCalculatorScreen extends StatelessWidget {
  const MarketCalculatorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SsalProvider>();
    final numberFormat = NumberFormat('#,###');

    if (provider.selectedCharacter == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, size: 54, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              '선택된 캐릭터가 없습니다.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '[캐릭터 관리] 탭에서 캐릭터를 먼저 선택해 주세요.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final char = provider.selectedCharacter!;
    final server = provider.selectedServer!;
    final items = provider.characterMarketItems;

    // 통계 계산: 등록된 전체 예상 실수령액 합계
    final totalExpectedNet = items
        .where((item) => item.status == '판매중')
        .fold<int>(0, (sum, item) => sum + item.netAmount);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 요약 카드: 캐릭터명, 현재 적용 수수료율, 판매중 총 예상 실수령액
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderDark),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.cardDark,
                      AppTheme.surfaceDark.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${char.name} 의 거래소 등록함',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.primaryGoldLight.withOpacity(0.5)),
                                ),
                                child: Text(
                                  '서버 수수료: ${server.feeRate.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGoldLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '서버: ${server.name} | 계정: ${char.accountInfo}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '판매중 예상 실수령 총합',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        Text(
                          '${numberFormat.format(totalExpectedNet)} 재화',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 액션 바: 아이템 추가 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '등록된 거래소 아이템 (${items.length}개)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddMarketItemDialog(context, char.id!, server.feeRate),
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('새 아이템 등록', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 아이템 리스트
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            '거래소에 등록된 아이템이 없습니다.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '우측 상단 [새 아이템 등록] 버튼을 눌러 아이템과 가격을 입력해 보세요.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSold = item.status == '판매완료';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSold ? AppTheme.accentGreen.withOpacity(0.4) : AppTheme.borderDark,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                // 상태 뱃지
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSold
                                        ? AppTheme.accentGreen.withOpacity(0.2)
                                        : AppTheme.primaryGold.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSold ? AppTheme.accentGreen : AppTheme.primaryGoldLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // 아이템 명 및 수량
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '단가 ${numberFormat.format(item.price)} × ${item.quantity}개 = 총 ${numberFormat.format(item.price * item.quantity)} (수수료 ${item.feeRate.toStringAsFixed(1)}%)',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 실수령액 표시 (핵심 요구사항)
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        '실수령액',
                                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                      ),
                                      Text(
                                        '${numberFormat.format(item.netAmount)} 재화',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.accentGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 팝업 메뉴: 판매완료 처리, 삭제
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
                                  onSelected: (val) {
                                    if (val == 'toggle_status') {
                                      final newStatus = item.status == '판매중' ? '판매완료' : '판매중';
                                      provider.updateMarketItemStatus(item, newStatus);
                                    } else if (val == 'delete') {
                                      provider.deleteMarketItem(item.id!);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(
                                      value: 'toggle_status',
                                      child: Text(
                                        item.status == '판매중' ? '✔ 판매완료 처리' : '↩ 판매중으로 변경',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        '아이템 삭제',
                                        style: TextStyle(fontSize: 13, color: AppTheme.accentRed),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 거래소 아이템 등록 다이얼로그 (수수료 자동 계산 & 우측 실수령액 표시) ---
  void _showAddMarketItemDialog(BuildContext context, int characterId, double serverFeeRate) {
    showDialog(
      context: context,
      builder: (ctx) => _AddMarketItemModal(
        characterId: characterId,
        serverFeeRate: serverFeeRate,
      ),
    );
  }
}

class _AddMarketItemModal extends StatefulWidget {
  final int characterId;
  final double serverFeeRate;

  const _AddMarketItemModal({
    Key? key,
    required this.characterId,
    required this.serverFeeRate,
  }) : super(key: key);

  @override
  State<_AddMarketItemModal> createState() => _AddMarketItemModalState();
}

class _AddMarketItemModalState extends State<_AddMarketItemModal> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  late TextEditingController _feeCtrl;

  int _totalAmount = 0;
  int _feeAmount = 0;
  int _netAmount = 0;

  final NumberFormat _nf = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _feeCtrl = TextEditingController(text: widget.serverFeeRate.toStringAsFixed(1));
    _priceCtrl.addListener(_recalculate);
    _quantityCtrl.addListener(_recalculate);
    _feeCtrl.addListener(_recalculate);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  void _recalculate() {
    final price = int.tryParse(_priceCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final quantity = int.tryParse(_quantityCtrl.text.replaceAll(',', '').trim()) ?? 1;
    final feeRate = double.tryParse(_feeCtrl.text.trim()) ?? widget.serverFeeRate;

    final total = price * (quantity > 0 ? quantity : 1);
    final fee = (total * (feeRate / 100.0)).round();
    final net = total - fee;

    setState(() {
      _totalAmount = total;
      _feeAmount = fee;
      _netAmount = net > 0 ? net : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.calculate_outlined, color: AppTheme.primaryGold),
          SizedBox(width: 8),
          Text('거래소 아이템 등록 & 수수료 계산', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '아이템 이름 *',
                  hintText: '예: 축복받은 강화 주문서, 영웅 방패',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '등록 가격 (재화) *',
                        hintText: '예: 100',
                        suffixText: '재화',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '수량',
                        hintText: '1',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '적용 수수료율 (%)',
                  helperText: '해당 서버 기본 수수료율(${widget.serverFeeRate.toStringAsFixed(1)}%)이 자동 로드되었습니다.',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 16),

              // 실시간 수수료 및 실수령액 자동 계산 명세 카드
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGold.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('총 등록 금액:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        Text('${_nf.format(_totalAmount)} 재화', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('수수료 (${_feeCtrl.text}% 차감):',
                            style: const TextStyle(color: AppTheme.accentRed, fontSize: 13)),
                        Text('- ${_nf.format(_feeAmount)} 재화',
                            style: const TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(color: AppTheme.borderDark, height: 16),
                    // 요구사항: 우측에 실수령액 계산되어 강조 표시
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '➔ 실수령액:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGoldLight,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accentGreen),
                          ),
                          child: Text(
                            '${_nf.format(_netAmount)} 재화',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final price = int.tryParse(_priceCtrl.text.replaceAll(',', '').trim()) ?? 0;
            final quantity = int.tryParse(_quantityCtrl.text.replaceAll(',', '').trim()) ?? 1;
            final feeRate = double.tryParse(_feeCtrl.text.trim()) ?? widget.serverFeeRate;

            if (name.isNotEmpty && price > 0) {
              context.read<SsalProvider>().addMarketItem(
                    characterId: widget.characterId,
                    itemName: name,
                    price: price,
                    quantity: quantity > 0 ? quantity : 1,
                    feeRate: feeRate,
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
