import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'nyutji_loading_overlay.dart';
import '../constants/api_constants.dart';

class NyutjiImagePicker {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required Function(XFile) onImagePicked,
    Color primaryColor = const Color(0xFF286B6A),
    String? currentImageUrl,
  }) async {
    final ImagePicker picker = ImagePicker();
    
    String? finalImageUrl;
    if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      if (currentImageUrl.startsWith('http')) {
        finalImageUrl = currentImageUrl;
      } else if (!currentImageUrl.contains('uploads/')) {
        finalImageUrl = "${ApiConstants.rootUrl}/uploads/profiles/$currentImageUrl";
      } else {
        finalImageUrl = "${ApiConstants.rootUrl}/$currentImageUrl";
      }
    }

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // --- SMART DYNAMIC PADDING ---
        // Menangani notch dan navigation bar di berbagai perangkat secara otomatis
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        
        return Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar (Mewah)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              if (finalImageUrl != null) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: NetworkImage(finalImageUrl),
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 28),
              
              Row(
                children: [
                  Expanded(
                    child: _buildOption(
                      context,
                      icon: LucideIcons.camera,
                      label: "Kamera",
                      color: primaryColor,
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? photo = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 50,
                        );
                        if (photo != null) {
                          if (context.mounted) NyutjiLoadingOverlay.show(context, message: "Mengompresi & Mengunggah...");
                          try {
                            final compressedPhoto = await compressToWebP(photo);
                            await onImagePicked(compressedPhoto ?? photo);
                          } finally {
                            if (context.mounted) NyutjiLoadingOverlay.hide(context);
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOption(
                      context,
                      icon: LucideIcons.image,
                      label: "Galeri",
                      color: primaryColor,
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 50,
                        );
                        if (image != null) {
                          if (context.mounted) NyutjiLoadingOverlay.show(context, message: "Mengompresi & Mengunggah...");
                          try {
                            final compressedImage = await compressToWebP(image);
                            await onImagePicked(compressedImage ?? image);
                          } finally {
                            if (context.mounted) NyutjiLoadingOverlay.hide(context);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.12), width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  static Future<XFile?> compressToWebP(XFile file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.absolute.path}/${DateTime.now().millisecondsSinceEpoch}.webp';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        format: CompressFormat.webp,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
      );
      return result;
    } catch (e) {
      debugPrint("Gagal mengompresi ke WebP: $e");
      return null;
    }
  }
}
