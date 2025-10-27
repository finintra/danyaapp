# Інтеграція з бекендом

Цей документ описує, як інтегрувати мобільний додаток з бекенд-сервісом, який взаємодіє з Odoo 15.

## Налаштування URL бекенду

За замовчуванням додаток налаштований на підключення до бекенду за адресою `http://localhost:3000`. Якщо ваш бекенд запущений на іншій адресі, вам потрібно змінити значення `baseUrl` у файлі `lib/config/constants.dart`.

```dart
class AppConstants {
  // API URLs
  static const String baseUrl = 'http://192.168.1.100:3000'; // Змініть на вашу адресу
  // ...
}
```

## API ендпоінти

Додаток використовує наступні ендпоінти бекенду:

### Авторизація

- `POST /flf/api/v1/login` - Вхід за логіном і паролем
  ```json
  {
    "login": "admin",
    "password": "admin",
    "device_id": "device-123"
  }
  ```

- `POST /flf/api/v1/login_badge` - Вхід за бейджем та PIN-кодом
  ```json
  {
    "badge_barcode": "123456",
    "pin": "1234",
    "device_id": "device-123"
  }
  ```

- `GET /flf/api/v1/device/status` - Перевірка статусу пристрою
  - Потребує заголовок `Authorization: Bearer <token>`

- `POST /flf/api/v1/logout` - Вихід з системи
  - Потребує заголовок `Authorization: Bearer <token>`

### Робота з замовленнями

- `POST /flf/api/v1/task/attach` - Прив'язка до замовлення
  ```json
  {
    "picking_barcode": "OUT/00001"
  }
  ```

- `POST /flf/api/v1/scan/item` - Сканування товару
  ```json
  {
    "picking_id": 1,
    "barcode": "1234567890123"
  }
  ```

- `POST /flf/api/v1/validate` - Валідація зібраного замовлення
  ```json
  {
    "picking_id": 1,
    "payload": [
      {
        "line_id": 1,
        "product_id": 1,
        "qty": 5
      }
    ]
  }
  ```

## Формат відповіді

Всі відповіді від бекенду мають наступний формат:

### Успішна відповідь

```json
{
  "ok": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "Admin",
    "active": true
  },
  "device_id": "device-123"
}
```

### Відповідь з помилкою

```json
{
  "ok": false,
  "error": "INVALID_CREDENTIALS",
  "message": "Невірний логін або пароль"
}
```

## Тестування з'єднання

Для перевірки з'єднання з бекендом можна використати наступну команду:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get
```

Якщо бекенд працює коректно, ви отримаєте відповідь:

```json
{
  "status": "ok",
  "timestamp": "2025-10-22T12:34:56.789Z"
}
```

## Налаштування CORS

Якщо ви отримуєте помилки CORS при підключенні до бекенду, переконайтеся, що в бекенді налаштовано CORS для вашого домену або `*` для тестування.

## Логування запитів

Для налагодження проблем з підключенням до бекенду, ви можете увімкнути детальне логування HTTP-запитів, змінивши значення `LOG_LEVEL` в файлі `.env` бекенду на `debug`.

```
LOG_LEVEL=debug
```
