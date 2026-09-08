import 'package:flutter/material.dart';

import 'photo_capture_sheet.dart';
import 'photo_thumb.dart';

export 'photo_capture_sheet.dart' show StagedPhoto;

/// Seção "Fotos" de um formulário de **criação**: mesma pegada da
/// [PhotoCaptureSheet] usada nas telas já salvas — "Adicionar foto" abre o
/// bottom sheet (câmera/galeria + legenda); a foto fica na lista e o envio
/// acontece depois que a entidade é salva (a tela chama
/// `AttachmentController.submitPhoto` com o id novo).
class StagedPhotosField extends StatelessWidget {
  const StagedPhotosField({
    super.key,
    required this.photos,
    required this.onChanged,
  });

  final List<StagedPhoto> photos;
  final ValueChanged<List<StagedPhoto>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < photos.length; i++)
                  PhotoThumb(
                    image: MemoryImage(photos[i].bytes),
                    caption: photos[i].caption,
                    badge: InkWell(
                      onTap: () => onChanged([...photos]..removeAt(i)),
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
                    onTap: () => openPhotoFullscreen(
                      context,
                      image: MemoryImage(photos[i].bytes),
                      caption: photos[i].caption,
                    ),
                  ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => PhotoCaptureSheet(
                onStaged: (p) => onChanged([...photos, p]),
              ),
            ),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Adicionar foto'),
          ),
        ),
      ],
    );
  }
}
