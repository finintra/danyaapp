import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/picking_model.dart';
import 'product_scan_screen.dart';

class InvoiceScanScreen extends StatefulWidget {
  const InvoiceScanScreen({super.key});

  @override
  State<InvoiceScanScreen> createState() => _InvoiceScanScreenState();
}

class _InvoiceScanScreenState extends State<InvoiceScanScreen> {
  final _invoiceController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _invoiceController.dispose();
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
                        _invoiceController.text = barcodeScanRes;
                      });
                      _processInvoice(barcodeScanRes);
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

  Future<void> _processInvoice(String invoice) async {
    if (!invoice.startsWith('OUT/') && !invoice.startsWith('WH/OUT')) {
      setState(() {
        _errorMessage = 'Неверный формат накладной. Должен начинаться с OUT/ или WH/OUT';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Отправляем запрос к API для прикрепления к накладной
      final apiService = ApiService();
      final response = await apiService.attachToPicking(invoice);
      
      if (!response.success) {
        setState(() {
          _isLoading = false;
          _errorMessage = response.error ?? 'Ошибка при обработке накладной';
        });
        return;
      }
      
      // Преобразуем ответ в модель
      final pickingResponse = PickingAttachResponse.fromJson(response.data);
      
      if (mounted) {
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
    } catch (e) {
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'СКАНУЙ НАКЛАДНУ',
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
                  'Піднесіть сканер до накладної OUT/... або WH/OUT...',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _invoiceController,
                        decoration: const InputDecoration(
                          hintText: 'OUT/... або WH/OUT...',
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
