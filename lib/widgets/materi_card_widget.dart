import 'package:flutter/material.dart';
import '../utils/app_translations.dart';

class MateriCardWidget extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double progressRatio;
  final VoidCallback onTap;

  const MateriCardWidget({
    super.key,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progressRatio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = LanguageController.instance.isEnglish;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnlocked ? color.withValues(alpha: 0.5) : borderColor,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? color.withValues(alpha: 0.15)
                          : (isDark ? Colors.white10 : Colors.black12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isUnlocked ? icon : Icons.lock_outline,
                      color: isUnlocked ? color : subTextColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? textColor : subTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUnlocked
                              ? desc
                              : (isEn ? 'Locked. Complete previous modules.' : 'Terkunci. Selesaikan materi sebelumnya.'),
                          style: TextStyle(fontSize: 10.5, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                  if (isUnlocked)
                    Text(
                      '${(progressRatio * 100).toInt()}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                    )
                  else
                    Icon(Icons.lock, size: 16, color: subTextColor),
                ],
              ),
              if (isUnlocked) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 4,
                    backgroundColor: isDark ? const Color(0xFF060913) : const Color(0xFFF8FAFC),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}