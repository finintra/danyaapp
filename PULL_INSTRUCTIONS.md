# Інструкція для git pull з гілки claude/web-app-frontend-NZLYe

## Швидкий старт

Виконайте скрипт:
```bash
cd /Users/arseniyfinberg/Downloads/whapp
chmod +x pull_claude_branch.sh
./pull_claude_branch.sh
```

## Або виконайте команди вручну:

```bash
# Перейдіть в корінь проекту
cd /Users/arseniyfinberg/Downloads/whapp

# Перевірте, чи є git репозиторій
git status

# Перевірте remotes
git remote -v

# Якщо немає origin, додайте:
# git remote add origin https://github.com/finintra/whapp2.git

# Отримайте останні зміни з remote
git fetch origin

# Перевірте доступні гілки
git branch -r | grep claude

# Якщо гілка вже існує локально:
git checkout claude/web-app-frontend-NZLYe
git pull origin claude/web-app-frontend-NZLYe

# Якщо гілка не існує локально, створіть tracking branch:
git checkout -b claude/web-app-frontend-NZLYe origin/claude/web-app-frontend-NZLYe
```

## Якщо виникли проблеми:

### Проблема: "This is not a git repository"
```bash
git init
git remote add origin https://github.com/finintra/whapp2.git
```

### Проблема: "Couldn't find remote branch"
```bash
# Перевірте доступні гілки
git fetch origin
git branch -r

# Можливо гілка має іншу назву, знайдіть правильну:
git branch -r | grep -i "claude\|frontend\|web"
```

### Проблема: "Permission denied" або "Authentication failed"
```bash
# Переконайтесь, що маєте права доступу до репозиторію
# Можливо потрібно налаштувати SSH ключі або використати токен
```

## Після виконання:

- ✅ Локальна гілка буде синхронізована з remote
- ✅ Всі файли з remote гілки будуть завантажені
- ✅ Можна працювати з кодом локально

## Якщо виникнуть конфлікти:

```bash
# Перевірте статус
git status

# Перегляньте конфлікти
git diff

# Після вирішення конфліктів:
git add .
git commit -m "Merge changes from claude/web-app-frontend-NZLYe"
```
