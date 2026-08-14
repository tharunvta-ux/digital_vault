import 'package:flutter/material.dart';

import '../../../../core/utils/app_dimensions.dart';

/// A small rounded tile showing an icon appropriate to [fileType].
class DocumentFileIcon extends StatelessWidget {
  const DocumentFileIcon({required this.fileType, super.key});

  final String fileType;

  IconData get _icon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Icon(_icon, color: colorScheme.onPrimaryContainer),
    );
  }
}
