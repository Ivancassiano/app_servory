import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Etiqueta única para impressão / compartilhamento — QR Code + código
/// legível + nome do registro. Função pura (sem I/O nem Riverpod): recebe o
/// texto, devolve os bytes do PDF. Página no tamanho de uma etiqueta
/// (100×60 mm); a maioria das impressoras ajusta à folha ou ao rolo.
Future<Uint8List> buildQrLabelPdf({
  required String publicCode,
  String? title,
  String? subtitle,
  String? message,
}) async {
  final doc = pw.Document(title: 'Etiqueta $publicCode');

  const format = PdfPageFormat(
    100 * PdfPageFormat.mm,
    60 * PdfPageFormat.mm,
    marginAll: 6 * PdfPageFormat.mm,
  );

  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.BarcodeWidget(
            data: publicCode,
            barcode: pw.Barcode.qrCode(),
            width: 42 * PdfPageFormat.mm,
            height: 42 * PdfPageFormat.mm,
            drawText: false,
          ),
          pw.SizedBox(width: 8 * PdfPageFormat.mm),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (title != null && title.isNotEmpty)
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: pw.TextOverflow.clip,
                  ),
                if (subtitle != null && subtitle.isNotEmpty)
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                    maxLines: 1,
                  ),
                pw.SizedBox(height: 6),
                pw.Text(
                  publicCode,
                  style: const pw.TextStyle(fontSize: 9.5, letterSpacing: 0.5),
                ),
                if (message != null && message.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    message.trim(),
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey800,
                      lineSpacing: 1.5,
                    ),
                    maxLines: 4,
                    overflow: pw.TextOverflow.clip,
                  ),
                ],
                pw.SizedBox(height: 8),
                pw.Text(
                  'ServiceReport',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}
