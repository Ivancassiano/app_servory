import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/local_file_image.dart';
import '../application/service_order_attachments_provider.dart';
import '../application/upload_queue_provider.dart';
import 'photo_capture_sheet.dart';
import 'photo_thumb.dart';

/// Galeria de fotos de um dono (`ownerKind` ∈ service_order | item | location):
/// já enviadas (`entityPhotosProvider`) + as ainda na fila de upload local
/// (`uploadQueueForOwnerProvider`, só nativo). Tocar numa foto abre em tela
/// cheia com a legenda. `serviceOrderItemId` (só faz sentido em ordem de
/// serviço) nulo = fotos **gerais**; setado = só as do item da visita.
class PhotosSection extends ConsumerWidget {
  const PhotosSection({
    super.key,
    required this.ownerKind,
    required this.ownerId,
    this.serviceOrderItemId,
  });

  final String ownerKind;
  final String ownerId;
  final String? serviceOrderItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadedAsync = ref.watch(
      entityPhotosProvider((ownerKind, ownerId)),
    );
    final pendingAsync = ref.watch(
      uploadQueueForOwnerProvider((ownerKind, ownerId)),
    );
    final pendingPhotos = (pendingAsync.value ?? const <UploadQueueData>[])
        .where(
          (i) =>
              i.kind == 'photo' && i.serviceOrderItemId == serviceOrderItemId,
        )
        .toList();
    final uploaded = uploadedAsync.maybeWhen(
      data: (photos) => photos
          .where((p) => p.serviceOrderItemId == serviceOrderItemId)
          .toList(),
      orElse: () => const <EntityPhoto>[],
    );

    // Galeria única (arrasta pro lado): enviadas primeiro, depois pendentes.
    final gallery = <GalleryPhoto>[
      for (final p in uploaded)
        GalleryPhoto(image: NetworkImage(p.downloadUrl), caption: p.caption ?? ''),
      for (final item in pendingPhotos)
        if (localFileImageProvider(item.filePath) case final img?)
          GalleryPhoto(image: img, caption: item.caption ?? ''),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (uploadedAsync.hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Não foi possível carregar as fotos.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < uploaded.length; i++)
              PhotoThumb(
                image: gallery[i].image,
                caption: gallery[i].caption,
                onTap: () => openPhotoGallery(
                  context,
                  photos: gallery,
                  initialIndex: i,
                ),
              ),
            for (var j = 0; j < pendingPhotos.length; j++)
              if (localFileImageProvider(pendingPhotos[j].filePath)
                  case final img?)
                PhotoThumb(
                  image: img,
                  caption: pendingPhotos[j].caption ?? '',
                  badge: const Icon(
                    Icons.cloud_upload_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  onTap: () => openPhotoGallery(
                    context,
                    photos: gallery,
                    initialIndex: uploaded.length + j,
                  ),
                ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => PhotoCaptureSheet(
                ownerKind: ownerKind,
                ownerId: ownerId,
                serviceOrderItemId: serviceOrderItemId,
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
