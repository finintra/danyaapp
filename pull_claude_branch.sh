#!/bin/bash

# Скрипт для git pull з гілки claude/web-app-frontend-NZLYe

# Не завершувати скрипт при помилці, щоб побачити деталі
set -e

# Точна назва гілки згідно з GitHub URL
BRANCH_NAME="claude/web-app-frontend-NZLYe"

echo "🔄 Початок git pull з гілки claude/web-app-frontend-NZLYe..."

# Перейдіть в корінь проекту
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📂 Поточна директорія: $(pwd)"

# Перевірте, чи це git репозиторій
if [ ! -d .git ]; then
    echo "❌ Помилка: Це не git репозиторій!"
    echo "💡 Спочатку ініціалізуйте git: git init"
    exit 1
fi

# Покажіть поточний remote
echo ""
echo "📡 Поточні remotes:"
git remote -v || echo "   (remotes не налаштовані)"

# Перевірте наявність origin
if ! git remote | grep -q "^origin$"; then
    echo "⚠️  Remote 'origin' не знайдено!"
    echo "💡 Додайте remote: git remote add origin <URL>"
    exit 1
fi

# Отримайте останні зміни з remote
echo ""
echo "📥 Отримання останніх змін з remote..."
if ! git fetch origin 2>&1; then
    echo "❌ Помилка при git fetch!"
    echo "💡 Перевірте підключення та права доступу до репозиторію"
    exit 1
fi

# Перевірте, чи існує гілка на remote
if git branch -r | grep -q "origin/$BRANCH_NAME"; then
    echo "✅ Гілка $BRANCH_NAME знайдена на remote"
else
    echo "⚠️  Гілка $BRANCH_NAME не знайдена на remote"
    echo ""
    echo "📋 Доступні remote гілки з 'claude':"
    git branch -r | grep "claude" || echo "   (не знайдено гілок з 'claude')"
    echo ""
    echo "📋 Всі доступні remote гілки:"
    git branch -r | head -20
    echo ""
    echo "💡 Переконайтесь, що виконали: git fetch origin"
    exit 1
fi

# Перевірте поточну гілку
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo ""
echo "🌿 Поточна гілка: $CURRENT_BRANCH"

# Переключіться на гілку або створить tracking branch
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME 2>/dev/null; then
    echo ""
    echo "🔄 Переключення на локальну гілку $BRANCH_NAME..."
    git checkout $BRANCH_NAME || {
        echo "❌ Помилка при переключенні на гілку!"
        exit 1
    }
    echo ""
    echo "⬇️  Виконання git pull..."
    if ! git pull origin $BRANCH_NAME 2>&1; then
        echo "❌ Помилка при git pull!"
        exit 1
    fi
else
    echo ""
    echo "🆕 Створення локальної гілки з tracking..."
    if ! git checkout -b $BRANCH_NAME origin/$BRANCH_NAME 2>&1; then
        echo "❌ Помилка: Не вдалося створити гілку з remote"
        echo ""
        echo "💡 Спробуйте виконати вручну:"
        echo "   git checkout -b $BRANCH_NAME origin/$BRANCH_NAME"
        exit 1
    fi
fi

echo ""
echo "✅ Готово! Гілка $BRANCH_NAME оновлена."
echo ""
echo "📊 Статус репозиторію:"
git status --short || true
