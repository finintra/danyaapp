# Інструкції з тестування системи credentials

## Що було реалізовано

1. **CredentialsService** - зберігання зашифрованих логін/пароль на 30 днів
2. **Довгострокові токени** - токени з терміном дії 30 днів
3. **Новий endpoint `/login_pin`** - вхід по PIN коду з використанням збереженого токену
4. **Автоматичне завантаження credentials** - middleware автоматично завантажує credentials при запитах

## Сценарій тестування

### 1. Перший вхід (логін/пароль)

```bash
curl -X POST http://localhost:3000/flf/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "login": "admin",
    "password": "admin",
    "device_id": "test-device-001"
  }'
```

**Очікуваний результат:**
- Отримуємо токен (термін дії 30 днів)
- Credentials зберігаються в зашифрованому вигляді
- Повертається інформація про користувача

### 2. Вхід по PIN (після першого входу)

```bash
curl -X POST http://localhost:3000/flf/api/v1/login_pin \
  -H "Content-Type: application/json" \
  -d '{
    "pin": "1234",
    "token": "YOUR_TOKEN_FROM_STEP_1"
  }'
```

**Очікуваний результат:**
- Перевіряється PIN код
- Використовуються збережені credentials для запитів до Odoo
- Повертається новий токен (оновлюється на 30 днів)

### 3. Використання токену для API запитів

```bash
curl -X GET http://localhost:3000/flf/api/v1/device/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Очікуваний результат:**
- Middleware автоматично завантажує credentials
- Запити до Odoo виконуються з credentials користувача

### 4. Автоматичний тест

Запустіть тестовий скрипт:

```bash
node test_credentials.js
```

Або вказати URL бекенду:

```bash
BASE_URL=https://danyaapp-production.up.railway.app node test_credentials.js
```

## Перевірка логів

При успішній роботі в логах має бути:
- `Stored encrypted credentials for user X`
- `Connected to Odoo with UID: X for user Y`
- `Using credentials for user Y`

## Важливі нотатки

1. **Перший вхід обов'язково через логін/пароль** - щоб зберегти credentials
2. **PIN код береться з hr.employee.pin** в Odoo
3. **Credentials шифруються** через AES-256-CBC
4. **Термін зберігання credentials: 30 днів**
5. **При логіні по бейджу** - credentials беруться з попереднього входу (якщо є)

## Troubleshooting

### Помилка "CREDENTIALS_NOT_FOUND"
- Користувач ще не входив через логін/пароль
- Credentials вже прострочені (30 днів)
- Потрібно зайти знову через логін/пароль

### Помилка "INVALID_PIN"
- Перевірте PIN код в Odoo (hr.employee.pin)
- Переконайтесь, що PIN передається правильно

### Помилка при запитах до Odoo
- Перевірте, чи credentials правильно збережені
- Перевірте лог: `Using credentials for user X`

