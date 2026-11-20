import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/app_translations.dart';
import 'custom_camera_ar_screen.dart';

class Simulation3DWidget extends StatefulWidget {
  final bool isDarkMode;

  const Simulation3DWidget({
    super.key,
    this.isDarkMode = true,
  });

  @override
  State<Simulation3DWidget> createState() => _Simulation3DWidgetState();
}

class _Simulation3DWidgetState extends State<Simulation3DWidget> {
  WebViewController? _controller;
  bool _isLoading = true;
  String _currentTab = 'stack'; // Melacak tab yang sedang aktif

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initWebView();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(covariant Simulation3DWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _syncTheme();
    }
  }

  void _initWebView() {
    final bgColor = widget.isDarkMode ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(bgColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              _syncLanguage();
              _syncTheme();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/web/index.html');

    setState(() {
      _controller = controller;
    });
  }

  void _syncLanguage() {
    if (!kIsWeb && _controller != null) {
      final isEn = LanguageController.instance.isEnglish;
      final lang = isEn ? 'en' : 'id';
      _controller!.runJavaScript("if (window.setLanguage) { window.setLanguage('$lang'); }");
    }
  }

  void _syncTheme() {
    if (!kIsWeb && _controller != null) {
      final theme = widget.isDarkMode ? 'dark' : 'light';
      _controller!.runJavaScript("if (window.setTheme) { window.setTheme('$theme'); }");
    }
  }

  Future<void> _switchTabFromFlutter(String tabName) async {
    setState(() {
      _currentTab = tabName;
    });
    if (!kIsWeb && _controller != null) {
      try {
        await _controller!.runJavaScript("switchTab('$tabName');");
      } catch (e) {
        debugPrint("Gagal memanggil JS switchTab: $e");
      }
    }
  }

  void _openArMode(bool isEn) {
    final String title = isEn
        ? 'AR Data Structure Scanner'
        : 'AR Scanner (Deteksi Dunia Nyata)';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomCameraArScreen(
          title: title,
          initialTab: _currentTab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LanguageController.instance.isEnglish;
    _syncLanguage();
    _syncTheme();

    final cardBg = widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final canvasBg = widget.isDarkMode ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final borderColor = widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Column(
      children: [
        // Sub-header Bar Simulasi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.view_in_ar_rounded, color: Color(0xFF6366F1), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEn ? 'Interactive 3D Visualizer' : 'Visualisasi 3D Interaktif',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Akses Mode AR Kamera
                  InkWell(
                    onTap: () => _openArMode(isEn),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF00F0FF)),
                          SizedBox(width: 4),
                          Text(
                            'AR Scanner',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00F0FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF818CF8)),
                    tooltip: isEn ? 'Reload Simulation' : 'Reload Simulasi',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (!kIsWeb && _controller != null) {
                        setState(() => _isLoading = true);
                        _controller!.reload();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Area Layar Canvas 3D WebView
        Expanded(
          child: Container(
            color: canvasBg,
            child: Stack(
              children: [
                if (!kIsWeb && _controller != null)
                  WebViewWidget(controller: _controller!)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.view_in_ar_rounded, size: 48, color: Color(0xFF6366F1)),
                          const SizedBox(height: 12),
                          Text(
                            isEn ? 'Interactive 3D Simulation' : 'Simulasi Interaktif 3D',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isEn
                                ? 'Run on an Android device to interact with the 3D lab.'
                                : 'Jalankan pada perangkat fisik Android untuk berinteraksi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isLoading && !kIsWeb)
                  Container(
                    color: canvasBg,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF6366F1)),
                        const SizedBox(height: 14),
                        Text(
                          isEn ? 'Loading 3D Simulation...' : 'Memuat Simulasi 3D...',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Menu Tab Shortcut Simulasi
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton('Stack', 'stack', Icons.layers_rounded, textColor),
              _buildNavButton('Queue', 'queue', Icons.people_alt_rounded, textColor),
              _buildNavButton('Linked List', 'linkedlist', Icons.link_rounded, textColor),
              _buildNavButton(isEn ? 'Sort & Search' : 'Sort & Search', 'sortsearch', Icons.sort_rounded, textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(String label, String tabKey, IconData icon, Color textColor) {
    final bool isSelected = _currentTab == tabKey;
    return InkWell(
      onTap: () => _switchTabFromFlutter(tabKey),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF818CF8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00F0FF) : textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}