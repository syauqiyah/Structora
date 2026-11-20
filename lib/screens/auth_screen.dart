import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../teacher_mode/teacher_data_helper.dart';
import '../services/firebase_service.dart';
import '../utils/app_translations.dart';

class AuthScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(String name, String email, bool isTeacher) onLoginSuccess;

  const AuthScreen({
    super.key,
    required this.isDarkMode,
    required this.onLoginSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String? _selectedRole;
  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    LanguageController.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageController.instance.removeListener(_onLanguageChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _prepareRoleAccess(String role) async {
    setState(() {
      _selectedRole = role;
      _isRegisterMode = false;
      _obscurePassword = true;
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
    });

    try {
      if (!kIsWeb) {
        FirebaseAuth.instance.signOut().catchError((_) {});
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userName');
      await prefs.remove('userEmail');
      await prefs.setBool('isLoggedIn', false);
      await prefs.setBool('isTeacher', role == 'teacher');
    } catch (e) {
      debugPrint('Catatan penyiapan role: $e');
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    final bool isEn = LanguageController.instance.isEnglish;

    final String email = _emailCtrl.text.trim();
    final String pass = _passCtrl.text.trim();
    final String name = _nameCtrl.text.trim();
    final bool isTeacher = _selectedRole == 'teacher';

    if (email.isEmpty || pass.isEmpty || (_isRegisterMode && name.isEmpty)) {
      _showMsg(isEn ? 'Please fill in all fields' : 'Harap lengkapi semua data');
      return;
    }

    final bool emailValid =
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!emailValid) {
      _showMsg(isEn ? 'Enter a valid email address' : 'Masukkan alamat email yang valid');
      return;
    }

    if (isTeacher && !email.toLowerCase().endsWith('@structora.app')) {
      _showMsg(
        isEn
            ? 'Access denied! Teacher Portal requires an official institution email (e.g., name@structora.app)'
            : 'Akses ditolak! Portal Guru memerlukan email institusi resmi (cth: nama@structora.app)',
      );
      return;
    }

    if (pass.length < 6) {
      _showMsg(isEn ? 'Password must be at least 6 characters' : 'Kata sandi minimal 6 karakter');
      return;
    }

    setState(() => _isLoading = true);

    final String emailClean = email.toLowerCase();
    try {
      final prefs = await SharedPreferences.getInstance();

      if (kIsWeb) {
        final String? registeredRole = await FirebaseService.getUserRoleByUidOrEmail('', email);
        if (registeredRole != null) {
          final bool accountIsTeacher = registeredRole == 'teacher' || registeredRole == 'guru';
          final bool accountIsStudent = registeredRole == 'student' || registeredRole == 'siswa';

          if (!isTeacher && accountIsTeacher) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _showMsg(
              isEn
                  ? 'This account is registered as a Teacher. Please log in using Teacher mode.'
                  : 'Akun ini terdaftar sebagai Guru. Silakan login melalui mode Guru.',
            );
            return;
          }

          if (isTeacher && accountIsStudent) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _showMsg(
              isEn
                  ? 'This account is registered as a Student. Please log in using Student mode.'
                  : 'Akun ini terdaftar sebagai Siswa. Silakan login melalui mode Siswa.',
            );
            return;
          }
        }

        String finalName = name;
        if (finalName.isEmpty) {
          String fallback = email.split('@').first;
          if (fallback.isNotEmpty) {
            fallback = fallback[0].toUpperCase() + fallback.substring(1);
          }
          finalName =
              fallback.isEmpty ? (isTeacher ? (isEn ? 'Teacher' : 'Guru') : (isEn ? 'Student' : 'Siswa')) : fallback;
        }

        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userRole', isTeacher ? 'teacher' : 'student');
        await prefs.setString('userEmail', email);
        await prefs.setString('userName', finalName);
        await prefs.setString('lastEmail', email);
        await prefs.setBool('isTeacher', isTeacher);
        await prefs.setString('saved_name_$emailClean', finalName);
        await prefs.setInt(
          'lastActiveTimestamp',
          DateTime.now().millisecondsSinceEpoch,
        );

        if (!isTeacher) {
          await FirebaseService.syncUserProgressOnLogin(email);
          await TeacherDataHelper.recordStudentProgress(
            name: finalName,
            email: email,
            preTestScore: '-',
            postTestScore: '-',
            status: isEn ? 'Not Tested' : 'Belum Ujian',
          );
        }

        if (!mounted) return;
        setState(() => _isLoading = false);
        widget.onLoginSuccess(finalName, email, isTeacher);
        return;
      }

      if (_isRegisterMode) {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );

        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(name);
          await user.sendEmailVerification();

          // Simpan Peran & Profil di Cloud Firestore
          await FirebaseService.saveUserRole(
            uid: user.uid,
            email: email,
            name: name,
            role: isTeacher ? 'teacher' : 'student',
          );
        }

        await FirebaseAuth.instance.signOut();

        await prefs.setString('userName', name);
        await prefs.setString('saved_name_$emailClean', name);
        await prefs.setString('lastEmail', email);
        await prefs.setBool('isLoggedIn', false);
        await prefs.setBool('isTeacher', isTeacher);

        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isRegisterMode = false;
          _passCtrl.clear();
        });

        _showMsg(isEn
            ? 'Activation link sent to $email! Check inbox/spam.'
            : 'Tautan aktivasi dikirim ke $email! Cek inbox/spam Gmail.');
        return;
      }

      await FirebaseAuth.instance.signOut();

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = credential.user;
      if (user == null) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showMsg(isEn ? 'Login failed. Please try again.' : 'Login gagal. Silakan coba kembali.');
        return;
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showMsg(isEn
            ? 'Account not activated! Please check your email inbox/spam.'
            : 'Akun belum diaktivasi! Silakan cek inbox/spam Gmail Anda.');
        return;
      }

      // VALIDASI KESESUAIAN ROLE PERAN TERDAFTAR SEBELUM MENYIMPAN SESI LOGIN
      final String? registeredRole = await FirebaseService.getUserRoleByUidOrEmail(
        refreshedUser.uid,
        email,
      );

      if (registeredRole != null) {
        final bool accountIsTeacher = registeredRole == 'teacher' || registeredRole == 'guru';
        final bool accountIsStudent = registeredRole == 'student' || registeredRole == 'siswa';

        if (!isTeacher && accountIsTeacher) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showMsg(
            isEn
                ? 'This account is registered as a Teacher. Please log in using Teacher mode.'
                : 'Akun ini terdaftar sebagai Guru. Silakan login melalui mode Guru.',
          );
          return;
        }

        if (isTeacher && accountIsStudent) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showMsg(
            isEn
                ? 'This account is registered as a Student. Please log in using Student mode.'
                : 'Akun ini terdaftar sebagai Siswa. Silakan login melalui mode Siswa.',
          );
          return;
        }
      }

      String detectedName = refreshedUser.displayName ?? '';
      if (detectedName.isEmpty) {
        String fallback = email.split('@').first;
        if (fallback.isNotEmpty) {
          fallback = fallback[0].toUpperCase() + fallback.substring(1);
        }
        detectedName =
            fallback.isEmpty ? (isTeacher ? (isEn ? 'Teacher' : 'Guru') : (isEn ? 'Student' : 'Siswa')) : fallback;
      }

      // Simpan/Sinkronkan Peran ke Cloud Firestore di latar belakang (non-blocking)
      FirebaseService.saveUserRole(
        uid: refreshedUser.uid,
        email: email,
        name: detectedName,
        role: isTeacher ? 'teacher' : 'student',
      );

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', isTeacher ? 'teacher' : 'student');
      await prefs.setString('userEmail', email);
      await prefs.setString('userName', detectedName);
      await prefs.setString('saved_name_$emailClean', detectedName);
      await prefs.setString('lastEmail', email);
      await prefs.setBool('isTeacher', isTeacher);
      await prefs.setInt(
        'lastActiveTimestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      if (!isTeacher) {
        await FirebaseService.syncUserProgressOnLogin(email);
        await TeacherDataHelper.recordStudentProgress(
          name: detectedName,
          email: email,
          preTestScore: '-',
          postTestScore: '-',
          status: isEn ? 'Not Tested' : 'Belum Ujian',
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onLoginSuccess(detectedName, email, isTeacher);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-not-found') {
        // Fallback: Cek apakah password cocok dengan kata sandi kustom dari fitur Lupa Password di Firestore / local cache
        final bool isCustomMatch = await FirebaseService.verifyCustomUserPassword(
          email: email,
          inputPassword: pass,
        );

        if (isCustomMatch) {
          final String? registeredRole =
              await FirebaseService.getUserRoleByUidOrEmail('', email);

          if (registeredRole != null) {
            final bool accountIsTeacher =
                registeredRole == 'teacher' || registeredRole == 'guru';
            final bool accountIsStudent =
                registeredRole == 'student' || registeredRole == 'siswa';

            if (!isTeacher && accountIsTeacher) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _showMsg(
                isEn
                    ? 'This account is registered as a Teacher. Please log in using Teacher mode.'
                    : 'Akun ini terdaftar sebagai Guru. Silakan login melalui mode Guru.',
              );
              return;
            }

            if (isTeacher && accountIsStudent) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _showMsg(
                isEn
                    ? 'This account is registered as a Student. Please log in using Student mode.'
                    : 'Akun ini terdaftar sebagai Siswa. Silakan login melalui mode Siswa.',
              );
              return;
            }
          }

          final prefs = await SharedPreferences.getInstance();
          String detectedName = prefs.getString('saved_name_$emailClean') ??
              prefs.getString('userName') ??
              '';
          if (detectedName.isEmpty) {
            String fallback = email.split('@').first;
            if (fallback.isNotEmpty) {
              fallback = fallback[0].toUpperCase() + fallback.substring(1);
            }
            detectedName = fallback.isEmpty
                ? (isTeacher ? (isEn ? 'Teacher' : 'Guru') : (isEn ? 'Student' : 'Siswa'))
                : fallback;
          }

          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userRole', isTeacher ? 'teacher' : 'student');
          await prefs.setString('userEmail', email);
          await prefs.setString('userName', detectedName);
          await prefs.setString('saved_name_$emailClean', detectedName);
          await prefs.setString('lastEmail', email);
          await prefs.setBool('isTeacher', isTeacher);
          await prefs.setInt(
            'lastActiveTimestamp',
            DateTime.now().millisecondsSinceEpoch,
          );

          if (!isTeacher) {
            await FirebaseService.syncUserProgressOnLogin(email);
            await TeacherDataHelper.recordStudentProgress(
              name: detectedName,
              email: email,
              preTestScore: '-',
              postTestScore: '-',
              status: isEn ? 'Not Tested' : 'Belum Ujian',
            );
          }

          if (!mounted) return;
          setState(() => _isLoading = false);
          widget.onLoginSuccess(detectedName, email, isTeacher);
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMsg = isEn ? 'Authentication error occurred.' : 'Terjadi kesalahan autentikasi.';
      if (e.code == 'email-already-in-use') {
        errorMsg = isEn ? 'This email is already registered. Please log in.' : 'Email ini sudah terdaftar. Silakan login.';
      } else if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMsg = isEn ? 'Invalid email or password / Account not registered.' : 'Email atau kata sandi salah / akun belum terdaftar.';
      } else if (e.code == 'weak-password') {
        errorMsg = isEn ? 'Password is too weak.' : 'Kata sandi terlalu lemah.';
      } else if (e.code == 'invalid-email') {
        errorMsg = isEn ? 'Invalid email format.' : 'Format email tidak valid.';
      } else if (e.code == 'network-request-failed') {
        errorMsg = isEn ? 'Network connection error. Check your internet.' : 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      }

      _showMsg(errorMsg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMsg(isEn ? 'An error occurred: $e' : 'Terjadi kesalahan: $e');
    }
  }

  void _showForgotPasswordDialog() {
    final bool isEn = LanguageController.instance.isEnglish;

    final String initialEmail = _emailCtrl.text.trim();
    final resetEmailCtrl = TextEditingController(text: initialEmail);
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmittingReset = false;

    final cardBg = widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final accentColor = widget.isDarkMode ? const Color(0xFF00F0FF) : const Color(0xFF0284C7);
    final boxInnerBg = widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFFF1F5F9);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: accentColor.withValues(alpha: 0.35), width: 1.2),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  child: Icon(Icons.lock_reset_rounded, color: accentColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEn ? 'Reset Password' : 'Reset Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textColor, size: 22),
                  onPressed: isSubmittingReset ? null : () => Navigator.pop(dialogCtx),
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
                        ? 'Enter your registered email and new password. Applicable for both Teacher and Student accounts.'
                        : 'Masukkan email terdaftar dan password baru. Berlaku untuk akun Guru maupun Siswa.',
                    style: TextStyle(fontSize: 11.5, color: subTextColor, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // 1. Email Terdaftar
                  TextField(
                    controller: resetEmailCtrl,
                    enabled: !isSubmittingReset,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: isEn ? 'Registered Email' : 'Email Terdaftar',
                      labelStyle: TextStyle(color: subTextColor, fontSize: 12),
                      prefixIcon: Icon(Icons.email_outlined, color: accentColor, size: 20),
                      filled: true,
                      fillColor: boxInnerBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Password Baru
                  TextField(
                    controller: newPassCtrl,
                    enabled: !isSubmittingReset,
                    obscureText: obscureNew,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: isEn ? 'New Password (min. 6 chars)' : 'Password Baru (min. 6 karakter)',
                      labelStyle: TextStyle(color: subTextColor, fontSize: 12),
                      prefixIcon: Icon(Icons.lock_outline, color: accentColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                          color: subTextColor,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                      filled: true,
                      fillColor: boxInnerBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Konfirmasi Password Baru
                  TextField(
                    controller: confirmPassCtrl,
                    enabled: !isSubmittingReset,
                    obscureText: obscureConfirm,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: isEn ? 'Confirm New Password' : 'Konfirmasi Password Baru',
                      labelStyle: TextStyle(color: subTextColor, fontSize: 12),
                      prefixIcon: Icon(Icons.lock_reset_outlined, color: accentColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm ? Icons.visibility_off : Icons.visibility,
                          color: subTextColor,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                      filled: true,
                      fillColor: boxInnerBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tombol opsional: Send Reset Email Link
                  Center(
                    child: TextButton.icon(
                      onPressed: isSubmittingReset
                          ? null
                          : () async {
                              final emailToReset = resetEmailCtrl.text.trim();
                              if (emailToReset.isEmpty ||
                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(emailToReset)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEn
                                        ? 'Please enter a valid email address first.'
                                        : 'Harap masukkan alamat email yang valid terlebih dahulu.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              try {
                                await FirebaseAuth.instance.sendPasswordResetEmail(email: emailToReset);
                                if (!mounted) return;
                                _showMsg(
                                  isEn
                                      ? 'Reset link sent to $emailToReset! Check inbox/spam.'
                                      : 'Tautan reset dikirim ke $emailToReset! Cek inbox/spam Gmail.',
                                );
                              } catch (e) {
                                if (!mounted) return;
                                _showMsg(
                                  isEn
                                      ? 'Error sending email link: $e'
                                      : 'Gagal mengirim tautan email: $e',
                                );
                              }
                            },
                      icon: Icon(Icons.mark_email_read_outlined, size: 16, color: accentColor),
                      label: Text(
                        isEn ? 'Kirim Link Reset ke Email' : 'Kirim Link Reset ke Email',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: accentColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmittingReset ? null : () => Navigator.pop(dialogCtx),
                child: Text(isEn ? 'Cancel' : 'Batal', style: TextStyle(color: subTextColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmittingReset
                    ? null
                    : () async {
                        final emailVal = resetEmailCtrl.text.trim();
                        final newPass = newPassCtrl.text.trim();
                        final confirmPass = confirmPassCtrl.text.trim();

                        if (emailVal.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEn ? 'Please fill in all fields.' : 'Harap isi semua kolom.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(emailVal)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEn ? 'Invalid email format.' : 'Format email tidak valid.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        if (newPass.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEn
                                  ? 'Password must be at least 6 characters.'
                                  : 'Password minimal 6 karakter.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEn
                                  ? 'Password confirmation does not match.'
                                  : 'Konfirmasi password tidak cocok.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSubmittingReset = true);

                        // Save password into Firestore users collection & local cache
                        await FirebaseService.updateUserPassword(
                          email: emailVal,
                          newPassword: newPass,
                        );

                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                        if (!mounted) return;
                        // Pre-fill login controllers for user convenience
                        setState(() {
                          _emailCtrl.text = emailVal;
                          _passCtrl.text = newPass;
                        });

                        _showMsg(
                          isEn
                              ? 'Password updated successfully! Please login with your new password.'
                              : 'Password berhasil diperbarui! Silakan login dengan password baru.',
                        );
                      },
                child: isSubmittingReset
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        isEn ? 'Save New Password' : 'Simpan Password Baru',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageController.instance.isEnglish;
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color accentColor = widget.isDarkMode
        ? const Color(0xFF00F0FF)
        : const Color(0xFF0284C7);
    final bool isTeacher = _selectedRole == 'teacher';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: InkWell(
              onTap: () {
                LanguageController.instance.toggleLanguage();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.translate_rounded, size: 16, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      isEn ? 'EN ⇄ ID' : 'ID ⇄ EN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).viewPadding.bottom +
                24,
          ),
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Structora',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (_selectedRole == null) ...[
                  const SizedBox(height: 10),
                  Text(
                    isEn ? 'Please select entry mode' : 'Silakan pilih akses masuk aplikasi',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _prepareRoleAccess('student'),
                      icon: const Icon(Icons.person_outline, color: Colors.black),
                      label: Text(
                        isEn ? 'ENTER AS STUDENT' : 'MASUK SEBAGAI SISWA',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _prepareRoleAccess('teacher'),
                      icon: Icon(Icons.school_outlined, color: accentColor),
                      label: Text(
                        isEn ? 'ENTER AS TEACHER' : 'MASUK SEBAGAI GURU',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: accentColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: accentColor, size: 20),
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _selectedRole = null;
                                  _isRegisterMode = false;
                                  _nameCtrl.clear();
                                  _emailCtrl.clear();
                                  _passCtrl.clear();
                                });
                              },
                        tooltip: isEn ? 'Back to role selection' : 'Kembali pilih peran',
                      ),
                      Text(
                        isTeacher
                            ? (isEn ? '🔒 Teacher Portal' : '🔒 Portal Khusus Guru')
                            : (isEn ? '👤 Student Portal' : '👤 Portal Siswa'),
                        style: TextStyle(
                          fontSize: 13,
                          color: isTeacher ? Colors.orangeAccent : accentColor,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_isRegisterMode) ...[
                    _buildInputField(
                      controller: _nameCtrl,
                      label: isTeacher
                          ? (isEn ? 'Full Name & Degree (e.g. Budi, M.Ed)' : 'Nama Lengkap & Gelar (Cth: Budi, S.Pd)')
                          : (isEn ? 'Student Full Name' : 'Nama Lengkap Siswa'),
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildInputField(
                    controller: _emailCtrl,
                    label: isTeacher
                        ? (isEn ? 'Institutional Email (e.g. name@structora.app)' : 'Email Institusi (Cth: nama@structora.app)')
                        : (isEn ? 'Email Address' : 'Alamat Email'),
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _passCtrl,
                    label: isEn ? 'Password (min. 6 characters)' : 'Password (min. 6 karakter)',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  if (!_isRegisterMode) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isEn ? 'Forgot Password?' : 'Lupa Password?',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isTeacher ? Colors.orangeAccent : accentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isTeacher ? Colors.orangeAccent : accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              _isRegisterMode
                                  ? (isEn ? 'REGISTER NOW' : 'DAFTAR SEKARANG')
                                  : (isEn ? 'LOG IN' : 'LOGIN'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isRegisterMode = !_isRegisterMode;
                              _passCtrl.clear();
                            });
                          },
                    child: Text(
                      _isRegisterMode
                          ? (isEn ? 'Already have an account? Log in here' : 'Sudah punya akun? Masuk di sini')
                          : (isEn ? 'Don\'t have an account? Register now' : 'Belum punya akun? Daftar sekarang'),
                      style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.white60
                            : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    final Color accentColor = widget.isDarkMode
        ? const Color(0xFF00F0FF)
        : const Color(0xFF0284C7);
    final Color subTextColor =
        widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      style: TextStyle(
        fontSize: 13,
        color: widget.isDarkMode ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: accentColor, size: 18),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: subTextColor,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              )
            : null,
        labelText: label,
        labelStyle: TextStyle(
          color: widget.isDarkMode ? Colors.white54 : Colors.black45,
          fontSize: 12,
        ),
        filled: true,
        fillColor:
            widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.isDarkMode
                ? const Color(0xFF1E293B)
                : const Color(0xFFCBD5E1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accentColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}