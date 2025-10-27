import 'dart:io';

void main() async {
  // Шляхи до файлів
  final storageServicePath = 'lib/services/storage_service.dart';
  
  // Тимчасові файли
  final storageServiceSimplePath = 'lib/services/storage_service_simple.dart';
  
  try {
    // Копіюємо вміст тимчасових файлів у основні файли
    if (await File(storageServiceSimplePath).exists()) {
      await File(storageServiceSimplePath).copy(storageServicePath);
      print('✅ Updated $storageServicePath');
    } else {
      print('❌ File $storageServiceSimplePath not found');
    }
    
    print('\n✨ Simple storage implementation updated successfully!');
    print('Now run: flutter build apk');
  } catch (e) {
    print('❌ Error updating files: $e');
  }
}
