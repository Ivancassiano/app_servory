import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';

import '../application/upload_queue_controller.dart';

/// Tela cheia de captura de assinatura (GUIA-FLUTTER.md §7/§12) — desenha
/// no canvas, exporta PNG (único formato aceito pelo servidor) e enfileira
/// o envio. Funciona sempre, mesmo offline.
class SignaturePadSheet extends ConsumerStatefulWidget {
  const SignaturePadSheet({super.key, required this.serviceOrderId});

  final String serviceOrderId;

  @override
  ConsumerState<SignaturePadSheet> createState() => _SignaturePadSheetState();
}

class _SignaturePadSheetState extends ConsumerState<SignaturePadSheet> {
  final _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.isEmpty) return;
    setState(() => _saving = true);
    try {
      final bytes = await _controller.toPngBytes();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, '${const Uuid().v4()}.png'));
      await file.writeAsBytes(bytes);
      await ref
          .read(uploadQueueControllerProvider)
          .enqueueSignature(
            serviceOrderId: widget.serviceOrderId,
            sourceFile: file,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assinatura do cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar',
            onPressed: () => _controller.clear(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Peça para o cliente assinar abaixo.'),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Signature(
                    controller: _controller,
                    backgroundColor: Colors.white,
                  ),
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
                    : const Text('Salvar assinatura'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
