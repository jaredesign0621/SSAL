import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ssal_provider.dart';
import '../models/character_model.dart';
import '../models/currency_model.dart';
import '../theme/app_theme.dart';

class CharacterManageScreen extends StatelessWidget {
  const CharacterManageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SsalProvider>();
    final numberFormat = NumberFormat('#,###');

    if (provider.selectedServer == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 54, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              '선택된 서버가 없습니다.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '먼저 [게임/서버] 탭에서 게임과 서버를 등록하거나 선택해 주세요.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final server = provider.selectedServer!;
    final characters = provider.characters;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: Text(
                '${server.name} 캐릭터 관리',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.surfaceDark,
              elevation: 0,
            )
          : null,
      body: Row(
        children: [
          // 왼쪽: 캐릭터 목록
          SizedBox(
            width: 170,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(
                  right: BorderSide(color: AppTheme.borderDark, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: AppTheme.cardDark,
                    child: Row(
                      children: [
                        const Icon(Icons.dns, size: 14, color: AppTheme.primaryGoldLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            server.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddCharacterDialog(context, server.id!),
                      icon: const Icon(Icons.person_add, size: 14),
                      label: const Text('캐릭터 등록', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      ),
                    ),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  Expanded(
                    child: characters.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                '캐릭터를 추가해 주세요.',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: characters.length,
                            itemBuilder: (context, index) {
                              final char = characters[index];
                              final isSelected = provider.selectedCharacter?.id == char.id;

                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: AppTheme.primaryGold.withOpacity(0.15),
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: isSelected ? AppTheme.primaryGold : AppTheme.cardDark,
                                  child: Text(
                                    char.name.isNotEmpty ? char.name[0] : 'C',
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : AppTheme.textLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  char.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.primaryGoldLight : AppTheme.textLight,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  char.accountInfo,
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => provider.selectCharacter(char),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          // 오른쪽: 선택된 캐릭터 상세 정보 & 보유 재화 관리
          Expanded(
            child: provider.selectedCharacter == null
                ? const Center(child: Text('캐릭터를 선택해 주세요.'))
                : _buildCharacterDetail(context, provider, numberFormat),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterDetail(
    BuildContext context,
    SsalProvider provider,
    NumberFormat numberFormat,
  ) {
    final char = provider.selectedCharacter!;
    final currencies = provider.characterCurrencies;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 캐릭터 & 연동 계정 정보 카드
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.borderDark),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGold, AppTheme.accentGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        char.name.isNotEmpty ? char.name[0] : 'U',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              char.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Text(
                                '계정: ${char.accountInfo}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.primaryGoldLight),
                              ),
                            ),
                          ],
                        ),
                        if (char.note != null && char.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            char.note!,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppTheme.textMuted),
                    tooltip: '캐릭터/계정 정보 수정',
                    onPressed: () => _showEditCharacterDialog(context, char),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.accentRed),
                    tooltip: '캐릭터 삭제',
                    onPressed: () => _confirmDeleteCharacter(context, char),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 보유 재화 관리 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monetization_on_outlined, size: 20, color: AppTheme.primaryGold),
                  SizedBox(width: 8),
                  Text(
                    '캐릭터 보유 재화 현황',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddCurrencyDialog(context, char.id!),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('재화 추가', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 재화 리스트
          Expanded(
            child: currencies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.savings_outlined, size: 40, color: AppTheme.textMuted),
                        const SizedBox(height: 8),
                        const Text(
                          '보유 재화가 등록되지 않았습니다.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _showAddCurrencyDialog(context, char.id!),
                          child: const Text('재화 (다이아, 골드 등) 등록'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: currencies.length,
                    itemBuilder: (context, index) {
                      final cur = currencies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.diamond_outlined, color: AppTheme.primaryGoldLight, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cur.name,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '수량: ${numberFormat.format(cur.amount)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.accentGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 빠른 수량 조정 버튼 (+1,000, -1,000 등)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: AppTheme.textMuted),
                                tooltip: '수량 직접 수정',
                                onPressed: () => _showEditCurrencyDialog(context, cur),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.accentRed),
                                tooltip: '재화 삭제',
                                onPressed: () => provider.deleteCurrency(cur.id!),
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
    );
  }

  // --- 대화상자: 캐릭터 추가 ---
  void _showAddCharacterDialog(BuildContext context, int serverId) {
    final nameCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('캐릭터 & 계정 등록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '캐릭터 명 *',
                  hintText: '예: 쌀먹장인1호, 버서커신',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountCtrl,
                decoration: const InputDecoration(
                  labelText: '연동 계정 정보 *',
                  hintText: '예: google01@gmail.com, 카카오계정 등',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: '레벨, 직업, 용도 등',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final account = accountCtrl.text.trim();
              if (name.isNotEmpty && account.isNotEmpty) {
                ctx.read<SsalProvider>().addCharacter(
                      serverId: serverId,
                      name: name,
                      accountInfo: account,
                      note: noteCtrl.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // --- 대화상자: 캐릭터 수정 ---
  void _showEditCharacterDialog(BuildContext context, CharacterModel character) {
    final nameCtrl = TextEditingController(text: character.name);
    final accountCtrl = TextEditingController(text: character.accountInfo);
    final noteCtrl = TextEditingController(text: character.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('캐릭터 정보 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '캐릭터 명 *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountCtrl,
                decoration: const InputDecoration(labelText: '연동 계정 정보 *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: '메모'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final account = accountCtrl.text.trim();
              if (name.isNotEmpty && account.isNotEmpty) {
                final updated = character.copyWith(
                  name: name,
                  accountInfo: account,
                  note: noteCtrl.text.trim(),
                );
                ctx.read<SsalProvider>().updateCharacter(updated);
                Navigator.pop(ctx);
              }
            },
            child: const Text('수정 완료'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCharacter(BuildContext context, CharacterModel character) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('캐릭터 삭제', style: TextStyle(color: AppTheme.accentRed)),
        content: Text('\'${character.name}\' 캐릭터와 등록된 재화 및 거래소 아이템이 삭제됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              ctx.read<SsalProvider>().deleteCharacter(character.id!);
              Navigator.pop(ctx);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 대화상자: 재화 추가 ---
  void _showAddCurrencyDialog(BuildContext context, int characterId) {
    final nameCtrl = TextEditingController(text: '다이아');
    final amountCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('보유 재화 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '재화 종류 *',
                hintText: '예: 다이아, 골드, 쌀, 루비',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '보유 수량 *',
                hintText: '예: 10000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final amount = int.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
              if (name.isNotEmpty) {
                ctx.read<SsalProvider>().addCurrency(
                      characterId: characterId,
                      name: name,
                      amount: amount,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // --- 대화상자: 재화 수량 수정 ---
  void _showEditCurrencyDialog(BuildContext context, CurrencyModel currency) {
    final amountCtrl = TextEditingController(text: currency.amount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${currency.name} 수량 수정', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '보유 수량',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            // 간편 가산 버튼 (+1,000, +10,000, -1,000)
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('+1,000'),
                  onPressed: () {
                    final curr = int.tryParse(amountCtrl.text) ?? 0;
                    amountCtrl.text = (curr + 1000).toString();
                  },
                ),
                ActionChip(
                  label: const Text('+10,000'),
                  onPressed: () {
                    final curr = int.tryParse(amountCtrl.text) ?? 0;
                    amountCtrl.text = (curr + 10000).toString();
                  },
                ),
                ActionChip(
                  label: const Text('-1,000'),
                  onPressed: () {
                    final curr = int.tryParse(amountCtrl.text) ?? 0;
                    final next = curr >= 1000 ? curr - 1000 : 0;
                    amountCtrl.text = next.toString();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? currency.amount;
              ctx.read<SsalProvider>().updateCurrencyAmount(currency.id!, amount);
              Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
