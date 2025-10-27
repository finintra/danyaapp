// Функція для перевірки пароля
function checkPassword() {
    const passwordOverlay = document.getElementById('passwordOverlay');
    const passwordInput = document.getElementById('passwordInput');
    const passwordError = document.getElementById('passwordError');
    
    // Перевіряємо, чи є вже авторизація в sessionStorage
    if (sessionStorage.getItem('authenticated') === 'true') {
        passwordOverlay.style.display = 'none';
        return;
    }
    
    // Показуємо оверлей пароля
    passwordOverlay.style.display = 'flex';
    
    // Обробник форми пароля
    document.getElementById('passwordForm').addEventListener('submit', function(e) {
        e.preventDefault();
        
        if (passwordInput.value === 'mobileodoo') {
            // Правильний пароль
            sessionStorage.setItem('authenticated', 'true');
            passwordOverlay.style.display = 'none';
        } else {
            // Неправильний пароль
            passwordError.style.display = 'block';
            passwordInput.value = '';
            passwordInput.focus();
        }
    });
}

// Функція для симуляції PIN-коду
function setupPinInput() {
    const pinDots = document.querySelectorAll('.pin-dot');
    const pinKeys = document.querySelectorAll('.pin-key');
    let currentPin = '';
    
    pinKeys.forEach(key => {
        key.addEventListener('click', function() {
            const value = this.getAttribute('data-value');
            
            if (value === 'delete') {
                // Видалення останньої цифри
                if (currentPin.length > 0) {
                    currentPin = currentPin.slice(0, -1);
                    updatePinDisplay();
                }
            } else if (value === 'exit') {
                // Вихід (перенаправлення на екран входу)
                window.location.href = 'screen-01-badge-scan.html';
            } else {
                // Додавання цифри
                if (currentPin.length < 4) {
                    currentPin += value;
                    updatePinDisplay();
                    
                    // Перевірка PIN-коду при введенні 4 цифр
                    if (currentPin.length === 4) {
                        setTimeout(() => {
                            if (currentPin === '1234') {
                                window.location.href = 'screen-03-invoice-scan.html';
                            } else {
                                window.location.href = 'screen-02b-pin-error.html';
                            }
                        }, 300);
                    }
                }
            }
        });
    });
    
    function updatePinDisplay() {
        pinDots.forEach((dot, index) => {
            if (index < currentPin.length) {
                dot.classList.add('filled');
            } else {
                dot.classList.remove('filled');
            }
        });
    }
}

// Функція для симуляції сканування накладної
function setupInvoiceScan() {
    const scanInput = document.getElementById('invoiceScanInput');
    
    scanInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            const value = scanInput.value.trim();
            
            if (value.startsWith('OUT/')) {
                window.location.href = 'screen-04-product-scan.html';
            } else {
                scanInput.value = '';
                scanInput.classList.add('error');
                setTimeout(() => {
                    scanInput.classList.remove('error');
                }, 500);
            }
        }
    });
}

// Функція для симуляції сканування товарів
function setupProductScan() {
    const scanInput = document.getElementById('productScanInput');
    let remainCount = parseInt(document.getElementById('remainCount').textContent);
    let doneCount = parseInt(document.getElementById('doneCount').textContent);
    
    scanInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            const value = scanInput.value.trim();
            
            if (value) {
                // Симуляція різних сценаріїв сканування
                if (value === 'error1') {
                    // Лишній товар
                    window.location.href = 'screen-06-error-extra.html';
                } else if (value === 'error2') {
                    // Немає в замовленні
                    window.location.href = 'screen-07-error-not-in-order.html';
                } else {
                    // Успішне сканування
                    if (remainCount > 0) {
                        remainCount--;
                        doneCount++;
                        
                        document.getElementById('remainCount').textContent = remainCount;
                        document.getElementById('doneCount').textContent = doneCount;
                        
                        scanInput.value = '';
                        
                        // Перевірка, чи закінчився рядок
                        if (remainCount === 0) {
                            window.location.href = 'screen-08-line-completed.html';
                        } else {
                            window.location.href = 'screen-05-success.html';
                        }
                    } else {
                        window.location.href = 'screen-06-error-extra.html';
                    }
                }
            }
        }
    });
    
    // Кнопка відміни збірки
    document.getElementById('cancelPickingBtn').addEventListener('click', function() {
        window.location.href = 'screen-11-cancel-picking.html';
    });
}

// Функція для автоматичного перенаправлення після затримки
function redirectAfterDelay(url, delay) {
    setTimeout(() => {
        window.location.href = url;
    }, delay);
}

// Ініціалізація при завантаженні сторінки
document.addEventListener('DOMContentLoaded', function() {
    // Перевірка пароля на всіх сторінках
    checkPassword();
    
    // Ініціалізація функцій в залежності від сторінки
    const currentPage = window.location.pathname.split('/').pop();
    
    if (currentPage === 'screen-02-pin-entry.html') {
        setupPinInput();
    } else if (currentPage === 'screen-03-invoice-scan.html') {
        setupInvoiceScan();
    } else if (currentPage === 'screen-04-product-scan.html') {
        setupProductScan();
    } else if (currentPage === 'screen-05-success.html') {
        redirectAfterDelay('screen-04-product-scan.html', 400);
    } else if (currentPage === 'screen-06-error-extra.html' || 
               currentPage === 'screen-07-error-not-in-order.html') {
        redirectAfterDelay('screen-04-product-scan.html', 800);
    } else if (currentPage === 'screen-08-line-completed.html') {
        redirectAfterDelay('screen-04-product-scan.html', 500);
    } else if (currentPage === 'screen-01b-badge-error.html') {
        redirectAfterDelay('screen-01-badge-scan.html', 2000);
    } else if (currentPage === 'screen-02b-pin-error.html') {
        redirectAfterDelay('screen-02-pin-entry.html', 2000);
    }
});
