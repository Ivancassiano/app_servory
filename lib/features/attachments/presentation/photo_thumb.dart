import 'package:flutter/material.dart';

/// Miniatura de foto (96px) com a legenda embaixo. Tocar chama [onTap]
/// (normalmente abre a galeria via [openPhotoGallery]). [badge] é um selo
/// opcional no canto (ex.: ícone de "pendente de envio").
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.image,
    required this.caption,
    required this.onTap,
    this.badge,
  });

  final ImageProvider image;
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: image,
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

/// Uma foto na galeria em tela cheia.
class GalleryPhoto {
  const GalleryPhoto({required this.image, this.caption = ''});
  final ImageProvider image;
  final String caption;
}

/// Abre uma galeria de fotos em tela cheia: arrasta pro lado pra trocar de
/// foto, pinça pra dar zoom em cada uma. Começa em [initialIndex].
void openPhotoGallery(
  BuildContext context, {
  required List<GalleryPhoto> photos,
  required int initialIndex,
}) {
  if (photos.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _GalleryViewer(
        photos: photos,
        initialIndex: initialIndex.clamp(0, photos.length - 1),
      ),
    ),
  );
}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.photos, required this.initialIndex});

  final List<GalleryPhoto> photos;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;
    final caption = widget.photos[_index].caption;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: total > 1
            ? Text(
                '${_index + 1} / $total',
                style: const TextStyle(fontSize: 14),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: total,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _ZoomablePhoto(image: widget.photos[i].image),
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

/// Uma foto da galeria: pinça pra dar zoom, dois toques pra voltar. O
/// arraste horizontal só é consumido quando está com zoom — sem zoom ele
/// passa pro [PageView] trocar de foto.
class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.image});
  final ImageProvider image;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final _tc = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _tc.addListener(() {
      final zoomed = _tc.value.getMaxScaleOnAxis() > 1.01;
      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => _tc.value = Matrix4.identity(),
      child: InteractiveViewer(
        transformationController: _tc,
        panEnabled: _zoomed,
        maxScale: 5,
        child: Center(
          child: Image(
            image: widget.image,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
