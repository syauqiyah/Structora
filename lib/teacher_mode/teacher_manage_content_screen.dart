import 'package:flutter/material.dart';
import '../utils/app_translations.dart';
import 'teacher_content_helper.dart';
import 'teacher_content_form_screen.dart';

class TeacherManageContentScreen extends StatefulWidget {
  final bool isDarkMode;
  final String? language;

  const TeacherManageContentScreen({
    super.key,
    required this.isDarkMode,
    this.language,
  });

  @override
  State<TeacherManageContentScreen> createState() =>
      _TeacherManageContentScreenState();
}

class _TeacherManageContentScreenState
    extends State<TeacherManageContentScreen> {
  List<dynamic> _allList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    LanguageController.instance.addListener(_onLanguageChanged);
    _loadMateriData();
  }

  @override
  void dispose() {
    LanguageController.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadMateriData() async {
    final data = await TeacherContentHelper.getMateriList();
    if (!mounted) return;
    setState(() {
      _allList = data;
      _isLoading = false;
    });
  }

  void _navigateToForm({Map<String, dynamic>? existingMateri}) async {
    final learningModules = _allList.where((m) {
      final id = (m['id'] ?? '').toString();
      return id != 'pretest' && id != 'posttest';
    }).toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherContentFormScreen(
          isDarkMode: widget.isDarkMode,
          existingMateri: existingMateri,
          nextPertemuanNumber: learningModules.length + 1,
        ),
      ),
    );

    if (result == true) {
      _loadMateriData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageController.instance.isEnglish;

    final Color bgColor =
    widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFFF8FAFC);
    final Color cardBg =
    widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor =
    widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor =
    widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const Color accentColor = Color(0xFF00F0FF);
    final Color borderColor =
    widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    // Pisahkan evaluasi umum (pre/post) dan materi modul
    final evalList = _allList.where((item) {
      final id = (item['id'] ?? '').toString();
      return id == 'pretest' || id == 'posttest';
    }).toList();

    final moduleList = _allList.where((item) {
      final id = (item['id'] ?? '').toString();
      return id != 'pretest' && id != 'posttest';
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppText.tr('manage_content_title'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppText.tr('manage_content_subtitle'),
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _navigateToForm(),
                  icon: const Icon(Icons.add, color: Colors.black, size: 18),
                  label: Text(
                    AppText.tr('btn_upload_material'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SEKSI 1: EVALUASI PRE-TEST & POST-TEST
            Row(
              children: [
                const Icon(Icons.fact_check_rounded,
                    color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppText.tr('eval_package_title'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...evalList.map((item) {
              final isPre = item['id'] == 'pretest';
              final Color badgeColor =
              isPre ? Colors.amber : const Color(0xFFE11D48);
              final List qList = (item['questions'] as List?) ?? [];

              // Judul evaluasi diterjemahkan otomatis
              final String itemTitle = isEn
                  ? (item['title_en'] ?? AppText.auto(item['title'] ?? ''))
                  : (item['title'] ?? '');

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPre
                          ? Icons.assignment_turned_in_outlined
                          : Icons.workspace_premium_outlined,
                      color: badgeColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemTitle,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEn
                                ? '${qList.length} questions installed • Key & script editable'
                                : '${qList.length} butir soal terpasang • Kunci & naskah dapat diedit',
                            style: TextStyle(
                                fontSize: 11, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, size: 22),
                      color: badgeColor,
                      tooltip: isEn
                          ? 'Edit Evaluation Questions'
                          : 'Edit Butir Soal Evaluasi',
                      onPressed: () =>
                          _navigateToForm(existingMateri: item),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            Divider(color: borderColor),
            const SizedBox(height: 12),

            // SEKSI 2: DAFTAR SESI PERTEMUAN MODUL
            Row(
              children: [
                const Icon(Icons.menu_book_rounded,
                    color: accentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppText.tr('learning_modules_title'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (moduleList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    isEn
                        ? 'No learning session modules yet.'
                        : 'Belum ada modul sesi pembelajaran.',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                ),
              )
            else
              ...List.generate(moduleList.length, (idx) {
                final item = moduleList[idx] as Map<String, dynamic>;
                final String videoUrl = item['videoUrl'] ?? '';
                final List questions = (item['questions'] as List?) ?? [];

                // Penyesuaian nama sesi dan judul modul
                final String modulLabel = isEn
                    ? (item['modul_en'] ?? AppText.auto(item['modul'] ?? 'Meeting ${idx + 1}'))
                    : (item['modul'] ?? 'Pertemuan ${idx + 1}');

                final String titleText = isEn
                    ? (item['title_en'] ?? AppText.auto(item['title'] ?? ''))
                    : (item['title'] ?? '');

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _navigateToForm(existingMateri: item),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                            accentColor.withValues(alpha: 0.15),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  modulLabel,
                                  style: const TextStyle(
                                    color: accentColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  titleText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_fill_rounded,
                                      size: 13,
                                      color: videoUrl.isNotEmpty
                                          ? Colors.redAccent
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      videoUrl.isNotEmpty
                                          ? (isEn
                                          ? 'Video Active'
                                          : 'Video Aktif')
                                          : (isEn
                                          ? 'No Video'
                                          : 'Tanpa Video'),
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          color: subTextColor),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.quiz_rounded,
                                      size: 13,
                                      color: questions.isNotEmpty
                                          ? Colors.greenAccent
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isEn
                                          ? '${questions.length} Assessment Questions'
                                          : '${questions.length} Soal Asesmen',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          color: subTextColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Color(0xFF00F0FF), size: 20),
                            tooltip: isEn
                                ? 'Edit & Open Details'
                                : 'Edit & Buka Detail',
                            onPressed: () =>
                                _navigateToForm(existingMateri: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                            tooltip: isEn
                                ? 'Delete Meeting'
                                : 'Hapus Pertemuan',
                            onPressed: () async {
                              final bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: cardBg,
                                  title: Text(
                                    isEn ? 'Delete Module?' : 'Hapus Pertemuan?',
                                    style: TextStyle(color: textColor),
                                  ),
                                  content: Text(
                                    isEn
                                        ? 'Are you sure you want to delete "$titleText"? This action cannot be undone.'
                                        : 'Apakah Anda yakin ingin menghapus "$titleText"? Tindakan ini tidak dapat dibatalkan.',
                                    style: TextStyle(color: subTextColor),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(isEn ? 'Cancel' : 'Batal', style: TextStyle(color: subTextColor)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      child: Text(isEn ? 'Delete' : 'Hapus', style: const TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await TeacherContentHelper.deleteMateri(
                                    item['id']?.toString() ?? '');
                                _loadMateriData();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}