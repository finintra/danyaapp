Write-Host "Запуск мобільного додатку 'Складський сканер'" -ForegroundColor Green
Write-Host "Переконайтеся, що режим розробника увімкнено в налаштуваннях Windows" -ForegroundColor Yellow

# Перевірка наявності Flutter
try {
    $flutterVersion = flutter --version
    Write-Host "Flutter знайдено: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "Flutter не знайдено. Переконайтеся, що Flutter встановлено і доданий до PATH" -ForegroundColor Red
    exit 1
}

# Перевірка наявності підключених пристроїв
Write-Host "Перевірка підключених пристроїв..." -ForegroundColor Cyan
flutter devices

# Запуск додатку
Write-Host "Запуск додатку..." -ForegroundColor Cyan
flutter run

# Якщо додаток завершився з помилкою
if ($LASTEXITCODE -ne 0) {
    Write-Host "Помилка запуску додатку. Код виходу: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
