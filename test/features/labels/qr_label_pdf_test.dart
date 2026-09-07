import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/labels/application/qr_label_pdf.dart';

void main() {
  test('gera um PDF válido só com o código', () async {
    final bytes = await buildQrLabelPdf(publicCode: 'ABC-123-XYZ');
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('inclui título e subtítulo sem estourar', () async {
    final bytes = await buildQrLabelPdf(
      publicCode: 'PADARIA-01',
      title: 'Padaria Central',
      subtitle: 'Local',
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
