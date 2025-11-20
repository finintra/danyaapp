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
      
      // Parse lineId safely
      final lineId = json['line_id'] is String ? int.parse(json['line_id']) : json['line_id'] as int;
      
      // Parse productId safely
      final productId = json['product_id'] is String ? int.parse(json['product_id']) : json['product_id'] as int;
      
      // Parse productName safely
      final productName = json['product_name'] as String;
      
      // Parse price safely
      double price;
      if (json['price'] is int) {
        price = json['price'].toDouble();
      } else if (json['price'] is double) {
        price = json['price'];
      } else if (json['price'] is String) {
        price = double.parse(json['price']);
      } else {
        price = 0.0;
      }
      
      // Parse required, done, remain safely
      double required;
      if (json['required'] is int) {
        required = json['required'].toDouble();
      } else if (json['required'] is double) {
        required = json['required'];
      } else if (json['required'] is String) {
        required = double.parse(json['required']);
      } else {
        required = 0.0;
      }
      
      double done;
      if (json['done'] is int) {
        done = json['done'].toDouble();
      } else if (json['done'] is double) {
        done = json['done'];
      } else if (json['done'] is String) {
        done = double.parse(json['done']);
      } else {
        done = 0.0;
      }
      
      double remain;
      if (json['remain'] is int) {
        remain = json['remain'].toDouble();
      } else if (json['remain'] is double) {
        remain = json['remain'];
      } else if (json['remain'] is String) {
        remain = double.parse(json['remain']);
      } else {
        remain = 0.0;
      }
      
      // Parse uom safely - can be String, bool (false), or null
      String? uom;
      if (json['uom'] is String) {
        uom = json['uom'] as String;
      } else if (json['uom'] is bool && json['uom'] == false) {
        uom = 'Units';
      } else {
        uom = 'Units';
      }
      
      // Parse productCode safely - can be String, bool (false), or null
      String? productCode;
      if (json['product_code'] is String) {
        productCode = json['product_code'] as String;
      } else {
        productCode = null;
      }
      
      // Parse barcode safely - can be String, bool (false), or null
      String? barcode;
      if (json['barcode'] is String) {
        barcode = json['barcode'] as String;
      } else {
        barcode = null;
      }
      
      // Parse location safely - can be String, bool (false), or null
      String? location;
      if (json['location'] is String) {
        location = json['location'] as String;
      } else {
        location = null;
      }
      
      // Parse locationComplete safely - can be String, bool (false), or null
      String? locationComplete;
      if (json['location_complete'] is String) {
        locationComplete = json['location_complete'] as String;
      } else {
        locationComplete = null;
      }
      
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
      
      // Check for null values
      if (json['picking'] == null) {
        throw Exception('Missing "picking" field in response');
      }
      if (json['line'] == null) {
        throw Exception('Missing "line" field in response. The picking may not have any items to pick.');
      }
      if (json['order_summary'] == null) {
        throw Exception('Missing "order_summary" field in response');
      }
      
      final pickingData = json['picking'] as Map<String, dynamic>;
      final lineData = json['line'] as Map<String, dynamic>;
      final orderSummary = json['order_summary'] as Map<String, dynamic>;
      
      final pickingId = pickingData['id'] is String ? int.parse(pickingData['id']) : pickingData['id'] as int;
      final pickingName = pickingData['name'] as String;
      
      final line = PickingLine.fromJson(lineData);
      
      final totalLines = orderSummary['total_lines'] is String ? 
          int.parse(orderSummary['total_lines']) : orderSummary['total_lines'] as int;
      
      final completedLines = orderSummary['completed_lines'] is String ? 
          int.parse(orderSummary['completed_lines']) : orderSummary['completed_lines'] as int;
      
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
