import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Uma foto escolhida mas ainda não enviada (cadastro que ainda não foi
/// salvo — não há `ownerId` pra fila de upload). `caption` é editável antes
/// de salvar.
class StagedPhoto {
  const StagedPhoto({required this.name, required this.bytes, this.caption = ''});

  final String name;
  final Uint8List bytes;
  final String caption;

  StagedPhoto withCaption(String c) =>
      StagedPhoto(name: name, bytes: bytes, caption: c);
}

/// Seção "Fotos" de um formulário de **criação**: escolhe as imagens agora
/// (com legenda), o envio acontece depois que a entidade é salva (a tela
/// chama `AttachmentController.submitPhoto` com o id novo). Em telas de
/// edição use a `PhotosSection` (que já envia direto).
class StagedPhotosField extends StatefulWidget {
  const StagedPhotosField({
    super.key,
    required this.photos,
    required this.onChanged,
  });

  final List<StagedPhoto> photos;
  final ValueChanged<List<StagedPhoto>> onChanged;

  @override
  State<StagedPhotosField> createState() => _StagedPhotosFieldState();
}

class _StagedPhotosFieldState extends State<StagedPhotosField> {
  final _captions = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(StagedPhotosField old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// Mantém um controller por foto; um novo controller começa com a legenda
  /// que veio da foto.
  void _sync() {
    while (_captions.length < widget.photos.length) {
      _captions.add(
        TextEditingController(text: widget.photos[_captions.length].caption),
      );
    }
    while (_captions.length > widget.photos.length) {
      _captions.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final c in _captions) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    widget.onChanged([
      ...widget.photos,
      StagedPhoto(name: file.name, bytes: bytes),
    ]);
  }

  void _remove(int i) {
    _captions.removeAt(i).dispose();
    widget.onChanged([...widget.photos]..removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.photos.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Image.memory(
                      widget.photos[i].bytes,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () => _remove(i),
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _captions[i],
                    decoration: const InputDecoration(
                      labelText: 'Legenda (opcional)',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final next = [...widget.photos];
                      next[i] = next[i].withCaption(v);
                      widget.onChanged(next);
                    },
                  ),
                ),
              ],
            ),
          ),
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
      ],
    );
  }
}
