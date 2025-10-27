Write-Host "Збірка APK для мобільного додатку 'Складський сканер'" -ForegroundColor Green
Write-Host "Переконайтеся, що режим розробника увімкнено в налаштуваннях Windows" -ForegroundColor Yellow

# Перевірка наявності Flutter
try {
    $flutterVersion = flutter --version
    Write-Host "Flutter знайдено: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "Flutter не знайдено. Переконайтеся, що Flutter встановлено і доданий до PATH" -ForegroundColor Red
    exit 1
}

# Збірка APK
Write-Host "Збірка APK..." -ForegroundColor Cyan
flutter build apk --release

# Якщо збірка завершилася з помилкою
if ($LASTEXITCODE -ne 0) {
    Write-Host "Помилка збірки APK. Код виходу: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Шлях до готового APK
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"

# Перевірка наявності APK
if (Test-Path $apkPath) {
    Write-Host "APK успішно створено: $apkPath" -ForegroundColor Green
    
    # Відкриття папки з APK
    Write-Host "Відкриття папки з APK..." -ForegroundColor Cyan
    explorer.exe /select,"$(Resolve-Path $apkPath)"
} else {
    Write-Host "APK не знайдено за шляхом: $apkPath" -ForegroundColor Red
}
