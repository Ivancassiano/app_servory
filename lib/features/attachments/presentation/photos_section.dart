import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/local_file_image.dart';
import '../application/service_order_attachments_provider.dart';
import '../application/upload_queue_provider.dart';
import 'photo_capture_sheet.dart';

/// Galeria de fotos de um dono (`ownerKind` ∈ service_order | item | location):
/// já enviadas (`entityPhotosProvider`) + as ainda na fila de upload local
/// (`uploadQueueForOwnerProvider`, só nativo). `serviceOrderItemId` (só faz
/// sentido em ordem de serviço) nulo = fotos **gerais**; setado = só as do item
/// da visita.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...uploadedAsync.maybeWhen(
              data: (photos) => photos
                  .where((p) => p.serviceOrderItemId == serviceOrderItemId)
                  .map(
                    (photo) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photo.downloadUrl,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 96,
                          height: 96,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              orElse: () => const [],
            ),
            ...pendingPhotos.map(
              (item) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: localFileImage(item.filePath, width: 96, height: 96),
                  ),
                  const Positioned(
                    right: 2,
                    top: 2,
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
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
