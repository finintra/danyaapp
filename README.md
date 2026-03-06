# Odoo 15 Mobile Backend

Бекенд-сервіс для мобільного додатку, який інтегрується з Odoo 15 через REST API.

## Опис

Цей сервіс забезпечує REST API для мобільного додатку "тупого" сканера для складу під Odoo 15. Він дозволяє працівникам сканувати штрихкоди товарів у призначеному замовленні за допомогою HID-сканера.

## Технічний стек

- Node.js
- Express.js
- JWT для автентифікації
- Axios для HTTP-запитів до Odoo
- Winston для логування

## Встановлення

1. Клонуйте репозиторій
2. Встановіть залежності:

```bash
npm install
```

3. Створіть файл `.env` на основі `.env.example` та налаштуйте змінні середовища:

```bash
cp .env.example .env
```

4. Запустіть сервер:

```bash
npm start
```

Для розробки:

```bash
npm run dev
```

## API Ендпоінти

### Авторизація

- `POST /flf/api/v1/login` - Вхід за логіном і паролем
- `POST /flf/api/v1/login_badge` - Вхід за бейджем та PIN-кодом
- `GET /flf/api/v1/device/status` - Перевірка статусу пристрою
- `POST /flf/api/v1/logout` - Вихід з системи

### Робота з замовленнями

- `POST /flf/api/v1/task/attach` - Прив'язка до замовлення
- `POST /flf/api/v1/scan/item` - Сканування товару
- `POST /flf/api/v1/validate` - Валідація зібраного замовлення
- `POST /flf/api/v1/cancel_local` - Скасування локальної збірки
- `GET /flf/api/v1/tasks/available` - Отримання списку доступних замовлень
- `GET /flf/api/v1/task/:pickingId` - Отримання деталей замовлення

## Налаштування Odoo

Для роботи з цим бекендом, необхідно налаштувати Odoo 15:

1. Переконатися, що в моделі `hr.employee` правильно налаштовано поле `pin`:
   - Поле `pin` використовується для автентифікації працівників у мобільному додатку
   - PIN-код повинен бути встановлений для кожного працівника, який буде використовувати додаток

2. Додати технічні поля до моделей:
   - `x_mobile_allowed_barcodes` - кеш валідних штрихкодів
   - `x_bound_device_ids` - історія прив'язок пристроїв
   - `x_last_mobile_user_id`, `x_last_mobile_at` - для аудиту

3. Налаштувати права доступу для API-користувача

4. Переконатися, що кожен працівник має пов'язаний обліковий запис користувача (поле `user_id` в моделі `hr.employee`)

## Тестування

Запустіть тести:

```bash
npm test
```

## Backend2 - Другий бекенд для веб-додатку

Проект містить другий окремий бекенд сервіс (`backend2/`), який призначений для веб-додатку і підключається до зовнішнього Odoo сервера.

### Відмінності від основного бекенду

- **Порт**: 3002 (основний бекенд працює на 3001)
- **Odoo сервер**: Підключається до зовнішнього сервера `https://dev.odoo15.emuaport.com/`
- **Логи**: Окремі логи в директорії `backend2/logs2/`
- **Конфігурація**: Окремі змінні оточення з префіксом `BACKEND2_`

### Запуск Backend2 через Docker Compose

1. Налаштуйте змінні оточення в `.env` файлі або в `docker-compose.yml`:

```bash
BACKEND2_ODOO_URL=https://dev.odoo15.emuaport.com/
BACKEND2_ODOO_DB=your_database_name
BACKEND2_ODOO_USERNAME=your_odoo_username
BACKEND2_ODOO_PASSWORD=your_odoo_password
BACKEND2_JWT_SECRET=your-jwt-secret-key
BACKEND2_CREDENTIALS_ENCRYPTION_KEY=your-encryption-key-32-characters-long!!
```

2. Запустіть Backend2:

```bash
docker-compose up -d backend2
```

3. Backend2 буде доступний за адресою: `http://localhost:3002`

### Запуск Backend2 локально (без Docker)

1. Перейдіть в директорію `backend2/`:

```bash
cd backend2
```

2. Встановіть залежності:

```bash
npm install
```

3. Створіть файл `.env` на основі `.env.example`:

```bash
cp .env.example .env
```

4. Налаштуйте змінні оточення в `.env` файлі

5. Запустіть сервер:

```bash
npm start
```

Для розробки:

```bash
npm run dev
```

### Перегляд логів Backend2

Через Docker Compose:

```bash
docker-compose logs -f backend2
```

Або безпосередньо з файлів:
- `backend2/logs2/error.log` - помилки
- `backend2/logs2/combined.log` - всі логи

Детальніша інформація про налаштування Docker знаходиться в [DOCKER_SETUP.md](DOCKER_SETUP.md)
