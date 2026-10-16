import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/game_model.dart';
import '../models/server_model.dart';
import '../models/character_model.dart';
import '../models/currency_model.dart';
import '../models/market_item_model.dart';
import '../models/exchange_record_model.dart';

class SsalProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<GameModel> _games = [];
  List<GameModel> get games => _games;

  GameModel? _selectedGame;
  GameModel? get selectedGame => _selectedGame;

  List<ServerModel> _servers = [];
  List<ServerModel> get servers => _servers;

  ServerModel? _selectedServer;
  ServerModel? get selectedServer => _selectedServer;

  List<CharacterModel> _characters = [];
  List<CharacterModel> get characters => _characters;

  CharacterModel? _selectedCharacter;
  CharacterModel? get selectedCharacter => _selectedCharacter;

  List<CurrencyModel> _characterCurrencies = [];
  List<CurrencyModel> get characterCurrencies => _characterCurrencies;

  List<MarketItemModel> _characterMarketItems = [];
  List<MarketItemModel> get characterMarketItems => _characterMarketItems;

  List<ExchangeRecordModel> _exchangeRecords = [];
  List<ExchangeRecordModel> get exchangeRecords => _exchangeRecords;

  // 전체 거래소 아이템 (대시보드 표시용)
  List<MarketItemModel> _allMarketItems = [];
  List<MarketItemModel> get allMarketItems => _allMarketItems;

  // 초기 로드
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _games = await _dbHelper.getGames();
      _exchangeRecords = await _dbHelper.getExchangeRecords();
      _allMarketItems = await _dbHelper.getAllMarketItems();

      if (_games.isNotEmpty) {
        _selectedGame = _games.first;
        await _loadServersForGame(_selectedGame!.id!);
      } else {
        _selectedGame = null;
        _servers = [];
        _selectedServer = null;
        _characters = [];
        _selectedCharacter = null;
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 게임 관리 ---
  Future<void> selectGame(GameModel game) async {
    _selectedGame = game;
    await _loadServersForGame(game.id!);
    notifyListeners();
  }

  Future<void> _loadServersForGame(int gameId) async {
    _servers = await _dbHelper.getServersByGame(gameId);
    if (_servers.isNotEmpty) {
      _selectedServer = _servers.first;
      await _loadCharactersForServer(_selectedServer!.id!);
    } else {
      _selectedServer = null;
      _characters = [];
      _selectedCharacter = null;
      _characterCurrencies = [];
      _characterMarketItems = [];
    }
  }

  Future<void> addGame(String name, String? memo) async {
    final newGame = GameModel(name: name, memo: memo);
    final id = await _dbHelper.insertGame(newGame);
    _games = await _dbHelper.getGames();
    final created = _games.firstWhere((g) => g.id == id, orElse: () => newGame);
    await selectGame(created);
  }

  Future<void> updateGame(GameModel game) async {
    await _dbHelper.updateGame(game);
    _games = await _dbHelper.getGames();
    if (_selectedGame?.id == game.id) {
      _selectedGame = game;
    }
    notifyListeners();
  }

  Future<void> deleteGame(int gameId) async {
    await _dbHelper.deleteGame(gameId);
    _games = await _dbHelper.getGames();
    if (_games.isNotEmpty) {
      await selectGame(_games.first);
    } else {
      _selectedGame = null;
      _servers = [];
      _selectedServer = null;
      _characters = [];
      _selectedCharacter = null;
      _characterCurrencies = [];
      _characterMarketItems = [];
    }
    await refreshGlobalData();
    notifyListeners();
  }

  // --- 서버 관리 (수수료율 포함) ---
  Future<void> selectServer(ServerModel server) async {
    _selectedServer = server;
    await _loadCharactersForServer(server.id!);
    notifyListeners();
  }

  Future<void> _loadCharactersForServer(int serverId) async {
    _characters = await _dbHelper.getCharactersByServer(serverId);
    if (_characters.isNotEmpty) {
      await selectCharacter(_characters.first);
    } else {
      _selectedCharacter = null;
      _characterCurrencies = [];
      _characterMarketItems = [];
    }
  }

  Future<void> addServer({
    required int gameId,
    required String name,
    required double feeRate,
    String? memo,
  }) async {
    final newServer = ServerModel(
      gameId: gameId,
      name: name,
      feeRate: feeRate,
      memo: memo,
    );
    await _dbHelper.insertServer(newServer);
    if (_selectedGame != null) {
      await _loadServersForGame(_selectedGame!.id!);
    }
    notifyListeners();
  }

  Future<void> updateServer(ServerModel server) async {
    await _dbHelper.updateServer(server);
    if (_selectedGame != null) {
      _servers = await _dbHelper.getServersByGame(_selectedGame!.id!);
      _selectedServer = _servers.firstWhere((s) => s.id == server.id, orElse: () => server);
    }
    notifyListeners();
  }

  Future<void> deleteServer(int serverId) async {
    await _dbHelper.deleteServer(serverId);
    if (_selectedGame != null) {
      await _loadServersForGame(_selectedGame!.id!);
    }
    await refreshGlobalData();
    notifyListeners();
  }

  // --- 캐릭터 & 계정 관리 ---
  Future<void> selectCharacter(CharacterModel character) async {
    _selectedCharacter = character;
    await loadCharacterDetails(character.id!);
    notifyListeners();
  }

  Future<void> loadCharacterDetails(int characterId) async {
    _characterCurrencies = await _dbHelper.getCurrenciesByCharacter(characterId);
    _characterMarketItems = await _dbHelper.getMarketItemsByCharacter(characterId);
  }

  Future<void> addCharacter({
    required int serverId,
    required String name,
    required String accountInfo,
    String? note,
  }) async {
    final newChar = CharacterModel(
      serverId: serverId,
      name: name,
      accountInfo: accountInfo,
      note: note,
    );
    final id = await _dbHelper.insertCharacter(newChar);
    if (_selectedServer != null) {
      _characters = await _dbHelper.getCharactersByServer(_selectedServer!.id!);
      final found = _characters.firstWhere((c) => c.id == id, orElse: () => newChar);
      await selectCharacter(found);
    }
    notifyListeners();
  }

  Future<void> updateCharacter(CharacterModel character) async {
    await _dbHelper.updateCharacter(character);
    if (_selectedServer != null) {
      _characters = await _dbHelper.getCharactersByServer(_selectedServer!.id!);
      if (_selectedCharacter?.id == character.id) {
        _selectedCharacter = character;
      }
    }
    notifyListeners();
  }

  Future<void> deleteCharacter(int characterId) async {
    await _dbHelper.deleteCharacter(characterId);
    if (_selectedServer != null) {
      await _loadCharactersForServer(_selectedServer!.id!);
    }
    await refreshGlobalData();
    notifyListeners();
  }

  // --- 재화 관리 ---
  Future<void> addCurrency({
    required int characterId,
    required String name,
    required int amount,
  }) async {
    final currency = CurrencyModel(
      characterId: characterId,
      name: name,
      amount: amount,
    );
    await _dbHelper.insertCurrency(currency);
    _characterCurrencies = await _dbHelper.getCurrenciesByCharacter(characterId);
    notifyListeners();
  }

  Future<void> updateCurrencyAmount(int currencyId, int newAmount) async {
    if (_selectedCharacter == null) return;
    final index = _characterCurrencies.indexWhere((c) => c.id == currencyId);
    if (index != -1) {
      final updated = _characterCurrencies[index].copyWith(
        amount: newAmount,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _dbHelper.updateCurrency(updated);
      _characterCurrencies = await _dbHelper.getCurrenciesByCharacter(_selectedCharacter!.id!);
      notifyListeners();
    }
  }

  Future<void> deleteCurrency(int currencyId) async {
    if (_selectedCharacter == null) return;
    await _dbHelper.deleteCurrency(currencyId);
    _characterCurrencies = await _dbHelper.getCurrenciesByCharacter(_selectedCharacter!.id!);
    notifyListeners();
  }

  // --- 거래소 아이템 등록 & 관리 ---
  Future<void> addMarketItem({
    required int characterId,
    required String itemName,
    required int price,
    int quantity = 1,
    required double feeRate,
  }) async {
    final netAmount = MarketItemModel.calculateNetAmount(price, quantity, feeRate);
    final item = MarketItemModel(
      characterId: characterId,
      itemName: itemName,
      price: price,
      quantity: quantity,
      feeRate: feeRate,
      netAmount: netAmount,
      status: '판매중',
    );
    await _dbHelper.insertMarketItem(item);
    _characterMarketItems = await _dbHelper.getMarketItemsByCharacter(characterId);
    _allMarketItems = await _dbHelper.getAllMarketItems();
    notifyListeners();
  }

  Future<void> updateMarketItemStatus(MarketItemModel item, String newStatus) async {
    final updated = item.copyWith(status: newStatus);
    await _dbHelper.updateMarketItem(updated);
    if (_selectedCharacter != null) {
      _characterMarketItems = await _dbHelper.getMarketItemsByCharacter(_selectedCharacter!.id!);
    }
    _allMarketItems = await _dbHelper.getAllMarketItems();
    notifyListeners();
  }

  Future<void> deleteMarketItem(int itemId) async {
    await _dbHelper.deleteMarketItem(itemId);
    if (_selectedCharacter != null) {
      _characterMarketItems = await _dbHelper.getMarketItemsByCharacter(_selectedCharacter!.id!);
    }
    _allMarketItems = await _dbHelper.getAllMarketItems();
    notifyListeners();
  }

  // --- 환전 관리 ---
  Future<void> addExchangeRecord(ExchangeRecordModel record) async {
    await _dbHelper.insertExchangeRecord(record);
    _exchangeRecords = await _dbHelper.getExchangeRecords();
    notifyListeners();
  }

  Future<void> deleteExchangeRecord(int recordId) async {
    await _dbHelper.deleteExchangeRecord(recordId);
    _exchangeRecords = await _dbHelper.getExchangeRecords();
    notifyListeners();
  }

  Future<void> refreshGlobalData() async {
    _exchangeRecords = await _dbHelper.getExchangeRecords();
    _allMarketItems = await _dbHelper.getAllMarketItems();
  }
}
