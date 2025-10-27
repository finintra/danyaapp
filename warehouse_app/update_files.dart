import 'dart:io';

void main() async {
  // Шляхи до файлів
  final storageServicePath = 'lib/services/storage_service.dart';
  final mainPath = 'lib/main.dart';
  final apiServicePath = 'lib/services/api_service.dart';
  final pinEntryScreenPath = 'lib/screens/pin_entry_screen.dart';
  final authProviderPath = 'lib/providers/auth_provider.dart';
  
  // Тимчасові файли
  final storageServiceTempPath = 'lib/services/storage_service_temp.dart';
  final mainTempPath = 'lib/main_temp.dart';
  final apiServiceTempPath = 'lib/services/api_service_temp.dart';
  final pinEntryScreenTempPath = 'lib/screens/pin_entry_screen_temp.dart';
  final authProviderTempPath = 'lib/providers/auth_provider_temp.dart';
  
  try {
    // Копіюємо вміст тимчасових файлів у основні файли
    if (await File(storageServiceTempPath).exists()) {
      await File(storageServiceTempPath).copy(storageServicePath);
      print('✅ Updated $storageServicePath');
    } else {
      print('❌ File $storageServiceTempPath not found');
    }
    
    if (await File(mainTempPath).exists()) {
      await File(mainTempPath).copy(mainPath);
      print('✅ Updated $mainPath');
    } else {
      print('❌ File $mainTempPath not found');
    }
    
    if (await File(apiServiceTempPath).exists()) {
      await File(apiServiceTempPath).copy(apiServicePath);
      print('✅ Updated $apiServicePath');
    } else {
      print('❌ File $apiServiceTempPath not found');
    }
    
    if (await File(pinEntryScreenTempPath).exists()) {
      await File(pinEntryScreenTempPath).copy(pinEntryScreenPath);
      print('✅ Updated $pinEntryScreenPath');
    } else {
      print('❌ File $pinEntryScreenTempPath not found');
    }
    
    if (await File(authProviderTempPath).exists()) {
      await File(authProviderTempPath).copy(authProviderPath);
      print('✅ Updated $authProviderPath');
    } else {
      print('❌ File $authProviderTempPath not found');
    }
    
    print('\n✨ All files updated successfully!');
    print('Now run: flutter build apk');
  } catch (e) {
    print('❌ Error updating files: $e');
  }
}
