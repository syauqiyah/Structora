import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'utils/app_translations.dart';

class ArSimulationScreen extends StatefulWidget {
  const ArSimulationScreen({super.key});

  @override
  State<ArSimulationScreen> createState() => _ArSimulationScreenState();
}

class _ArSimulationScreenState extends State<ArSimulationScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  WebViewController? _webViewController;
  bool _isCameraReady = false;
  bool _isScanning = false;
  String? _cameraError;
  String _activeTab = 'stack';
  String _detectedObject = '-';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _initArWebView();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showContextualOnboardingDialog();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _cameraError = 'Kamera fisik tidak ditemukan');
        }
        return;
      }

      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Gagal mengakses kamera AR: $e');
      }
    }
  }

  void _initArWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _syncLanguageAndTab();
          },
        ),
      )
      ..loadFlutterAsset('assets/simulasi_3d_ar.html');

    _webViewController = controller;
  }

  void _syncLanguageAndTab() {
    if (_webViewController != null) {
      final isEn = LanguageController.instance.isEnglish;
      final lang = isEn ? 'en' : 'id';
      _webViewController!.runJavaScript("if (window.setLanguage) window.setLanguage('$lang');");
      _webViewController!.runJavaScript("if (window.switchTab) window.switchTab('$_activeTab');");
    }
  }

  void _showContextualOnboardingDialog() {
    final bool isEn = LanguageController.instance.isEnglish;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00F0FF), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn ? 'AR & AI Contextual Learning' : 'Panduan AR & AI Kontekstual',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                    ? 'Scan real-world objects around you using AI camera to simulate 4 Data Structures:'
                    : 'Pindai objek nyata di sekitarmu menggunakan kamera AI untuk mensimulasikan 4 Struktur Data:',
                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 12),
              _buildConceptItem(
                icon: Icons.layers_rounded,
                title: '1. Stack (LIFO)',
                desc: isEn
                    ? 'Scan stacked books, pillows, or boxes.'
                    : 'Pindai tumpukan buku, piring, atau kotak.',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 8),
              _buildConceptItem(
                icon: Icons.people_alt_rounded,
                title: '2. Queue (FIFO)',
                desc: isEn
                    ? 'Scan lined-up bottles, shoes, or items.'
                    : 'Pindai barisan botol, sandal, atau barang.',
                color: const Color(0xFF00F0FF),
              ),
              const SizedBox(height: 8),
              _buildConceptItem(
                icon: Icons.search_rounded,
                title: '3. Searching',
                desc: isEn
                    ? 'Locate specific items sequentially or binary.'
                    : 'Cari objek spesifik secara linier/binary.',
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 8),
              _buildConceptItem(
                icon: Icons.sort_rounded,
                title: '4. Sorting',
                desc: isEn
                    ? 'Order items by size or heights.'
                    : 'Urutkan objek berdasarkan tinggi/ukuran.',
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 18),
            label: Text(
              isEn ? 'START AR SCANNING' : 'MULAIPINDAI AR',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptItem({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF060913),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerMlKitScan() async {
    if (_isScanning) return;
    final bool isEn = LanguageController.instance.isEnglish;

    setState(() => _isScanning = true);

    try {
      // 1. Ambil 1 frame gambar dari kamera native secara hemat resource
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.takePicture();
      }

      // Simulasi/Hasil deteksi ML Kit terhadap objek fisik sekitar
      final sampleDetections = [
        {'label': isEn ? 'Book Stack / Pillow' : 'Tumpukan Buku / Piring', 'tab': 'stack'},
        {'label': isEn ? 'Bottle Line / Shoes Queue' : 'Barisan Botol / Sandal', 'tab': 'queue'},
        {'label': isEn ? 'Scattered Desk Items' : 'Barang Terpisah di Meja', 'tab': 'linkedlist'},
        {'label': isEn ? 'Random Objects for Sorting' : 'Barang Acak Berbeda Ukuran', 'tab': 'sortsearch'},
      ];

      final detection = (sampleDetections..shuffle()).first;
      final label = detection['label']!;
      final tab = detection['tab']!;

      setState(() {
        _detectedObject = label;
        _activeTab = tab;
        _isScanning = false;
      });

      // 2. Kirim label deteksi ML Kit via JS Bridge ke Three.js WebView
      _webViewController?.runJavaScript(
        "if (window.setMlKitDetectedObject) window.setMlKitDetectedObject('$label', '$tab');",
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageController.instance.isEnglish;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Feed Kamera Belakang (Aspect Ratio Fill Layar Penuh)
          if (_isCameraReady && _cameraController != null)
            LayoutBuilder(
              builder: (context, constraints) {
                var camera = _cameraController!.value;
                var scale = constraints.maxHeight /
                    (constraints.maxWidth * camera.aspectRatio);

                if (scale < 1) scale = 1 / scale;

                return ClipRect(
                  child: Transform.scale(
                    scale: scale,
                    child: Center(
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                );
              },
            )
          else if (_cameraError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
            ),

          // 2. Kanvas 3D Three.js Transparan di Atas Kamera Belakang
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!),

          // 3. Status Bar Deteksi Objek ML Kit & AI
          Positioned(
            top: 95,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isScanning ? Icons.autofreq_rounded : Icons.center_focus_strong_rounded,
                      color: const Color(0xFF00F0FF),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isScanning
                          ? (isEn ? 'AI ML Kit Analyzing Object...' : 'AI ML Kit Memindai Objek...')
                          : (isEn
                              ? 'Object: $_detectedObject'
                              : 'Objek: $_detectedObject'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Header Navigasi & Judul Minimalis
          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      isEn ? 'Simulasi AR & AI' : 'Simulasi AR & AI',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  child: IconButton(
                    icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF00F0FF)),
                    onPressed: _showContextualOnboardingDialog,
                  ),
                ),
              ],
            ),
          ),

          // 5. Floating Action HUD Bar di Bawah Layar
          Positioned(
            bottom: 25,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _triggerMlKitScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 22),
                label: Text(
                  _isScanning
                      ? (isEn ? 'ANALYZING OBJECT...' : 'MEMINDAI OBJEK...')
                      : (isEn ? 'PINDAI OBJEK SEKITAR (AI AR)' : 'PINDAI OBJEK SEKITAR (AI AR)'),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}