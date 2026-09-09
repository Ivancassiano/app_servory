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
///
/// - [showAdd] (padrão `true`): mostra o botão "Adicionar foto". As telas de
///   **visualização** de item/local passam `false` — lá a foto é só leitura.
/// - [onToggleRemoval] (só nos formulários de **edição** de item/local): põe um
///   "×" em cada foto já enviada pra marcá-la pra remoção. A marcação é
///   **reversível** e só vira `DELETE` de verdade quando a tela chama
///   `AttachmentController.deletePhoto` no "Salvar" — clicar em "Cancelar"
///   descarta as marcações. [pendingRemovalIds] são as fotos já marcadas.
class PhotosSection extends ConsumerWidget {
  const PhotosSection({
    super.key,
    required this.ownerKind,
    required this.ownerId,
    this.serviceOrderItemId,
    this.showAdd = true,
    this.pendingRemovalIds = const {},
    this.onToggleRemoval,
  });

  final String ownerKind;
  final String ownerId;
  final String? serviceOrderItemId;
  final bool showAdd;
  final Set<String> pendingRemovalIds;
  final void Function(String photoId)? onToggleRemoval;

  /// Prefere a cópia local (cache offline, mais rápida) e cai na URL
  /// assinada quando não há cache.
  static ImageProvider _photoImage(EntityPhoto p) {
    final local = p.localPath;
    if (local != null) {
      final img = localFileImageProvider(local);
      if (img != null) return img;
    }
    return NetworkImage(p.downloadUrl);
  }

  Widget _toggleBadge({required bool marked, required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        child: Container(
          color: Colors.black54,
          padding: const EdgeInsets.all(2),
          child: Icon(
            marked ? Icons.undo : Icons.close,
            size: 16,
            color: Colors.white,
          ),
        ),
      );

  Widget _uploadedThumb(
    BuildContext context, {
    required List<GalleryPhoto> gallery,
    required int index,
    required String photoId,
  }) {
    final marked = pendingRemovalIds.contains(photoId);
    final thumb = PhotoThumb(
      image: gallery[index].image,
      caption: gallery[index].caption,
      badge: onToggleRemoval == null
          ? null
          : _toggleBadge(
              marked: marked,
              onTap: () => onToggleRemoval!(photoId),
            ),
      onTap: () =>
          openPhotoGallery(context, photos: gallery, initialIndex: index),
    );
    return marked ? Opacity(opacity: 0.4, child: thumb) : thumb;
  }

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
        GalleryPhoto(image: _photoImage(p), caption: p.caption ?? ''),
      for (final item in pendingPhotos)
        if (localFileImageProvider(item.filePath) case final img?)
          GalleryPhoto(image: img, caption: item.caption ?? ''),
    ];

    if (!showAdd && gallery.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Nenhuma foto.'),
      );
    }

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
              _uploadedThumb(
                context,
                gallery: gallery,
                index: i,
                photoId: uploaded[i].id,
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
        if (showAdd) ...[
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
      ],
    );
  }
}
