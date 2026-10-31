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

      if (role == 'teacher') {
        _emailCtrl.text = 'teacher.demo@structora.app';
      }
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

  Future<void> _handleDemoLogin(bool isTeacher) async {
    if (_isLoading) return;
    final bool isEn = LanguageController.instance.isEnglish;

    setState(() => _isLoading = true);

    try {
      if (!kIsWeb) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }

      final String demoName = isTeacher
          ? (isEn ? 'Demo Teacher' : 'Ibu Guru Demo')
          : (isEn ? 'Demo Student' : 'Siswa Demo');
      final String demoEmail =
          isTeacher ? 'teacher.demo@structora.app' : 'demo@structora.app';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', demoName);
      await prefs.setString('userEmail', demoEmail);
      await prefs.setString('lastEmail', demoEmail);
      await prefs.setBool('isTeacher', isTeacher);
      await prefs.setString('userRole', isTeacher ? 'teacher' : 'student');
      await prefs.setInt(
        'lastActiveTimestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      final String demoUid = 'demo_${isTeacher ? "teacher" : "student"}';

      // Sinkronkan peran ke Firestore di latar belakang (non-blocking)
      FirebaseService.saveUserRole(
        uid: demoUid,
        email: demoEmail,
        name: demoName,
        role: isTeacher ? 'teacher' : 'student',
      );

      if (!isTeacher) {
        TeacherDataHelper.recordStudentProgress(
          name: demoName,
          email: demoEmail,
          preTestScore: '-',
          postTestScore: '-',
          status: isEn ? 'Not Tested' : 'Belum Ujian',
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onLoginSuccess(demoName, demoEmail, isTeacher);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMsg(isEn ? 'Demo login failed: $e' : 'Login demo gagal: $e');
    }
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

    if (isTeacher &&
        email != 'teacher.demo@structora.app' &&
        !email.toLowerCase().endsWith('@structora.app')) {
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
        await prefs.setString('userName', finalName);
        await prefs.setString('userEmail', email);
        await prefs.setString('lastEmail', email);
        await prefs.setBool('isTeacher', isTeacher);
        await prefs.setString('saved_name_$emailClean', finalName);
        await prefs.setInt(
          'lastActiveTimestamp',
          DateTime.now().millisecondsSinceEpoch,
        );

        if (!isTeacher) {
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
      await prefs.setString('userName', detectedName);
      await prefs.setString('saved_name_$emailClean', detectedName);
      await prefs.setString('userEmail', email);
      await prefs.setString('lastEmail', email);
      await prefs.setBool('isTeacher', isTeacher);
      await prefs.setString('userRole', isTeacher ? 'teacher' : 'student');
      await prefs.setInt(
        'lastActiveTimestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      if (!isTeacher) {
        TeacherDataHelper.recordStudentProgress(
          name: detectedName,
          email: email,
          preTestScore: '-',
          postTestScore: '-',
          status: isEn ? 'Not Tested' : 'Belum Ujian',
        );
      }
      await prefs.setString('lastEmail', email);
      await prefs.setBool('isTeacher', isTeacher);
      await prefs.setInt(
        'lastActiveTimestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      if (!isTeacher) {
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
          padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 24),
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
                  if (!_isRegisterMode) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _handleDemoLogin(isTeacher),
                        icon: Icon(
                          isTeacher ? Icons.school_rounded : Icons.flash_on_rounded,
                          size: 18,
                          color: isTeacher ? Colors.orangeAccent : accentColor,
                        ),
                        label: Text(
                          isTeacher
                              ? (isEn ? 'LOG IN AS DEMO TEACHER' : 'MASUK SEBAGAI GURU DEMO')
                              : (isEn ? 'LOG IN AS DEMO STUDENT' : 'MASUK SEBAGAI SISWA DEMO'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isTeacher ? Colors.orangeAccent : accentColor,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isTeacher ? Colors.orangeAccent : accentColor,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
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