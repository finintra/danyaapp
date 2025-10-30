import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/picking_model.dart';
import '../services/sound_service.dart';
import 'cancel_picking_screen.dart';
import 'success_scan_screen.dart';
import 'error_extra_screen.dart';
import 'error_not_in_order_screen.dart';
import 'error_wrong_order_screen.dart';
import 'error_already_scanned_screen.dart';
import 'line_completed_screen.dart';
import 'order_completed_screen.dart';

class ProductScanScreen extends StatefulWidget {
  final String invoiceNumber;
  final int pickingId;
  final PickingLine currentLine;
  final int totalLines;
  final int completedLines;

  const ProductScanScreen({
    super.key,
    required this.invoiceNumber,
    required this.pickingId,
    required this.currentLine,
    required this.totalLines,
    required this.completedLines,
  });

  @override
  State<ProductScanScreen> createState() => _ProductScanScreenState();
}

class _ProductScanScreenState extends State<ProductScanScreen> {
  final _scanController = TextEditingController();
  late int _remainCount;
  late int _doneCount;
  bool _isLoading = false;
  String? _errorMessage;
  late PickingLine _currentLine;
  final SoundService _soundService = SoundService();
  
  @override
  void initState() {
    super.initState();
    _currentLine = widget.currentLine;
    _remainCount = _currentLine.remain.toInt();
    _doneCount = _currentLine.done.toInt();
    
    // Debugging information
    print('Current line data:');
    print('Product: ${_currentLine.productName}');
    print('Required: ${_currentLine.required}');
    print('Done: ${_currentLine.done}');
    print('Remain: ${_currentLine.remain}');
    print('Remain count: $_remainCount');
    print('Done count: $_doneCount');
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    try {
      // Відкриваємо діалог зі сканером
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Скануйте штрих-код',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: MobileScanner(
                  controller: MobileScannerController(),
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      String barcodeScanRes = barcodes.first.rawValue!;
                      Navigator.pop(context); // Закриваємо сканер
                      setState(() {
                        _scanController.text = barcodeScanRes;
                      });
                      _processScannedItem(barcodeScanRes);
                    }
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Відміна'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Помилка сканування: $e';
      });
    }
  }

  Future<void> _processScannedItem(String code) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Отправляем запрос к API для сканирования товара
      final apiService = ApiService();
      // Передаємо ID поточного товару
      final response = await apiService.scanItem(widget.pickingId, code, _currentLine.productId);
      
      if (!response.success) {
        // Обрабатываем ошибки
        if (response.error == 'NOT_IN_ORDER') {
          // Відтворюємо звук помилки
          _soundService.playErrorSound();
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ErrorNotInOrderScreen()),
            );
          }
        } else if (response.error == 'OVERPICK') {
          // Відтворюємо звук помилки
          _soundService.playErrorSound();
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ErrorExtraScreen()),
            );
          }
        } else if (response.error == 'WRONG_ORDER' || response.error == 'ALREADY_SCANNED') {
          // Відтворюємо звук помилки
          _soundService.playErrorSound();
          if (mounted) {
            // Показуємо окремі екрани для вже відсканованого та раннього товару
            final isAlreadyScanned = response.error == 'ALREADY_SCANNED';
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => isAlreadyScanned
                    ? const ErrorAlreadyScannedScreen()
                    : const ErrorWrongOrderScreen(),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = response.error ?? 'Ошибка при сканировании товара';
          });
        }
      } else {
        // Успешное сканирование
        final lineData = response.data['line'];
        
        // Відтворюємо звук успішного сканування
        _soundService.playScanSuccessSound();
        
        // Дебаг информация
        print('Line data: $lineData');
        
        // Конвертируем данные в целые числа
        int remain = 0;
        int done = 0;
        
        if (lineData['remain'] != null) {
          if (lineData['remain'] is int) {
            remain = lineData['remain'];
          } else if (lineData['remain'] is double) {
            remain = lineData['remain'].toInt();
          } else {
            try {
              remain = int.parse(lineData['remain'].toString());
            } catch (e) {
              print('Error parsing remain: $e');
            }
          }
        }
        
        if (lineData['done'] != null) {
          if (lineData['done'] is int) {
            done = lineData['done'];
          } else if (lineData['done'] is double) {
            done = lineData['done'].toInt();
          } else {
            try {
              done = int.parse(lineData['done'].toString());
            } catch (e) {
              print('Error parsing done: $e');
            }
          }
        }
        
        setState(() {
          _remainCount = remain;
          _doneCount = done;
        });
        
        // Дебаг информация
        print('Updated remain: $_remainCount, done: $_doneCount');
        
        final rowCompleted = response.data['row_completed'] ?? false;
        final orderCompleted = response.data['order_completed'] ?? false;
        
        // Показываем екран успішного сканування і чекаємо закриття, 
        // щоб не накладалися навігаційні переходи
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SuccessScanScreen()),
          );
        }
        
        // Если товар полностью отсканирован
        if (rowCompleted) {
          // Відтворюємо звук успішного завершення
          _soundService.playSuccessSound();
          
          // Показываем экран завершения рядка
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const LineCompletedScreen()),
            );
          }
          
          // Проверяем завершение заказа
          await Future.delayed(const Duration(milliseconds: 800));
          if (orderCompleted) {
            // Відтворюємо звук успішного завершення
            _soundService.playSuccessSound();
            
            // Заказ завершен
            if (mounted) {
              // Отримуємо загальну кількість товарів
              int totalItems = 0;
              if (response.data['order_summary'] != null && response.data['order_summary']['total_items'] != null) {
                totalItems = response.data['order_summary']['total_items'];
              }
              
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => OrderCompletedScreen(
                    invoiceNumber: widget.invoiceNumber,
                    pickingId: widget.pickingId,
                    totalItems: totalItems,
                  ),
                ),
              );
            }
            return;
          }
          
          // Получаем следующий товар
          final nextLineData = response.data['next_line'];
          if (nextLineData != null) {
            // Загружаем новый экран с новым товаром
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              final nextLine = PickingLine.fromJson(nextLineData);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ProductScanScreen(
                    invoiceNumber: widget.invoiceNumber,
                    pickingId: widget.pickingId,
                    currentLine: nextLine,
                    totalLines: widget.totalLines,
                    completedLines: widget.completedLines + 1,
                  ),
                ),
              );
            }
          } else {
            // Если нет данных о следующем товаре, пробуем получить детали накладной
            final detailsResponse = await apiService.getPickingDetails(widget.pickingId);
            if (detailsResponse.success && detailsResponse.data['lines'] != null) {
              final lines = detailsResponse.data['lines'] as List<dynamic>;
              dynamic nextLine;
              try {
                nextLine = lines.firstWhere((line) => line['remain'] > 0);
              } catch (e) {
                nextLine = null;
              }
              
              if (nextLine != null && mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ProductScanScreen(
                      invoiceNumber: widget.invoiceNumber,
                      pickingId: widget.pickingId,
                      currentLine: PickingLine.fromJson(nextLine),
                      totalLines: widget.totalLines,
                      completedLines: widget.completedLines + 1,
                    ),
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _scanController.clear();
        });
      }
    }
  }

  void _cancelPicking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CancelPickingScreen(
          pickingId: widget.pickingId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Заголовок с номером накладной
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 3),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Text(
                'НАКЛАДНА ${widget.invoiceNumber}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Основная зона
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Блок с информацией о количестве товаров
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Товарів:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Блоки с информацией о количестве
                  Row(
                    children: [
                      // Блок "Всього"
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD), // Светло-синий цвет
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Всього',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue, // Синий цвет текста
                                ),
                              ),
                              Text(
                                '${widget.totalLines}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue, // Синий цвет текста
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Блок "Лишилось"
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0), // Цвет как у нижнего блока
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Лишилось',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warningColor, // Цвет как у нижнего блока
                                ),
                              ),
                              Text(
                                '${widget.totalLines - widget.completedLines}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warningColor, // Цвет как у нижнего блока
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Информация о товаре
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Артикул: ${_currentLine.productCode ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _currentLine.productName,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _currentLine.location != null ? _currentLine.location! : 'Місцезнаходження не вказано',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  if (_currentLine.locationComplete != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _currentLine.locationComplete!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 15),
                  
                  // Счетчики текущего товара
                  Row(
                    children: [
                      // Счетчик "Відскановано"
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Відскановано',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_doneCount',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Счетчик "Ще сканувати"
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Ще сканувати',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.warningColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_remainCount',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warningColor,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Поле ввода и кнопка камеры
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _scanController,
                          decoration: const InputDecoration(
                            hintText: 'Скануйте товар',
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _processScannedItem(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 3),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[200],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 30,
                          ),
                          onPressed: _scanBarcode,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  const Text(
                    'Або натисніть камеру',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textColor,
                    ),
                  ),
                  
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
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
                      padding: EdgeInsets.only(top: 10),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
          
          // Кнопка отмены сборки
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey, width: 2),
              ),
            ),
            child: ElevatedButton(
              onPressed: _cancelPicking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                minimumSize: const Size(double.infinity, 55),
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('ВІДМІНИТИ ЗБІРКУ'),
            ),
          ),
        ],
      ),
    );
  }
}
