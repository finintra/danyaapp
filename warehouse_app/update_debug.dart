import 'dart:io';

void main() async {
  // Шляхи до файлів
  final storageServicePath = 'lib/services/storage_service.dart';
  final mainPath = 'lib/main.dart';
  
  // Тимчасові файли
  final storageServiceDebugPath = 'lib/services/storage_service_debug.dart';
  final mainDebugPath = 'lib/main_debug.dart';
  
  try {
    // Копіюємо вміст тимчасових файлів у основні файли
    if (await File(storageServiceDebugPath).exists()) {
      await File(storageServiceDebugPath).copy(storageServicePath);
      print('✅ Updated $storageServicePath');
    } else {
      print('❌ File $storageServiceDebugPath not found');
    }
    
    if (await File(mainDebugPath).exists()) {
      await File(mainDebugPath).copy(mainPath);
      print('✅ Updated $mainPath');
    } else {
      print('❌ File $mainDebugPath not found');
    }
    
    print('\n✨ Debug files updated successfully!');
    print('Now run: flutter build apk');
  } catch (e) {
    print('❌ Error updating files: $e');
  }
}
