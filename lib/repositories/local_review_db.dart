// lib/repositories/local_review_db.dart
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
        // Tabla de reviews locales
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

        // Tabla para actualizaciones pendientes (offline)
        await db.execute('''
          CREATE TABLE pending_updates(
            reviewId TEXT PRIMARY KEY,
            comment TEXT,
            stars INTEGER,
            imageUrl TEXT
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

  // OFFLINE SYNC helpers
  Future<void> savePendingUpdate(Map<String, dynamic> update) async {
    final db = await database;
    await db.insert(
      'pending_updates',
      update,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingUpdates() async {
    final db = await database;
    return await db.query('pending_updates');
  }

  Future<void> clearPendingUpdate(String reviewId) async {
    final db = await database;
    await db.delete(
      'pending_updates',
      where: 'reviewId = ?',
      whereArgs: [reviewId],
    );
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete('reviews');
  }

  Future<void> saveReviews(List<Review> reviews) async {
    final db = await database;
    // Inserta/actualiza cada review; evita eliminar otras entradas
    final batch = db.batch();
    for (final r in reviews) {
      batch.insert(
        "reviews",
        {
          "id": r.id,
          "comment": r.comment,
          "stars": r.stars,
          "userId": r.userId,
          "restaurantId": r.restaurantId,
          "dishId": r.dishId,
          "imageUrl": r.imageUrl,
          "createdAt": r.createdAt?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
