import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Folha para obter um código de etiqueta — por câmera ou digitado. Devolve
/// a string do código (com ou sem separadores; o backend aceita as duas),
/// ou `null` se cancelado.
Future<String?> showQrScanSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _QrScanSheet(),
  );
}

class _QrScanSheet extends StatefulWidget {
  const _QrScanSheet();

  @override
  State<_QrScanSheet> createState() => _QrScanSheetState();
}

class _QrScanSheetState extends State<_QrScanSheet> {
  final _controller = TextEditingController();
  MobileScannerController? _scanner;
  bool _scanning = false;
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    _scanner?.dispose();
    super.dispose();
  }

  void _toggleScanner() {
    setState(() {
      _scanning = !_scanning;
      if (_scanning) {
        _scanner = MobileScannerController(
          formats: const [BarcodeFormat.qrCode],
          detectionSpeed: DetectionSpeed.noDuplicates,
        );
      } else {
        _scanner?.dispose();
        _scanner = null;
      }
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;
    _handled = true;
    Navigator.of(context).pop(raw.trim());
  }

  void _submitTyped() {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Etiqueta',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (_scanning && _scanner != null) ...[
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetect,
                  errorBuilder: (_, _) => const _ScannerUnavailable(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _toggleScanner,
              icon: const Icon(Icons.keyboard_outlined),
              label: const Text('Digitar em vez de escanear'),
            ),
          ] else ...[
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código da etiqueta',
                hintText: 'SL-XXXX-XXXX-XXXX-XXXX-X',
              ),
              inputFormatters: [
                UpperCaseFormatter(),
                LengthLimitingTextInputFormatter(30),
              ],
              onSubmitted: (_) => _submitTyped(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitTyped,
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScannerUnavailable extends StatelessWidget {
  const _ScannerUnavailable();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Câmera indisponível. Use "Digitar em vez de escanear".',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Deixa o código sempre em caixa alta enquanto digita.
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
