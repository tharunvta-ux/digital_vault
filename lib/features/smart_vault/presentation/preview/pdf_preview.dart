import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';

/// Scrollable, pinch-to-zoom PDF preview.
///
/// `pdfx`'s `PdfDocument` only opens a file path, an asset, or raw bytes --
/// there is no built-in network loader (confirmed by reading the package
/// source), so the download URL is fetched with a plain HTTP GET first.
/// This is a generic HTTP call against a signed download URL, not a
/// Storage SDK call -- it doesn't violate "no backend SDK in widgets,"
/// since nothing here imports a Supabase or Firebase package directly.
class PdfPreview extends StatefulWidget {
  const PdfPreview({required this.url, super.key});

  final String url;

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<PdfPreview> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(document: _loadDocument());
  }

  Future<PdfDocument> _loadDocument() async {
    final response = await http.get(Uri.parse(widget.url));
    if (response.statusCode != 200) {
      throw StateError('Failed to download PDF (HTTP ${response.statusCode}).');
    }
    return PdfDocument.openData(response.bodyBytes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(
      controller: _controller,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (context) => const LoadingIndicator(message: 'Loading PDF...'),
        errorBuilder: (context, error) => const AppErrorWidget(message: 'Could not load PDF preview.'),
      ),
    );
  }
}
