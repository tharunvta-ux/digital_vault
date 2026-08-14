import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Pinch-to-zoom image preview. `NetworkImage` fetches the bytes itself
/// (Flutter's own cross-platform image pipeline, including web) -- no
/// manual HTTP handling needed here, unlike [PdfPreview].
class ImagePreview extends StatelessWidget {
  const ImagePreview({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: NetworkImage(url),
      backgroundDecoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(Icons.broken_image_outlined, size: 48, color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
