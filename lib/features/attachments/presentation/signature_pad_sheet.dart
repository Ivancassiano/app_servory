import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import '../../../core/theme/app_theme.dart';
import '../application/attachment_controller.dart';

/// Tela cheia de captura de assinatura (GUIA-FLUTTER.md §7/§12) — desenha
/// no canvas, exporta PNG (único formato aceito pelo servidor) e envia. No
/// nativo enfileira (funciona offline); no web envia direto.
class SignaturePadSheet extends ConsumerStatefulWidget {
  const SignaturePadSheet({super.key, required this.serviceOrderId});

  final String serviceOrderId;

  @override
  ConsumerState<SignaturePadSheet> createState() => _SignaturePadSheetState();
}

class _SignaturePadSheetState extends ConsumerState<SignaturePadSheet> {
  late final SignatureController _controller = SignatureController(
    penStrokeWidth: 3.4,
    penColor: BrandColor.ink,
    exportBackgroundColor: Colors.white,
    onDrawEnd: () => setState(() {}),
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
      await ref.read(attachmentControllerProvider).submitSignature(
        orderId: widget.serviceOrderId,
        bytes: bytes,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_saving && _controller.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Assinatura do cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar',
            onPressed: () => setState(_controller.clear),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Peça para o cliente assinar abaixo.',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 13.5,
                  color: BrandColor.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border.fromBorderSide(
                      BorderSide(color: BrandColor.border),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 120,
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE3E5E8),
                        ),
                      ),
                      Signature(
                        controller: _controller,
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canSave ? _submit : null,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar assinatura'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'envio enfileirado — funciona offline',
                style: BrandText.brandOver.copyWith(
                  letterSpacing: 0.4,
                  color: BrandColor.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
