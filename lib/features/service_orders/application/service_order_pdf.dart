import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/db/app_database.dart';
import 'service_order_report.dart';

const _statusLabels = {
  'draft': 'Rascunho',
  'open': 'Aberta',
  'in_progress': 'Em andamento',
  'completed': 'Concluída',
};

const _photoKindLabels = {
  'before': 'Antes',
  'after': 'Depois',
  'other': 'Outra',
};

/// Monta o PDF da cópia de campo do laudo (ADR-0018 §10). Função pura: recebe
/// os dados já lidos do dispositivo, devolve os bytes — sem I/O, sem
/// Riverpod, dá pra testar direto. As fontes padrão do pacote `pdf`
/// (Helvetica) cobrem Latin-1, o que basta para português.
Future<Uint8List> buildServiceOrderPdf(ServiceOrderReportData d) async {
  final doc = pw.Document(
    title: 'Ordem de serviço ${_shortId(d.order.id)}',
  );

  final theme = pw.ThemeData.withFont();

  doc.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 48),
      header: (context) =>
          context.pageNumber == 1 ? _header(d) : pw.SizedBox(),
      footer: (context) => _footer(d, context),
      build: (context) => [
        _entitiesBlock(d),
        _datesBlock(d),
        ..._textSections(d.order),
        if (d.parts.isNotEmpty) ..._partsSection(d.parts),
        if (d.photos.isNotEmpty) ..._photosSection(d.photos),
        if (d.signaturePng != null) ..._signatureSection(d.signaturePng!),
      ],
    ),
  );

  return doc.save();
}

String _shortId(String id) =>
    id.length <= 8 ? id : id.substring(0, 8).toUpperCase();

String _fmtDateTime(DateTime? dt) {
  if (dt == null) return '-';
  final l = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

String _fmtDate(DateTime? dt) {
  if (dt == null) return '-';
  final l = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year}';
}

/// `1234.5` -> `1.234,50`. Entrada é string vinda do servidor/DB (pode estar
/// mascarada como `null` — grupo de campo sensível `cost`).
String? _money(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final value = double.tryParse(raw.replaceAll(',', '.'));
  if (value == null) return raw; // deixa passar o que veio, sem inventar
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
  return 'R\$ $intPart,${parts[1]}';
}

pw.Widget _header(ServiceOrderReportData d) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ORDEM DE SERVIÇO',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Cópia de campo',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (d.organizationName != null)
                pw.Text(
                  d.organizationName!,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              pw.Text(
                'Nº ${_shortId(d.order.id)}',
                style: const pw.TextStyle(color: PdfColors.grey700),
              ),
              pw.Text(
                _statusLabels[d.order.status] ?? d.order.status,
                style: const pw.TextStyle(color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
      pw.Divider(thickness: 1, color: PdfColors.grey400),
    ],
  );
}

pw.Widget _footer(ServiceOrderReportData d, pw.Context context) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Divider(thickness: .5, color: PdfColors.grey400),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              d.hasPendingUploads
                  ? 'Gerado em ${_fmtDateTime(d.generatedAt)} no dispositivo. Há anexos ainda não sincronizados - a via oficial no servidor pode diferir.'
                  : 'Gerado em ${_fmtDateTime(d.generatedAt)} no dispositivo. A via oficial é gerada no servidor após a sincronização.',
              style: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            '${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _entitiesBlock(ServiceOrderReportData d) {
  final address = _addressLine(d.location);
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _kv('Cliente', d.client?.name ?? '-'),
        if (d.client != null && d.client!.taxId.isNotEmpty)
          _kv('CNPJ/CPF', d.client!.taxId),
        if (d.client != null && d.client!.phone.isNotEmpty)
          _kv('Telefone', d.client!.phone),
        if (d.location != null) _kv('Local', d.location!.name),
        if (address.isNotEmpty) _kv('Endereço', address),
        if (d.equipment != null) _kv('Equipamento', _equipmentLine(d.equipment!)),
        if (d.technicianName != null) _kv('Técnico', d.technicianName!),
      ],
    ),
  );
}

String _addressLine(LocalLocation? l) {
  if (l == null) return '';
  final parts = <String>[
    if (l.street.isNotEmpty) l.street,
    if (l.number.isNotEmpty) l.number,
    if (l.complement.isNotEmpty) l.complement,
    if (l.district.isNotEmpty) l.district,
    if (l.city.isNotEmpty) l.city,
    if (l.state.isNotEmpty) l.state,
    if (l.postalCode.isNotEmpty) 'CEP ${l.postalCode}',
  ];
  return parts.join(', ');
}

