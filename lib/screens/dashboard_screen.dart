import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ssal_provider.dart';
import '../widgets/ssal_app_bar.dart';
import '../theme/app_theme.dart';
import 'game_server_screen.dart';
import 'character_manage_screen.dart';
import 'market_calculator_screen.dart';
import 'exchange_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SsalProvider>();

    final List<Widget> screens = [
      _buildHomeOverview(context, provider),
      const GameServerScreen(),
      const CharacterManageScreen(),
      const MarketCalculatorScreen(),
      const ExchangeScreen(),
    ];

    return Scaffold(
      appBar: SsalAppBar(
        actions: [
          // 상단: 오프라인 모드 상태 표시 뱃지
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, size: 14, color: AppTheme.accentGreen),
                SizedBox(width: 5),
                Text(
                  '오프라인 DB',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.textMuted),
            tooltip: '앱 정보',
            onPressed: () => _showAppInfoDialog(context),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceDark,
          selectedItemColor: AppTheme.primaryGoldLight,
          unselectedItemColor: AppTheme.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dns_outlined),
              activeIcon: Icon(Icons.dns),
              label: '게임/서버',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '캐릭터/재화',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: '거래소 계산',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.currency_exchange),
              activeIcon: Icon(Icons.currency_exchange),
              label: '환전/출금',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeOverview(BuildContext context, SsalProvider provider) {
    final nf = NumberFormat('#,###');
    final game = provider.selectedGame;
    final server = provider.selectedServer;
    final char = provider.selectedCharacter;

    final totalExchangedKrw = provider.exchangeRecords
        .fold<int>(0, (sum, r) => sum + r.netKrwAmount);

    final totalMarketItems = provider.allMarketItems.length;
    final activeMarketItems = provider.allMarketItems
        .where((i) => i.status == '판매중')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 웰컴 브랜딩 배너
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B2011), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.agriculture_rounded,
                    color: AppTheme.primaryGoldLight,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SSAL (쌀) 게임 자산 매니저',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game != null && server != null
                            ? '현재 선택: [${game.name}] ${server.name} (수수료 ${server.feeRate.toStringAsFixed(1)}%)'
                            : '게임과 서버를 선택하여 자산 및 수수료를 관리하세요.',
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryGoldLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 핵심 지표 카드 2x2 그리드
          const Text(
            '핵심 자산 현황 요약',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: '누적 환전 정산액',
                  value: '₩ ${nf.format(totalExchangedKrw)}',
                  subtitle: '${provider.exchangeRecords.length}건 거래 완료',
                  icon: Icons.paid,
                  iconColor: AppTheme.accentGreen,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: '거래소 등록 아이템',
                  value: '$activeMarketItems 건',
                  subtitle: '전체 $totalMarketItems건 중 판매중',
                  icon: Icons.storefront,
                  iconColor: AppTheme.primaryGold,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: '관리 중인 캐릭터',
                  value: '${provider.characters.length} 명',
                  subtitle: server != null ? '${server.name} 기준' : '서버 미선택',
                  icon: Icons.people_outline,
                  iconColor: AppTheme.accentBlue,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: '서버 거래 수수료',
                  value: server != null ? '${server.feeRate.toStringAsFixed(1)} %' : '0.0 %',
                  subtitle: '실수령 자동 계산 적용',
                  icon: Icons.percent,
                  iconColor: AppTheme.primaryGoldLight,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 선택된 캐릭터 보유 재화 간략 카드
          if (char != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${char.name} 보유 재화',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 2),
                  child: const Text('재화 관리 ➔', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (provider.characterCurrencies.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      '${char.name}에 등록된 재화가 없습니다.',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: provider.characterCurrencies.map((c) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            const Icon(Icons.diamond, color: AppTheme.primaryGoldLight, size: 18),
                            const SizedBox(width: 8),
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text(
                              '${nf.format(c.amount)} 개',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],

          // 빠른 실행 메뉴 버튼들
          const Text(
            '빠른 작업',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _currentIndex = 3),
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('거래소 아이템 등록'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _currentIndex = 4),
                  icon: const Icon(Icons.currency_exchange, size: 16),
                  label: const Text('재화 현금 환전'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  Icon(icon, color: iconColor, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.agriculture_rounded, color: AppTheme.primaryGold),
            SizedBox(width: 8),
            Text('SSAL 정보', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('버전: 1.0.0 (오프라인 퍼스트)'),
            SizedBox(height: 6),
            Text('저장소: SQLite 로컬 데이터베이스'),
            SizedBox(height: 6),
            Text('특징: 인터넷 연결 없이 모든 자산/수수료 계산 및 저장'),
            SizedBox(height: 10),
            Text(
              '※ 데이터는 기기 내부 로컬 저장소에 안전하게 보관됩니다.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
