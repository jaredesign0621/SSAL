import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ssal_provider.dart';
import '../models/game_model.dart';
import '../models/server_model.dart';
import '../theme/app_theme.dart';
import 'character_manage_screen.dart';

class GameServerScreen extends StatelessWidget {
  const GameServerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SsalProvider>();

    return Scaffold(
      body: provider.games.isEmpty
          ? _buildEmptyView(context)
          : Row(
              children: [
                // 왼쪽: 게임(대그룹) 목록 사이드바
                SizedBox(
                  width: 140,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceDark,
                      border: Border(
                        right: BorderSide(color: AppTheme.borderDark, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddGameDialog(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('게임 추가', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                        const Divider(color: AppTheme.borderDark, height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: provider.games.length,
                            itemBuilder: (context, index) {
                              final game = provider.games[index];
                              final isSelected = provider.selectedGame?.id == game.id;
                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: AppTheme.primaryGold.withOpacity(0.15),
                                title: Text(
                                  game.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.primaryGoldLight : AppTheme.textLight,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isSelected
                                    ? PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 16, color: AppTheme.textMuted),
                                        padding: EdgeInsets.zero,
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _showEditGameDialog(context, game);
                                          } else if (val == 'delete') {
                                            _confirmDeleteGame(context, game);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 16, color: AppTheme.primaryGold),
                                                SizedBox(width: 8),
                                                Text('게임 수정', style: TextStyle(fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, size: 16, color: AppTheme.accentRed),
                                                SizedBox(width: 8),
                                                Text('게임 삭제', style: TextStyle(fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                                onTap: () => provider.selectGame(game),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 오른쪽: 선택된 게임의 서버(중그룹) 및 수수료율(소그룹) 목록
                Expanded(
                  child: provider.selectedGame == null
                      ? const Center(child: Text('게임을 선택해 주세요.'))
                      : _buildServerSection(context, provider),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videogame_asset_outlined, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text(
            '등록된 게임이 없습니다.',
            style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddGameDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('첫 번째 게임 등록하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSection(BuildContext context, SsalProvider provider) {
    final game = provider.selectedGame!;
    final servers = provider.servers;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 게임 명칭 및 서버 추가 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    if (game.memo != null && game.memo!.isNotEmpty)
                      Text(
                        game.memo!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddServerDialog(context, game.id!),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('서버 추가', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '서버 목록 & 거래소 수수료율 설정',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryGoldLight),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: servers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.dns_outlined, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          '${game.name}에 등록된 서버가 없습니다.',
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showAddServerDialog(context, game.id!),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('서버 등록하기'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      final isSelected = provider.selectedServer?.id == server.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryGold : AppTheme.borderDark,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            provider.selectServer(server);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CharacterManageScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceDark,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.dns, color: AppTheme.primaryGoldLight, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        server.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textLight,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentGreen.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
                                            ),
                                            child: Text(
                                              '수수료율: ${server.feeRate.toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.accentGreen,
                                              ),
                                            ),
                                          ),
                                          if (server.memo != null && server.memo!.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                server.memo!,
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGold.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '캐릭터 관리',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGoldLight,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(Icons.chevron_right, size: 14, color: AppTheme.primaryGoldLight),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: AppTheme.textMuted),
                                  tooltip: '서버 & 수수료 수정',
                                  onPressed: () => _showEditServerDialog(context, server),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.accentRed),
                                  tooltip: '서버 삭제',
                                  onPressed: () => _confirmDeleteServer(context, server),
                                ),
                              ],
                            ),
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

  // --- 대화상자: 게임 추가 ---
  void _showAddGameDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final memoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('신규 게임 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '게임 이름 *',
                hintText: '예: 오딘, 리니지M, 로스트아크',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memoCtrl,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                hintText: '장르 또는 설명',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                ctx.read<SsalProvider>().addGame(name, memoCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // --- 대화상자: 게임 수정 ---
  void _showEditGameDialog(BuildContext context, GameModel game) {
    final nameCtrl = TextEditingController(text: game.name);
    final memoCtrl = TextEditingController(text: game.memo ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게임 정보 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '게임 이름 *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memoCtrl,
              decoration: const InputDecoration(labelText: '메모'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final updated = game.copyWith(name: name, memo: memoCtrl.text.trim());
                ctx.read<SsalProvider>().updateGame(updated);
                Navigator.pop(ctx);
              }
            },
            child: const Text('수정 완료'),
          ),
        ],
      ),
    );
  }

  // --- 게임 삭제 확인 ---
  void _confirmDeleteGame(BuildContext context, GameModel game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게임 삭제', style: TextStyle(color: AppTheme.accentRed)),
        content: Text('\'${game.name}\' 게임과 하위 등록된 모든 서버, 캐릭터, 재화 정보가 함께 삭제됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              ctx.read<SsalProvider>().deleteGame(game.id!);
              Navigator.pop(ctx);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 대화상자: 서버 추가 & 수수료율 설정 ---
  void _showAddServerDialog(BuildContext context, int gameId) {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '5.0');
    final memoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('서버 추가 및 수수료 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '서버 이름 *',
                  hintText: '예: 1서버, 오딘01, 루페온',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '거래소 수수료율 (%) *',
                  hintText: '예: 5.0 (5% 적용 시)',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '※ 아이템 등록 시 이 수수료율이 실수령액 계산에 자동 반영됩니다.',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoCtrl,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: '도시 서버, 시세 특이사항 등',
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
              final fee = double.tryParse(feeCtrl.text.trim()) ?? 5.0;
              if (name.isNotEmpty) {
                ctx.read<SsalProvider>().addServer(
                      gameId: gameId,
                      name: name,
                      feeRate: fee,
                      memo: memoCtrl.text.trim(),
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

  // --- 대화상자: 서버 수정 & 수수료율 수정 ---
  void _showEditServerDialog(BuildContext context, ServerModel server) {
    final nameCtrl = TextEditingController(text: server.name);
    final feeCtrl = TextEditingController(text: server.feeRate.toString());
    final memoCtrl = TextEditingController(text: server.memo ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('서버 & 수수료율 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '서버 이름 *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '거래소 수수료율 (%) *',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoCtrl,
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
              final fee = double.tryParse(feeCtrl.text.trim()) ?? server.feeRate;
              if (name.isNotEmpty) {
                final updated = server.copyWith(
                  name: name,
                  feeRate: fee,
                  memo: memoCtrl.text.trim(),
                );
                ctx.read<SsalProvider>().updateServer(updated);
                Navigator.pop(ctx);
              }
            },
            child: const Text('수정 완료'),
          ),
        ],
      ),
    );
  }

  // --- 서버 삭제 확인 ---
  void _confirmDeleteServer(BuildContext context, ServerModel server) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('서버 삭제', style: TextStyle(color: AppTheme.accentRed)),
        content: Text('\'${server.name}\' 서버와 등록된 모든 캐릭터, 재화 데이터가 함께 삭제됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              ctx.read<SsalProvider>().deleteServer(server.id!);
              Navigator.pop(ctx);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
