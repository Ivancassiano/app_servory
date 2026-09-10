import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/form_sheet.dart';
import '../application/attachment_controller.dart';

/// Uma foto escolhida mas ainda não enviada (cadastro que ainda não foi
/// salvo — não há `ownerId` pra fila de upload). `caption` é editável antes
/// de salvar.
class StagedPhoto {
  const StagedPhoto({required this.name, required this.bytes, this.caption = ''});

  final String name;
  final Uint8List bytes;
  final String caption;
}

/// Bottom sheet: escolhe câmera ou galeria, classifica a foto (só para
/// ordem de serviço), põe legenda e envia (GUIA-FLUTTER.md §7). No nativo
/// salva local e enfileira (funciona offline); no web envia direto. Serve
/// para ordem de serviço, item e local (`ownerKind`).
///
/// Modo "staging" ([onStaged] != null): a entidade ainda não existe (form de
/// cadastro), então em vez de enviar, devolve a foto + legenda pela callback
/// — a tela junta na lista e envia depois de salvar.
class PhotoCaptureSheet extends ConsumerStatefulWidget {
  const PhotoCaptureSheet({
    super.key,
    this.ownerKind,
    this.ownerId,
    this.serviceOrderItemId,
    this.onStaged,
  }) : assert(
         onStaged != null || (ownerKind != null && ownerId != null),
         'sem onStaged é preciso ownerKind + ownerId',
       );

  final String? ownerKind; // service_order | item | location
  final String? ownerId;

  /// Só para ordem de serviço: vincula a foto a um item da visita.
  final String? serviceOrderItemId;

  /// Modo staging: recebe a foto escolhida (com legenda) em vez de enviar.
  final void Function(StagedPhoto)? onStaged;

  @override
  ConsumerState<PhotoCaptureSheet> createState() => _PhotoCaptureSheetState();
}

class _PhotoCaptureSheetState extends ConsumerState<PhotoCaptureSheet> {
  final _captionController = TextEditingController();
  XFile? _picked;
  Uint8List? _bytes;
  String _kind = 'other';
  bool _saving = false;

  bool get _isOrder => widget.ownerKind == 'service_order';

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _picked = file;
      _bytes = bytes;
    });
  }

  Future<void> _submit() async {
    final picked = _picked;
    final bytes = _bytes;
    if (picked == null || bytes == null) return;
    final caption = _captionController.text.trim();

    if (widget.onStaged != null) {
      widget.onStaged!(
        StagedPhoto(name: picked.name, bytes: bytes, caption: caption),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(attachmentControllerProvider)
          .submitPhoto(
            ownerKind: widget.ownerKind!,
            ownerId: widget.ownerId!,
            bytes: bytes,
            filename: picked.name,
            photoKind: _kind,
            caption: caption,
            serviceOrderItemId: widget.serviceOrderItemId,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'Adicionar foto',
      children: [
        if (_bytes == null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Câmera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeria'),
                ),
              ),
            ],
          )
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(_bytes!, height: 180, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _picked = null;
              _bytes = null;
            }),
            child: const Text('Trocar foto'),
          ),
          if (_isOrder) ...[
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'before', label: Text('Antes')),
                ButtonSegment(value: 'after', label: Text('Depois')),
                ButtonSegment(value: 'other', label: Text('Outra')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _captionController,
            decoration: const InputDecoration(
              labelText: 'Legenda (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Adicionar'),
          ),
        ],
      ],
    );
  }
}
