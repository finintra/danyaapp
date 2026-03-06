# Інструкція для завантаження гілки claude/web-app-frontend-NZLYe

## Виконайте ці команди в терміналі:

```bash
# Перейдіть в директорію проекту
cd /Users/arseniyfinberg/Downloads/whapp

# Якщо це не git репозиторій, ініціалізуйте його
git init

# Додайте remote (якщо його немає)
git remote add origin https://github.com/finintra/whapp2.git

# Або оновіть існуючий remote
git remote set-url origin https://github.com/finintra/whapp2.git

# Отримайте дані з GitHub
git fetch origin

# Переключіться на гілку (створить локально якщо не існує)
git checkout -b claude/web-app-frontend-NZLYe origin/claude/web-app-frontend-NZLYe

# Або якщо гілка вже існує локально:
git checkout claude/web-app-frontend-NZLYe
git pull origin claude/web-app-frontend-NZLYe
```

## Або виконайте скрипт:

```bash
cd /Users/arseniyfinberg/Downloads/whapp
chmod +x pull_branch.sh
./pull_branch.sh
```

Після виконання всі файли з гілки будуть в поточній директорії.
