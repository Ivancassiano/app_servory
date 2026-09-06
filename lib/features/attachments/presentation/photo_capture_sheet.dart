import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../application/attachment_controller.dart';

/// Bottom sheet: escolhe câmera ou galeria, classifica a foto
/// (`kind`/legenda) e envia (GUIA-FLUTTER.md §7). No nativo salva local e
/// enfileira (funciona offline); no web envia direto.
class PhotoCaptureSheet extends ConsumerStatefulWidget {
  const PhotoCaptureSheet({super.key, required this.serviceOrderId});

  final String serviceOrderId;

  @override
  ConsumerState<PhotoCaptureSheet> createState() => _PhotoCaptureSheetState();
}

class _PhotoCaptureSheetState extends ConsumerState<PhotoCaptureSheet> {
  final _captionController = TextEditingController();
  XFile? _picked;
  Uint8List? _bytes;
  String _kind = 'other';
  bool _saving = false;

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
    setState(() => _saving = true);
    try {
      await ref.read(attachmentControllerProvider).submitPhoto(
        orderId: widget.serviceOrderId,
        bytes: bytes,
        filename: picked.name,
        photoKind: _kind,
        caption: _captionController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adicionar foto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_bytes == null) ...[
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
              ),
            ] else ...[
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
        ),
      ),
    );
  }
}
