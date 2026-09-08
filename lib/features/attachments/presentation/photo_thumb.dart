import 'package:flutter/material.dart';

/// Miniatura de foto (96px) com a legenda embaixo. Tocar chama [onTap]
/// (normalmente abre em tela cheia via [openPhotoFullscreen]). [badge] é um
/// selo opcional no canto (ex.: ícone de "pendente de envio").
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

/// Abre uma foto em tela cheia (zoom por [InteractiveViewer]) com a legenda
/// numa barra embaixo.
void openPhotoFullscreen(
  BuildContext context, {
  required ImageProvider image,
  required String caption,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _FullscreenPhoto(image: image, caption: caption),
    ),
  );
}

class _FullscreenPhoto extends StatelessWidget {
  const _FullscreenPhoto({required this.image, required this.caption});

  final ImageProvider image;
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
                child: Image(
                  image: image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
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
