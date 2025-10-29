class Picking {
  final int id;
  final String name;
  final String date;
  final String partnerName;
  final List<PickingLine> lines;

  Picking({
    required this.id,
    required this.name,
    required this.date,
    required this.partnerName,
    required this.lines,
  });

  factory Picking.fromJson(Map<String, dynamic> json) {
    final pickingData = json['picking'] as Map<String, dynamic>;
    final linesData = json['lines'] as List<dynamic>;
    
    return Picking(
      id: pickingData['id'],
      name: pickingData['name'],
      date: pickingData['date'],
      partnerName: pickingData['partner_name'],
      lines: linesData.map((line) => PickingLine.fromJson(line)).toList(),
    );
  }
}

class PickingLine {
  final int lineId;
  final int productId;
  final String productName;
  final String? productCode;
  final double price;
  final String uom;
  final double required;
  final double done;
  final double remain;
  final String? barcode;
  final String? location;
  final String? locationComplete;

  PickingLine({
    required this.lineId,
    required this.productId,
    required this.productName,
    this.productCode,
    required this.price,
    required this.uom,
    required this.required,
    required this.done,
    required this.remain,
    this.barcode,
    this.location,
    this.locationComplete,
  });

  factory PickingLine.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing PickingLine from: $json');
      
      // Спрощена обробка полів
      // Перетворюємо всі поля на безпечні типи
      
      // Функція для безпечного отримання цілого числа
      int safeInt(dynamic value, String fieldName, {int defaultValue = 0}) {
        if (value == null) {
          print('Warning: $fieldName is null, using default: $defaultValue');
          return defaultValue;
        } else if (value is int) {
          return value;
        } else if (value is String) {
          try {
            return int.parse(value);
          } catch (e) {
            print('Warning: $fieldName is not a valid int string: $value');
            return defaultValue;
          }
        } else if (value is bool) {
          final result = value ? 1 : 0;
          print('Warning: $fieldName is boolean, converted to int: $result');
          return result;
        } else if (value is double) {
          return value.toInt();
        } else {
          print('Warning: $fieldName is not a valid int type: $value (${value.runtimeType})');
          return defaultValue;
        }
      }
      
      // Функція для безпечного отримання дійсного числа
      double safeDouble(dynamic value, String fieldName, {double defaultValue = 0.0}) {
        if (value == null) {
          print('Warning: $fieldName is null, using default: $defaultValue');
          return defaultValue;
        } else if (value is double) {
          return value;
        } else if (value is int) {
          return value.toDouble();
        } else if (value is String) {
          try {
            return double.parse(value);
          } catch (e) {
            print('Warning: $fieldName is not a valid double string: $value');
            return defaultValue;
          }
        } else if (value is bool) {
          final result = value ? 1.0 : 0.0;
          print('Warning: $fieldName is boolean, converted to double: $result');
          return result;
        } else {
          print('Warning: $fieldName is not a valid double type: $value (${value.runtimeType})');
          return defaultValue;
        }
      }
      
      // Функція для безпечного отримання рядка
      String safeString(dynamic value, String fieldName, {String defaultValue = ''}) {
        if (value == null) {
          print('Warning: $fieldName is null, using default: $defaultValue');
          return defaultValue;
        } else if (value is String) {
          return value;
        } else {
          final result = value.toString();
          print('Warning: $fieldName is not a string, converted to string: $result');
          return result;
        }
      }
      
      // Функція для безпечного отримання нульового рядка
      String? safeNullableString(dynamic value, String fieldName) {
        if (value == null) {
          return null;
        } else if (value is String) {
          return value;
        } else {
          final result = value.toString();
          print('Warning: $fieldName is not a string, converted to string: $result');
          return result;
        }
      }
      
      // Використовуємо функції для отримання всіх полів
      final lineId = safeInt(json['line_id'], 'line_id');
      final productId = safeInt(json['product_id'], 'product_id');
      final productName = safeString(json['product_name'], 'product_name', defaultValue: 'Unknown Product');
      final productCode = safeNullableString(json['product_code'], 'product_code');
      final price = safeDouble(json['price'], 'price');
      final uom = safeString(json['uom'], 'uom', defaultValue: 'Units');
      final required = safeDouble(json['required'], 'required');
      final done = safeDouble(json['done'], 'done');
      final remain = safeDouble(json['remain'], 'remain');
      final barcode = safeNullableString(json['barcode'], 'barcode');
      final location = safeNullableString(json['location'], 'location');
      final locationComplete = safeNullableString(json['location_complete'], 'location_complete');
      
