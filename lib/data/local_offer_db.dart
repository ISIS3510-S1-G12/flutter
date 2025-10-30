import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/offer.dart';

class OfferDB {
  static final OfferDB _instance = OfferDB._internal();
  factory OfferDB() => _instance;
  OfferDB._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'offers.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offers(
            localId INTEGER PRIMARY KEY AUTOINCREMENT,
            restaurant_id TEXT,
            title TEXT,
            description TEXT,
            discount_percentage REAL,
            price REAL,
            createdAt TEXT,
            synced INTEGER
          )
        ''');
      },
    );
  }

  Future<int> insertOffer(Offer offer) async {
    final db = await database;
    return await db.insert('offers', offer.toLocalMap());
  }

  Future<List<Offer>> getUnsyncedOffers() async {
    final db = await database;
    final res = await db.query('offers', where: 'synced = ?', whereArgs: [0]);
    return res.map((e) => Offer.fromLocalMap(e)).toList();
  }

  Future<void> markAsSynced(int localId) async {
    final db = await database;
    await db.update(
      'offers',
      {'synced': 1},
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }
}
