import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Uma foto escolhida mas ainda não enviada (cadastro que ainda não foi
/// salvo — não há `ownerId` pra fila de upload).
typedef StagedPhoto = ({String name, Uint8List bytes});

/// Seção "Fotos" de um formulário de **criação**: escolhe as imagens agora,
/// o envio acontece depois que a entidade é salva (a tela chama
/// `AttachmentController.submitPhoto` com o id novo). Em telas de edição use
/// a `PhotosSection` (que já envia direto).
class StagedPhotosField extends StatelessWidget {
  const StagedPhotosField({
    super.key,
    required this.photos,
    required this.onChanged,
  });

  final List<StagedPhoto> photos;
  final ValueChanged<List<StagedPhoto>> onChanged;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    onChanged([...photos, (name: file.name, bytes: bytes)]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < photos.length; i++)
                  Stack(
                    children: [
                      Image.memory(
                        photos[i].bytes,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: InkWell(
                          onTap: () => onChanged(
                            [...photos]..removeAt(i),
                          ),
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
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(context, ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Câmera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(context, ImageSource.gallery),
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
