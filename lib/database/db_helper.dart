import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/game_model.dart';
import '../models/server_model.dart';
import '../models/character_model.dart';
import '../models/currency_model.dart';
import '../models/market_item_model.dart';
import '../models/exchange_record_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ssal_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Games (대그룹)
    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        memo TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Servers (중그룹 & 소그룹 옵션 수수료율)
    await db.execute('''
      CREATE TABLE servers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        fee_rate REAL NOT NULL DEFAULT 5.0,
        memo TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    // 3. Characters & Accounts
    await db.execute('''
      CREATE TABLE characters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        account_info TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE CASCADE
      )
    ''');

    // 4. Currencies per Character
    await db.execute('''
      CREATE TABLE currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');

    // 5. Market Items with Auto Net Calculation
    await db.execute('''
      CREATE TABLE market_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        price INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        fee_rate REAL NOT NULL,
        net_amount INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT '판매중',
        created_at TEXT NOT NULL,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');

    // 6. Exchange Records
    await db.execute('''
      CREATE TABLE exchange_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER,
        character_name TEXT NOT NULL,
        server_name TEXT NOT NULL,
        currency_name TEXT NOT NULL,
        currency_amount INTEGER NOT NULL,
        exchange_rate REAL NOT NULL,
        gross_amount INTEGER NOT NULL,
        fee_rate REAL NOT NULL DEFAULT 0.0,
        fee_amount INTEGER NOT NULL,
        is_withdraw_fee_applied INTEGER NOT NULL DEFAULT 0,
        withdraw_fee INTEGER NOT NULL DEFAULT 1000,
        net_krw_amount INTEGER NOT NULL,
        memo TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 초기 샘플 데이터 시딩 (첫 사용자가 바로 UI를 체험해 볼 수 있도록)
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // 샘플 게임 등록
    final gameId1 = await db.insert('games', {
      'name': '오딘: 발할라 라이징',
      'memo': '모바일 MMORPG',
      'created_at': now,
    });
    final gameId2 = await db.insert('games', {
      'name': '리니지M',
      'memo': '엔씨소프트',
      'created_at': now,
    });

    // 샘플 서버 등록 (수수료율 각각 5%, 8% 등)
    final serverId1 = await db.insert('servers', {
      'game_id': gameId1,
      'name': '오딘01 서버',
      'fee_rate': 5.0,
      'memo': '수수료 기본 5%',
      'created_at': now,
    });
    final serverId2 = await db.insert('servers', {
      'game_id': gameId1,
      'name': '토르03 서버',
      'fee_rate': 7.5,
      'memo': '수수료 7.5%',
      'created_at': now,
    });
    await db.insert('servers', {
      'game_id': gameId2,
      'name': '데포로쥬01',
      'fee_rate': 10.0,
      'memo': '거래소 10%',
      'created_at': now,
    });

    // 샘플 캐릭터 등록
    final charId1 = await db.insert('characters', {
      'server_id': serverId1,
      'name': '쌀먹장인1호',
      'account_info': 'google_game01@gmail.com',
      'note': '버서커 80레벨 본캐',
      'created_at': now,
    });
    final charId2 = await db.insert('characters', {
      'server_id': serverId1,
      'name': '부캐파밍러',
      'account_info': 'google_game02@gmail.com',
      'note': '아크메이지 72레벨 서브',
      'created_at': now,
    });

    // 샘플 재화 등록
    await db.insert('currencies', {
      'character_id': charId1,
      'name': '다이아',
      'amount': 25000,
      'updated_at': now,
    });
    await db.insert('currencies', {
      'character_id': charId1,
      'name': '골드',
      'amount': 150000000,
      'updated_at': now,
    });
    await db.insert('currencies', {
      'character_id': charId2,
      'name': '다이아',
      'amount': 8200,
      'updated_at': now,
    });

    // 샘플 거래소 등록 아이템
    // 100 다이아, 수수료 5% -> 95 실수령
    await db.insert('market_items', {
      'character_id': charId1,
      'item_name': '영웅 스킬북 (광폭화)',
      'price': 10000,
      'quantity': 1,
      'fee_rate': 5.0,
      'net_amount': 9500,
      'status': '판매중',
      'created_at': now,
    });
    await db.insert('market_items', {
      'character_id': charId1,
      'item_name': '축복받은 강화석 상자',
      'price': 100,
      'quantity': 10,
      'fee_rate': 5.0,
      'net_amount': 950,
      'status': '판매중',
      'created_at': now,
    });

    // 샘플 환전 내역
    await db.insert('exchange_records', {
      'character_id': charId1,
      'character_name': '쌀먹장인1호',
      'server_name': '오딘01 서버',
      'currency_name': '다이아',
      'currency_amount': 10000,
      'exchange_rate': 10.0, // 1다이아 = 10원
      'gross_amount': 100000,
      'fee_rate': 3.0, // 플랫폼 수수료 3%
      'fee_amount': 3000,
      'is_withdraw_fee_applied': 1,
      'withdraw_fee': 1000,
      'net_krw_amount': 96000,
      'memo': '아이템베이 안전거래 10,000 다이아 정산',
      'created_at': now,
    });
  }

  // --- CRUD: Games ---
  Future<List<GameModel>> getGames() async {
    final db = await instance.database;
    final result = await db.query('games', orderBy: 'id ASC');
    return result.map((json) => GameModel.fromMap(json)).toList();
  }

  Future<int> insertGame(GameModel game) async {
    final db = await instance.database;
    return await db.insert('games', game.toMap());
  }

  Future<int> updateGame(GameModel game) async {
    final db = await instance.database;
    return await db.update(
      'games',
      game.toMap(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  Future<int> deleteGame(int id) async {
    final db = await instance.database;
    return await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD: Servers ---
  Future<List<ServerModel>> getServersByGame(int gameId) async {
    final db = await instance.database;
    final result = await db.query(
      'servers',
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'id ASC',
    );
    return result.map((json) => ServerModel.fromMap(json)).toList();
  }

  Future<List<ServerModel>> getAllServers() async {
    final db = await instance.database;
    final result = await db.query('servers', orderBy: 'id ASC');
    return result.map((json) => ServerModel.fromMap(json)).toList();
  }

  Future<ServerModel?> getServerById(int serverId) async {
    final db = await instance.database;
    final result = await db.query(
      'servers',
      where: 'id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return ServerModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertServer(ServerModel server) async {
    final db = await instance.database;
    return await db.insert('servers', server.toMap());
  }

  Future<int> updateServer(ServerModel server) async {
    final db = await instance.database;
    return await db.update(
      'servers',
      server.toMap(),
      where: 'id = ?',
      whereArgs: [server.id],
    );
  }

  Future<int> deleteServer(int id) async {
    final db = await instance.database;
    return await db.delete(
      'servers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD: Characters ---
  Future<List<CharacterModel>> getCharactersByServer(int serverId) async {
    final db = await instance.database;
    final result = await db.query(
      'characters',
      where: 'server_id = ?',
      whereArgs: [serverId],
      orderBy: 'id ASC',
    );
    return result.map((json) => CharacterModel.fromMap(json)).toList();
  }

  Future<List<CharacterModel>> getAllCharacters() async {
    final db = await instance.database;
    final result = await db.query('characters', orderBy: 'id ASC');
    return result.map((json) => CharacterModel.fromMap(json)).toList();
  }

  Future<CharacterModel?> getCharacterById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return CharacterModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertCharacter(CharacterModel character) async {
    final db = await instance.database;
    return await db.insert('characters', character.toMap());
  }

  Future<int> updateCharacter(CharacterModel character) async {
    final db = await instance.database;
    return await db.update(
      'characters',
      character.toMap(),
      where: 'id = ?',
      whereArgs: [character.id],
    );
  }

  Future<int> deleteCharacter(int id) async {
    final db = await instance.database;
    return await db.delete(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD: Currencies ---
  Future<List<CurrencyModel>> getCurrenciesByCharacter(int characterId) async {
    final db = await instance.database;
    final result = await db.query(
      'currencies',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'id ASC',
    );
    return result.map((json) => CurrencyModel.fromMap(json)).toList();
  }

  Future<int> insertCurrency(CurrencyModel currency) async {
    final db = await instance.database;
    return await db.insert('currencies', currency.toMap());
  }

  Future<int> updateCurrency(CurrencyModel currency) async {
    final db = await instance.database;
    return await db.update(
      'currencies',
      currency.toMap(),
      where: 'id = ?',
      whereArgs: [currency.id],
    );
  }

  Future<int> deleteCurrency(int id) async {
    final db = await instance.database;
    return await db.delete(
      'currencies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD: Market Items ---
  Future<List<MarketItemModel>> getMarketItemsByCharacter(int characterId) async {
    final db = await instance.database;
    final result = await db.query(
      'market_items',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'id DESC',
    );
    return result.map((json) => MarketItemModel.fromMap(json)).toList();
  }

  Future<List<MarketItemModel>> getAllMarketItems() async {
    final db = await instance.database;
    final result = await db.query('market_items', orderBy: 'id DESC');
    return result.map((json) => MarketItemModel.fromMap(json)).toList();
  }

  Future<int> insertMarketItem(MarketItemModel item) async {
    final db = await instance.database;
    return await db.insert('market_items', item.toMap());
  }

  Future<int> updateMarketItem(MarketItemModel item) async {
    final db = await instance.database;
    return await db.update(
      'market_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteMarketItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'market_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD: Exchange Records ---
  Future<List<ExchangeRecordModel>> getExchangeRecords() async {
    final db = await instance.database;
    final result = await db.query('exchange_records', orderBy: 'id DESC');
    return result.map((json) => ExchangeRecordModel.fromMap(json)).toList();
  }

  Future<int> insertExchangeRecord(ExchangeRecordModel record) async {
    final db = await instance.database;
    return await db.insert('exchange_records', record.toMap());
  }

  Future<int> deleteExchangeRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'exchange_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
