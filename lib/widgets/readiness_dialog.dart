import 'package:flutter/material.dart';
import '../utils/app_translations.dart';

class ReadinessDialog extends StatefulWidget {
  final String currentModuleName;
  final String nextModuleName;
  final bool isDarkMode;
  final VoidCallback onReady;
  final VoidCallback onReview;

  const ReadinessDialog({
    super.key,
    required this.currentModuleName,
    required this.nextModuleName,
    required this.isDarkMode,
    required this.onReady,
    required this.onReview,
  });

  @override
  State<ReadinessDialog> createState() => _ReadinessDialogState();
}

class _ReadinessDialogState extends State<ReadinessDialog> {
  // 3 Indikator refleksi diri singkat
  bool _understandsConcept = false;
  bool _understandsOperation = false;
  bool _readyForNext = false;

  bool get _isAllChecked =>
      _understandsConcept && _understandsOperation && _readyForNext;

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageController.instance.isEnglish;

    final cardBg = widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final accentColor = widget.isDarkMode ? const Color(0xFF00F0FF) : const Color(0xFF0284C7);
    final boxInnerBg = widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFFF8FAFC);
    final borderColor = widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: Icon(Icons.psychology, size: 20, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEn ? 'Learning Readiness Check' : 'Cek Kesiapan Belajar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'Before advancing to ${widget.nextModuleName}, let\'s reflect on your understanding of ${widget.currentModuleName}:'
                  : 'Sebelum melangkah ke materi ${widget.nextModuleName}, mari refleksi pemahamanmu di ${widget.currentModuleName}:',
              style: TextStyle(fontSize: 11.5, color: subTextColor, height: 1.4),
            ),
            const SizedBox(height: 14),

            _buildCheckItem(
              boxInnerBg: boxInnerBg,
              borderColor: borderColor,
              textColor: textColor,
              accentColor: accentColor,
              title: isEn
                  ? 'I understand basic concepts and analogies for this topic.'
                  : 'Saya memahami konsep dasar dan analogi materi ini.',
              value: _understandsConcept,
              onChanged: (val) => setState(() => _understandsConcept = val ?? false),
            ),
            const SizedBox(height: 8),

            _buildCheckItem(
              boxInnerBg: boxInnerBg,
              borderColor: borderColor,
              textColor: textColor,
              accentColor: accentColor,
              title: isEn
                  ? 'I understand data operations and simulation flow.'
                  : 'Saya mengerti alur operasi data dan simulasinya.',
              value: _understandsOperation,
              onChanged: (val) => setState(() => _understandsOperation = val ?? false),
            ),
            const SizedBox(height: 8),

            _buildCheckItem(
              boxInnerBg: boxInnerBg,
              borderColor: borderColor,
              textColor: textColor,
              accentColor: accentColor,
              title: isEn
                  ? 'I am ready to learn the next module with focus.'
                  : 'Saya siap mempelajari materi berikutnya dengan fokus.',
              value: _readyForNext,
              onChanged: (val) => setState(() => _readyForNext = val ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onReview,
          child: Text(
            isEn ? 'Review Material' : 'Ulas Kembali Materi',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isAllChecked ? widget.onReady : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            disabledBackgroundColor: borderColor,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: Text(
            isEn ? 'I\'m Ready! 🚀' : 'Saya Siap Lanjut! 🚀',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _isAllChecked ? Colors.black : subTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem({
    required Color boxInnerBg,
    required Color borderColor,
    required Color textColor,
    required Color accentColor,
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: boxInnerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? accentColor.withValues(alpha: 0.5) : borderColor,
        ),
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          title,
          style: TextStyle(fontSize: 11, color: textColor),
        ),
        value: value,
        activeColor: accentColor,
        checkColor: Colors.black,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: onChanged,
      ),
    );
  }
}