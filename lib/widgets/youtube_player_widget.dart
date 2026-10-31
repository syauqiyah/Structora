import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_translations.dart';

class YouTubeVideoPlayerWidget extends StatelessWidget {
  final String videoId;
  final VoidCallback? onPlayTriggered;

  const YouTubeVideoPlayerWidget({
    super.key,
    required this.videoId,
    this.onPlayTriggered,
  });

  Future<void> _launchYouTube(BuildContext context) async {
    final bool isEn = LanguageController.instance.isEnglish;
    // Memicu pencatatan progres modul saat tombol ditekan
    onPlayTriggered?.call();

    // 1. Coba buka langsung di aplikasi resmi YouTube (Android intent)
    final Uri appUri = Uri.parse('vnd.youtube:$videoId');
    // 2. URL alternatif (Web browser)
    final Uri webUri = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching YouTube: $e');
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn ? 'Cannot open video link' : 'Tidak dapat membuka tautan video'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageController.instance.isEnglish;

    if (videoId.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Text(
          isEn ? 'Video not available' : 'Video belum tersedia',
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
      );
    }

    // Mengambil thumbnail resolusi tinggi dari server YouTube
    final String thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _launchYouTube(context),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar Sampul Video
                  Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF0F172A),
                      child: const Center(
                        child: Icon(
                          Icons.video_library_outlined,
                          color: Colors.white24,
                          size: 50,
                        ),
                      ),
                    ),
                  ),

                  // Lapisan Overlay Gelap agar Tombol Terlihat Jelas
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),

                  // Tombol Play YouTube di Tengah
                  Center(
                    child: Container(
                      width: 68,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000), // Merah khas YouTube
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF0000).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),

                  // Label Keterangan di Bagian Bawah Sampul
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.smart_display_rounded,
                                size: 14,
                                color: Color(0xFF00F0FF),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isEn ? 'Tap to Watch' : 'Ketuk untuk Menonton',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'YouTube App',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 12,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}