import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class AttachmentViewerScreen extends StatelessWidget {
  const AttachmentViewerScreen({
    super.key,
    required this.path,
    required this.serviceName,
    required this.year,
    required this.monthName,
  });

  final String path;
  final String serviceName;
  final int year;
  final String monthName;

  bool _isImage(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  Future<void> _shareFile() async {
    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(path)],
      text: '$serviceName / $year / $monthName Adjunto de Págame App',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isImg = _isImage(path);
    final fileName = path.split('/').last.split('\\').last;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          fileName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareFile,
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: Center(
        child: isImg
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: path,
                  child: Image.file(
                    File(path),
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        'No se pudo cargar la imagen',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Colors.redAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Documento PDF',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _shareFile,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Compartir archivo'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueGrey[800],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
