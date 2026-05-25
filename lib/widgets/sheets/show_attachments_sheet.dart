import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pagame/models/payment_record.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/screens/services/attachment_viewer_screen.dart';
import 'package:pagame/theme/app_colors.dart';

class ShowAttachmentsSheet extends StatelessWidget {
  const ShowAttachmentsSheet({
    super.key,
    required this.payment,
    required this.service,
    required this.year,
    required this.monthName,
  });

  final PaymentRecord payment;
  final ServiceItem service;
  final int year;
  final String monthName;

  bool _isImage(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final paths = payment.attachments;
    final maxOffset = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxOffset),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Archivos Adjuntos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${paths.length} ${paths.length == 1 ? 'archivo asociado' : 'archivos asociados'} a este pago.',
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: paths.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final path = paths[index];
                    final isImg = _isImage(path);
                    final fileName = path.split('/').last.split('\\').last;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                          color: AppColors.card,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: isImg
                            ? Image.file(
                                File(path),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.inkMuted,
                                ),
                              )
                            : const Icon(
                                Icons.picture_as_pdf_outlined,
                                color: Colors.redAccent,
                              ),
                      ),
                      title: Text(
                        fileName,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        isImg ? 'Imagen' : 'Documento PDF',
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.fullscreen_rounded,
                          color: AppColors.accent,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AttachmentViewerScreen(
                                path: path,
                                serviceName: service.name,
                                year: year,
                                monthName: monthName,
                              ),
                            ),
                          );
                        },
                        tooltip: 'Ver pantalla completa',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
