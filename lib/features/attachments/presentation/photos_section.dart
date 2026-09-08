import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/local_file_image.dart';
import '../application/service_order_attachments_provider.dart';
import '../application/upload_queue_provider.dart';
import 'photo_capture_sheet.dart';

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
            for (final photo in uploaded)
              _Thumb(
                caption: photo.caption ?? '',
                onTap: () => _openViewer(
                  context,
                  imageUrl: photo.downloadUrl,
                  caption: photo.caption ?? '',
                ),
                child: Image.network(
                  photo.downloadUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _brokenThumb(context),
                ),
              ),
            for (final item in pendingPhotos)
              _Thumb(
                caption: item.caption ?? '',
                badge: const Icon(
                  Icons.cloud_upload_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                onTap: () => _openViewer(
                  context,
                  localPath: item.filePath,
                  caption: item.caption ?? '',
                ),
                child: localFileImage(item.filePath, width: 96, height: 96),
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

  Widget _brokenThumb(BuildContext context) => Container(
    width: 96,
    height: 96,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Icon(Icons.broken_image_outlined),
  );

  void _openViewer(
    BuildContext context, {
    String? imageUrl,
    String? localPath,
    required String caption,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(
          imageUrl: imageUrl,
          localPath: localPath,
          caption: caption,
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.child,
    required this.caption,
    required this.onTap,
    this.badge,
  });

  final Widget child;
  final String caption;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
                if (badge != null) Positioned(right: 2, top: 2, child: badge!),
              ],
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({this.imageUrl, this.localPath, required this.caption});

  final String? imageUrl;
  final String? localPath;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 64,
                        ),
                      )
                    : localFileImage(localPath!, fit: BoxFit.contain),
              ),
            ),
          ),
          if (caption.isNotEmpty)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.black,
                child: Text(
                  caption,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
