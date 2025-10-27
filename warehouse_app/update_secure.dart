import 'dart:io';

void main() async {
  // Шляхи до файлів
  final storageServicePath = 'lib/services/storage_service.dart';
  
  // Тимчасові файли
  final storageServiceSecurePath = 'lib/services/storage_service_secure.dart';
  
  try {
    // Копіюємо вміст тимчасових файлів у основні файли
    if (await File(storageServiceSecurePath).exists()) {
      await File(storageServiceSecurePath).copy(storageServicePath);
      print('✅ Updated $storageServicePath');
    } else {
      print('❌ File $storageServiceSecurePath not found');
    }
    
    print('\n✨ Secure storage implementation updated successfully!');
    print('Now run: flutter build apk');
  } catch (e) {
    print('❌ Error updating files: $e');
  }
}
