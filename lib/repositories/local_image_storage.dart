import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class LocalImageStorage {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndSaveImage(String reviewId) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/review_$reviewId.jpg';
    final saved = await File(picked.path).copy(path);
    return saved.path;
  }

  Future<File?> getImage(String path) async {
    final file = File(path);
    if (await file.exists()) return file;
    return null;
  }
}
