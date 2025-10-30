import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalFileHelper {
  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/local_dishes.json');
  }

  static Future<List<Map<String, dynamic>>> readLocalDishes() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contents);
      return jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> writeLocalDishes(List<Map<String, dynamic>> dishes) async {
    final file = await _getLocalFile();
    final jsonString = jsonEncode(dishes);
    await file.writeAsString(jsonString);
  }

  static Future<void> addLocalDish(Map<String, dynamic> dish) async {
    final dishes = await readLocalDishes();
    dishes.add(dish);
    await writeLocalDishes(dishes);
  }

  static Future<void> clearLocalDishes() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
