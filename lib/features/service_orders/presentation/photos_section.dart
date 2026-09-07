import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/local_file_image.dart';
import '../../attachments/application/pending_uploads.dart';
import '../../attachments/application/service_order_attachments_provider.dart';
import '../../attachments/presentation/photo_capture_sheet.dart';

/// Galeria de fotos da ordem — já enviadas (`orderPhotosProvider`) + as ainda
/// na fila de upload local (`uploadQueueForOrderProvider`, só nativo).
/// `serviceOrderItemId` nulo = as fotos **gerais** da ordem; setado = só as
/// daquele item da visita (e novas ficam vinculadas a ele).
class PhotosSection extends ConsumerWidget {
  const PhotosSection({
    super.key,
    required this.serviceOrderId,
    this.serviceOrderItemId,
  });

  final String serviceOrderId;
  final String? serviceOrderItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadedAsync = ref.watch(orderPhotosProvider(serviceOrderId));
    final pendingAsync = ref.watch(uploadQueueForOrderProvider(serviceOrderId));
    final pendingPhotos = (pendingAsync.value ?? const <UploadQueueData>[])
        .where(
          (i) =>
              i.kind == 'photo' &&
              i.serviceOrderItemId == serviceOrderItemId,
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
        OutlinedButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => PhotoCaptureSheet(
              serviceOrderId: serviceOrderId,
              serviceOrderItemId: serviceOrderItemId,
            ),
          ),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Adicionar foto'),
        ),
      ],
    );
  }
}