String _equipmentLine(LocalEquipment e) {
  final extras = <String>[
    if (e.brand.isNotEmpty) e.brand,
    if (e.model.isNotEmpty) e.model,
    if ((e.serialNumber ?? '').isNotEmpty) 'nº série ${e.serialNumber}',
  ];
  return extras.isEmpty ? e.name : '${e.name} (${extras.join(' · ')})';
}

pw.Widget _datesBlock(ServiceOrderReportData d) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    child: pw.Wrap(
      spacing: 24,
      runSpacing: 2,
      children: [
        _inline('Agendada', _fmtDate(d.order.scheduledFor)),
        _inline('Iniciada', _fmtDateTime(d.order.startedAt)),
        _inline('Concluída', _fmtDateTime(d.order.completedAt)),
      ],
    ),
  );
}

List<pw.Widget> _textSections(LocalServiceOrder o) {
  final sections = <List<String>>[
    ['Motivo', o.reason],
    ['Diagnóstico', o.diagnosis],
    ['Serviço realizado', o.workPerformed],
    ['Condição final', o.finalCondition],
    ['Recomendações', o.recommendations],
    ['Observações', o.notes],
  ];
  return [
    for (final s in sections)
      if (s[1].trim().isNotEmpty)
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                s[0].toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(s[1].trim(), style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
  ];
}

List<pw.Widget> _partsSection(List<LocalServiceOrderPart> parts) {
  double? total = 0;
  final rows = <List<String>>[];
  for (final part in parts) {
    final qty = part.quantity.trim().isEmpty ? '1' : part.quantity.trim();
    final unitPrice = _money(part.unitPrice);
    final qtyNum = double.tryParse(qty.replaceAll(',', '.'));
    final priceNum = double.tryParse((part.unitPrice ?? '').replaceAll(',', '.'));
    String lineTotal = '-';
    if (qtyNum != null && priceNum != null) {
      final t = qtyNum * priceNum;
      lineTotal = _money(t.toStringAsFixed(2))!;
      if (total != null) total = total + t;
    } else {
      total = null; // um item sem preço parseável invalida o total
    }
    rows.add([
      part.description.trim().isEmpty ? '(sem descrição)' : part.description.trim(),
      part.partNumber,
      '$qty ${part.unit}'.trim(),
      unitPrice ?? '-',
      lineTotal,
    ]);
  }

  return [
    pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'PEÇAS E MATERIAIS',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey700,
        ),
      ),
    ),
    pw.SizedBox(height: 4),
    pw.TableHelper.fromTextArray(
      headers: ['Descrição', 'Código', 'Qtd.', 'Preço un.', 'Total'],
      data: rows,
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
    ),
    if (total != null)
      pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Text(
          'Total: ${_money(total.toStringAsFixed(2))}',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
  ];
}

List<pw.Widget> _photosSection(List<ReportPhoto> photos) {
  return [
    pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'FOTOS',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey700,
        ),
      ),
    ),
    pw.SizedBox(height: 6),
    pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final photo in photos)
          pw.Container(
            width: 160,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.ClipRRect(
                  horizontalRadius: 4,
                  verticalRadius: 4,
                  child: pw.Image(
                    pw.MemoryImage(photo.bytes),
                    width: 160,
                    height: 120,
                    fit: pw.BoxFit.cover,
                  ),
                ),
                if (photo.kind != null || (photo.caption ?? '').isNotEmpty)
                  pw.Text(
                    [
                      if (photo.kind != null)
                        _photoKindLabels[photo.kind] ?? photo.kind!,
                      if ((photo.caption ?? '').isNotEmpty) photo.caption!,
                    ].join(' · '),
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  ];
}

List<pw.Widget> _signatureSection(Uint8List png) {
  return [
    pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'ASSINATURA DO CLIENTE',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey700,
        ),
      ),
    ),
    pw.SizedBox(height: 4),
    pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: .5),
      ),
      padding: const pw.EdgeInsets.all(4),
      child: pw.Image(
        pw.MemoryImage(png),
        height: 90,
        fit: pw.BoxFit.contain,
      ),
    ),
  ];
}

pw.Widget _kv(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 90,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    ),
  );
}

pw.Widget _inline(String label, String value) {
  return pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '$label: ',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 8)),
      ],
    ),
  );
}
