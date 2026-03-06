import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/picking_model.dart';
import '../services/storage_service.dart';
import 'product_scan_screen.dart';
import 'error_order_locked_screen.dart';
import 'error_already_done_screen.dart';
import 'login_screen.dart';

class InvoiceScanScreen extends StatefulWidget {
  const InvoiceScanScreen({super.key});

  @override
  State<InvoiceScanScreen> createState() => _InvoiceScanScreenState();
}

class _InvoiceScanScreenState extends State<InvoiceScanScreen> {
  final _invoiceController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // Автофокус на поле ввода после загрузки экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    try {
      // Отримуємо збережений стан спалаху
      final savedTorchState = await _storageService.getTorchState();
      
      // Створюємо контролер для сканера
      final scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
      
      // Якщо спалах був увімкнений, увімкнемо його при ініціалізації
      if (savedTorchState) {
        // Невелика затримка, щоб камера встигла ініціалізуватися
        Future.delayed(const Duration(milliseconds: 300), () async {
          try {
            await scannerController.toggleTorch();
          } catch (e) {
            print('Error turning on torch on init: $e');
          }
        });
      }
      
      // Відкриваємо діалог зі сканером
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            // Слухаємо зміни стану спалаху
            return ValueListenableBuilder<TorchState>(
              valueListenable: scannerController.torchState,
              builder: (context, torchState, child) {
                final isTorchOn = torchState == TorchState.on;
                
                return Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Скануйте штрих-код або QR-код',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Кнопка для увімкнення/вимкнення спалаху
                            // Завжди показуємо кнопку, але обробляємо помилки
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: isTorchOn ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isTorchOn ? Colors.amber : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                                  size: 28,
                                  color: isTorchOn ? Colors.amber : Colors.grey[700],
                                ),
                                onPressed: () async {
                                  try {
                                    await scannerController.toggleTorch();
                                    // Зберігаємо новий стан спалаху
                                    final newState = torchState == TorchState.off;
                                    await _storageService.saveTorchState(newState);
                                  } catch (e) {
                                    print('Error toggling torch: $e');
                                    // Якщо спалах недоступний, просто ігноруємо помилку
                                    // Кнопка залишиться видимою, але не працюватиме
                                  }
                                },
                                tooltip: isTorchOn ? 'Вимкнути спалах' : 'Увімкнути спалах',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: MobileScanner(
                          controller: scannerController,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                              String barcodeScanRes = barcodes.first.rawValue!;
                              scannerController.dispose(); // Закриваємо контролер перед закриттям
                              Navigator.pop(context); // Закриваємо сканер
                              setState(() {
                                _invoiceController.text = barcodeScanRes;
                              });
                              _processInvoice(barcodeScanRes);
                            }
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          scannerController.dispose();
                          Navigator.pop(context);
                        },
                        child: Text('Відміна'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Помилка сканування: $e';
      });
    }
  }

  Future<void> _processInvoice(String invoice) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Processing invoice: $invoice');
      
      // Отправляем запрос к API для прикрепления к накладной
      final apiService = ApiService();
      final response = await apiService.attachToPicking(invoice);
      
      print('API response received: success=${response.success}');
      
      if (!response.success) {
        // Перевіряємо наявність помилки авторизації
        final errorMessage = response.error ?? 'Ошибка при обработке накладной';
        print('API error: $errorMessage');
        
        // Перевіряємо, чи це помилка авторизації
        if (errorMessage.toLowerCase().contains('not authorized') || 
            errorMessage.toLowerCase().contains('token failed') ||
            errorMessage.toLowerCase().contains('unauthorized') ||
            errorMessage.toLowerCase().contains('auth') ||
            errorMessage == 'TOKEN_EXPIRED' ||
            errorMessage == 'TOKEN_INVALID') {
          
          print('Authorization error detected, redirecting to login screen');
          
          // Очищуємо дані авторизації
          final storageService = StorageService();
          await storageService.clearAllComplete();
          
          if (mounted) {
            // Переходимо на екран логіну
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false, // Видаляємо всі попередні екрани зі стеку
            );
          }
          return;
        }
        
        // Обробка помилки ORDER_ALREADY_DONE
        if (response.error == 'ORDER_ALREADY_DONE') {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ErrorAlreadyDoneScreen()),
            );
          }
          return;
        }
        
        // Обробка помилки ORDER_LOCKED
        if (response.error == 'ORDER_LOCKED') {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ErrorOrderLockedScreen()),
            );
          }
          return;
        }
        
        // Обробка помилки NO_MOVE_LINES
        if (response.error == 'NO_MOVE_LINES') {
          setState(() {
            _isLoading = false;
            _errorMessage = response.message ?? 'Накладна не містить товарів для збірки';
          });
          return;
        }
        
        // Обробка помилки CREDENTIALS_NOT_FOUND
        if (response.error == 'CREDENTIALS_NOT_FOUND') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message ?? 'Збережені облікові дані не знайдено. Будь ласка, увійдіть знову.'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        }
        
        setState(() {
          _isLoading = false;
          _errorMessage = response.error ?? 'Ошибка при обработке накладной';
        });
        return;
      }
      
      // Перевірка відповіді API
      if (response.data == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка: Пустой ответ от сервера';
        });
        return;
      }
      
      if (response.data is! Map<String, dynamic>) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка: Неверный формат ответа от сервера';
        });
        return;
      }
      
      // Перевірка наявності необхідних полів
      if (response.data['picking'] == null) {
        throw Exception('Відсутнє поле "picking" у відповіді API');
      }
      if (response.data['line'] == null) {
        throw Exception('Відсутнє поле "line" у відповіді API');
      }
      if (response.data['order_summary'] == null) {
        throw Exception('Відсутнє поле "order_summary" у відповіді API');
      }
      
      try {
        // Спеціальна обробка для булевих значень
        print('Pre-processing API response to handle boolean values...');
        Map<String, dynamic> processedData = {};
        
        // Копіюємо всі дані з відповіді
        response.data.forEach((key, value) {
          processedData[key] = value;
        });
        
        // Обробляємо picking
        if (processedData['picking'] != null && processedData['picking'] is Map) {
          Map<String, dynamic> processedPicking = {};
          (processedData['picking'] as Map).forEach((key, value) {
            // Перетворюємо булеві значення на рядки
            if (value is bool) {
              processedPicking[key] = value.toString();
              print('Converted boolean to string in picking[$key]: $value -> ${value.toString()}');
            } else {
              processedPicking[key] = value;
            }
          });
          processedData['picking'] = processedPicking;
        }
        
        // Обробляємо line
        if (processedData['line'] != null && processedData['line'] is Map) {
          Map<String, dynamic> processedLine = {};
          (processedData['line'] as Map).forEach((key, value) {
            // Перетворюємо булеві значення на рядки
            if (value is bool) {
              processedLine[key] = value.toString();
              print('Converted boolean to string in line[$key]: $value -> ${value.toString()}');
            } else {
              processedLine[key] = value;
            }
          });
          processedData['line'] = processedLine;
        }
        
        // Обробляємо order_summary
        if (processedData['order_summary'] != null && processedData['order_summary'] is Map) {
          Map<String, dynamic> processedSummary = {};
          (processedData['order_summary'] as Map).forEach((key, value) {
            // Перетворюємо булеві значення на рядки
            if (value is bool) {
              processedSummary[key] = value ? '1' : '0';
              print('Converted boolean to string in order_summary[$key]: $value -> ${value ? '1' : '0'}');
            } else {
              processedSummary[key] = value;
            }
          });
          processedData['order_summary'] = processedSummary;
        }
        
        print('Pre-processing complete. Processed data: $processedData');
        
        // Преобразуем ответ в модель
        print('Converting processed response to PickingAttachResponse...');
        final pickingResponse = PickingAttachResponse.fromJson(processedData);
        print('Successfully converted to PickingAttachResponse');
        
        // Перевірка даних після перетворення
        print('Picking ID: ${pickingResponse.pickingId}');
        print('Picking Name: ${pickingResponse.pickingName}');
        print('Total Lines: ${pickingResponse.totalLines}');
        print('Completed Lines: ${pickingResponse.completedLines}');
        
        if (mounted) {
          print('Navigating to ProductScanScreen...');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ProductScanScreen(
                invoiceNumber: pickingResponse.pickingName,
                pickingId: pickingResponse.pickingId,
                currentLine: pickingResponse.line,
                totalLines: pickingResponse.totalLines,
                completedLines: pickingResponse.completedLines,
              ),
            ),
          );
        }
      } catch (conversionError) {
        print('Error converting response to PickingAttachResponse: $conversionError');
        
        // Спроба вручну створити об'єкт з даних API
        try {
          print('Trying manual conversion...');
          final pickingData = response.data['picking'] as Map<String, dynamic>;
          final lineData = response.data['line'] as Map<String, dynamic>;
          
          // Отримуємо необхідні дані
          final pickingId = pickingData['id'] is int ? pickingData['id'] : 0;
          final pickingName = pickingData['name']?.toString() ?? 'Unknown';
          
          // Створюємо об'єкт PickingLine вручну
          final line = PickingLine(
            lineId: lineData['line_id'] is int ? lineData['line_id'] : 0,
            productId: lineData['product_id'] is int ? lineData['product_id'] : 0,
            productName: lineData['product_name']?.toString() ?? 'Unknown Product',
            price: 0.0,
            uom: 'Units',
            required: 1.0,
            done: 0.0,
            remain: 1.0,
          );
          
          if (mounted) {
            print('Navigating to ProductScanScreen with manually created data...');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ProductScanScreen(
                  invoiceNumber: pickingName,
                  pickingId: pickingId,
                  currentLine: line,
                  totalLines: 1,
                  completedLines: 0,
                ),
              ),
            );
          }
        } catch (manualError) {
          print('Error in manual conversion: $manualError');
          throw manualError; // Передаємо помилку далі
        }
      }
    } catch (e) {
      print('Error in _processInvoice: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем высоту клавиатуры
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: keyboardHeight > 0 ? keyboardHeight + 20 : 20.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - (keyboardHeight > 0 ? keyboardHeight : 0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'СКАНУЙ НАКЛАДНУ\nАБО ТТН',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.description_outlined,
                  size: 100,
                ),
                const SizedBox(height: 20),
                Text(
                  'Піднесіть сканер до накладної OUT/... або WH/OUT...\nабо до номера ТТН',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _invoiceController,
                        focusNode: _focusNode,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'OUT/... або ТТН',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                        ),
                        // Дозволяємо вводити будь-які символи
                        keyboardType: TextInputType.text,
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _processInvoice(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 3),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 35,
                        ),
                        onPressed: _scanBarcode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Або натисніть камеру для сканування',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
