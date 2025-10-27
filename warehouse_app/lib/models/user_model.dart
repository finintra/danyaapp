class User {
  final int id;
  final String name;
  final String? login;
  final bool active;
  final int? employeeId;
  final String? pin; // PIN-код користувача з Odoo

  User({
    required this.id,
    required this.name,
    this.login,
    required this.active,
    this.employeeId,
    this.pin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('\n\n=== PARSING USER JSON ===');
    print('Full JSON: $json');
    
    // Шукаємо PIN-код в об'єкті employee
    String? pinCode;
    
    // Перевіряємо наявність об'єкта employee та поля pin в ньому
    if (json.containsKey('employee') && json['employee'] is Map) {
      final employee = json['employee'] as Map<String, dynamic>;
      print('Found employee object: $employee');
      
      if (employee.containsKey('pin') && employee['pin'] != null) {
        pinCode = employee['pin'].toString();
        print('Found PIN in employee.pin: $pinCode');
      }
    }
    
    // Якщо не знайшли в employee, перевіряємо інші можливі місця
    if (pinCode == null) {
      // Можливі назви полів для PIN-коду
      final possiblePinFields = ['pin', 'employee_pin', 'user_pin', 'badge_pin', 'security_pin'];
      
      // Перевіряємо поля в корені об'єкта користувача
      for (final field in possiblePinFields) {
        if (json.containsKey(field) && json[field] != null && json[field].toString().isNotEmpty) {
          pinCode = json[field].toString();
          print('Found PIN in user.$field: $pinCode');
          break;
        }
      }
    }
    
    // Якщо PIN-код не знайдено, повертаємо null
    if (pinCode == null) {
      print('WARNING: No PIN code found in user data');
    } else {
      print('Using PIN code from API: $pinCode');
    }
    
    print('=== END OF USER PARSING ===\n\n');
    
    return User(
      id: json['id'],
      name: json['name'],
      login: json['login'],
      active: json['active'],
      employeeId: json['employee_id'],
      pin: pinCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'login': login,
      'active': active,
      'employee_id': employeeId,
      'pin': pin,
    };
  }
}