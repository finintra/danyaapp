#!/bin/bash

# Скрипт для завантаження всіх файлів з гілки claude/web-app-frontend-NZLYe в поточну директорію

set -e

BRANCH_NAME="claude/web-app-frontend-NZLYe"
REPO_URL="https://github.com/finintra/whapp2.git"

echo "📥 Завантаження файлів з гілки $BRANCH_NAME..."

# Перейдіть в поточну директорію
cd "$(dirname "$0")"

CURRENT_DIR=$(pwd)
echo "📂 Поточна директорія: $CURRENT_DIR"

# Перевірте, чи це git репозиторій
if [ ! -d .git ]; then
    echo "📦 Ініціалізація git репозиторію..."
    git init
fi

# Додайте або оновіть remote для whapp2
if git remote | grep -q "^whapp2$"; then
    echo "🔄 Оновлення remote whapp2..."
    git remote set-url whapp2 "$REPO_URL"
else
    echo "➕ Додавання remote whapp2..."
    git remote add whapp2 "$REPO_URL"
fi

# Використовуємо whapp2 як remote для цієї операції
REMOTE_NAME="whapp2"

# Отримайте останні зміни
echo "📥 Отримання даних з GitHub..."
git fetch $REMOTE_NAME

# Перевірте, чи існує гілка
if ! git branch -r | grep -q "$REMOTE_NAME/$BRANCH_NAME"; then
    echo "❌ Помилка: Гілка $BRANCH_NAME не знайдена на remote $REMOTE_NAME!"
    echo "📋 Доступні гілки з $REMOTE_NAME:"
    git branch -r | grep "$REMOTE_NAME" | head -10
    exit 1
fi

# Створіть або переключіться на гілку
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME 2>/dev/null; then
    echo "🔄 Переключення на локальну гілку $BRANCH_NAME..."
    git checkout $BRANCH_NAME
    echo "⬇️  Оновлення файлів..."
    git pull $REMOTE_NAME $BRANCH_NAME
else
    echo "🆕 Створення локальної гілки та завантаження файлів..."
    git checkout -b $BRANCH_NAME $REMOTE_NAME/$BRANCH_NAME
fi

echo ""
echo "✅ Готово! Всі файли з гілки $BRANCH_NAME завантажено в поточну директорію."
echo ""
echo "📊 Статус:"
git status --short || true
