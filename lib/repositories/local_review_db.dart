import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:moviles/models/review.dart';

class LocalReviewDB {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'reviews.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reviews(
            id TEXT PRIMARY KEY,
            comment TEXT,
            stars INTEGER,
            userId TEXT,
            restaurantId TEXT,
            dishId TEXT,
            imageUrl TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertReview(Review review) async {
    final db = await database;
    await db.insert('reviews', review.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Review>> getReviewsByRestaurant(String restaurantId) async {
    final db = await database;
    final res = await db.query(
      'reviews',
      where: 'restaurantId = ?',
      whereArgs: [restaurantId],
    );
    return res.map((e) => Review.fromJson(e)).toList();
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete('reviews');
  }
}