      return PickingLine(
        lineId: lineId,
        productId: productId,
        productName: productName,
        productCode: productCode,
        price: price,
        uom: uom,
        required: required,
        done: done,
        remain: remain,
        barcode: barcode,
        location: location,
        locationComplete: locationComplete,
      );
    } catch (e) {
      print('Error parsing PickingLine: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class PickingAttachResponse {
  final int pickingId;
  final String pickingName;
  final PickingLine line;
  final int totalLines;
  final int completedLines;

  PickingAttachResponse({
    required this.pickingId,
    required this.pickingName,
    required this.line,
    required this.totalLines,
    required this.completedLines,
  });

  factory PickingAttachResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing PickingAttachResponse from: $json');
      
      // Детальне логування типів даних
      print('picking type: ${json['picking']?.runtimeType}');
      print('line type: ${json['line']?.runtimeType}');
      print('order_summary type: ${json['order_summary']?.runtimeType}');
      
      // Функція для безпечного отримання об'єкта Map
      Map<String, dynamic> safeMap(dynamic value, String fieldName) {
        if (value == null) {
          print('Warning: $fieldName is null, using empty map');
          return {};
        } else if (value is Map) {
          // Перетворюємо на Map<String, dynamic>
          Map<String, dynamic> result = {};
          value.forEach((key, val) {
            // Перетворюємо ключ на рядок
            String strKey = key.toString();
            // Додаємо значення в новий об'єкт
            result[strKey] = val;
          });
          return result;
        } else {
          print('Warning: $fieldName is not a Map: $value (${value.runtimeType})');
          return {};
        }
      }
      
      // Функція для безпечного отримання цілого числа
      int safeInt(dynamic value, String fieldName, {int defaultValue = 0}) {
        if (value == null) {
          print('Warning: $fieldName is null, using default: $defaultValue');
          return defaultValue;
        } else if (value is int) {
          return value;
        } else if (value is String) {
          try {
            return int.parse(value);
          } catch (e) {
            print('Warning: $fieldName is not a valid int string: $value');
            return defaultValue;
          }
        } else if (value is bool) {
          final result = value ? 1 : 0;
          print('Warning: $fieldName is boolean, converted to int: $result');
          return result;
        } else if (value is double) {
          return value.toInt();
        } else {
          print('Warning: $fieldName is not a valid int type: $value (${value.runtimeType})');
          return defaultValue;
        }
      }
      
      // Функція для безпечного отримання рядка
      String safeString(dynamic value, String fieldName, {String defaultValue = ''}) {
        if (value == null) {
          print('Warning: $fieldName is null, using default: $defaultValue');
          return defaultValue;
        } else if (value is String) {
          return value;
        } else {
          final result = value.toString();
          print('Warning: $fieldName is not a string, converted to string: $result');
          return result;
        }
      }
      
      // Безпечне отримання об'єктів
      final pickingData = safeMap(json['picking'], 'picking');
      final lineData = safeMap(json['line'], 'line');
      final orderSummary = safeMap(json['order_summary'], 'order_summary');
      
      // Логування полів
      print('pickingData fields:');
      pickingData.forEach((key, value) {
        print('  $key: $value (${value?.runtimeType})');
      });
      
      print('lineData fields:');
      lineData.forEach((key, value) {
        print('  $key: $value (${value?.runtimeType})');
      });
      
      print('orderSummary fields:');
      orderSummary.forEach((key, value) {
        print('  $key: $value (${value?.runtimeType})');
      });
      
      // Використовуємо функції для отримання всіх полів
      final pickingId = safeInt(pickingData['id'], 'pickingId');
      final pickingName = safeString(pickingData['name'], 'pickingName', defaultValue: 'Unknown');
      
      // Створюємо об'єкт PickingLine
      PickingLine line;
      try {
        line = PickingLine.fromJson(lineData);
      } catch (e) {
        print('Error creating PickingLine: $e');
        // Створюємо замісний об'єкт
        line = PickingLine(
          lineId: 0,
          productId: 0,
          productName: 'Unknown Product',
          price: 0.0,
          uom: 'Units',
          required: 1.0,
          done: 0.0,
          remain: 1.0,
        );
      }
      
      // Отримуємо значення totalLines та completedLines
      final totalLines = safeInt(orderSummary['total_lines'], 'totalLines');
      final completedLines = safeInt(orderSummary['completed_lines'], 'completedLines');
      
      return PickingAttachResponse(
        pickingId: pickingId,
        pickingName: pickingName,
        line: line,
        totalLines: totalLines,
        completedLines: completedLines,
      );
    } catch (e) {
      print('Error parsing PickingAttachResponse: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}
