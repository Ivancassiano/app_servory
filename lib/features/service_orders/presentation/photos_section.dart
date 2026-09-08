import 'package:flutter/material.dart';

import '../../attachments/presentation/photos_section.dart' as generic;

/// Galeria de fotos de uma ordem de serviço — fina camada sobre a
/// `PhotosSection` genérica de anexos (`ownerKind: 'service_order'`).
class PhotosSection extends StatelessWidget {
  const PhotosSection({
    super.key,
    required this.serviceOrderId,
    this.serviceOrderItemId,
  });

  final String serviceOrderId;
  final String? serviceOrderItemId;

  @override
  Widget build(BuildContext context) => generic.PhotosSection(
    ownerKind: 'service_order',
    ownerId: serviceOrderId,
    serviceOrderItemId: serviceOrderItemId,
  );
}
