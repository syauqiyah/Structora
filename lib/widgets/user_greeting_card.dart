import 'package:flutter/material.dart';
import '../utils/app_translations.dart';

class UserGreetingCard extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;

  const UserGreetingCard({
    super.key,
    required this.userName,
    this.profileImageUrl,
  });

  String _getGreetingText(bool isEn) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return isEn ? 'Good Morning' : 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return isEn ? 'Good Afternoon' : 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return isEn ? 'Good Evening' : 'Selamat Sore';
    } else {
      return isEn ? 'Good Night' : 'Selamat Malam';
    }
  }

  String _getFirstName() {
    final clean = userName.trim();
    if (clean.isEmpty) return 'Siswa';
    return clean.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LanguageController.instance.isEnglish;
    final String greeting = _getGreetingText(isEn);
    final String firstName = _getFirstName();
    final String fullName = userName.trim().toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF03226A),
            Color(0xFF003CB5),
            Color(0xFF0256EB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0256EB).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        isEn ? 'Student' : 'Mahasiswa',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 2.5,
              ),
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFF1E293B),
              backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                  ? AssetImage(profileImageUrl!) as ImageProvider
                  : null,
              child: profileImageUrl == null || profileImageUrl!.isEmpty
                  ? const Icon(Icons.person, size: 38, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}