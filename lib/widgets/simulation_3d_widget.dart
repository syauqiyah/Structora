import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/app_translations.dart';

class Simulation3DWidget extends StatefulWidget {
  const Simulation3DWidget({super.key});

  @override
  State<Simulation3DWidget> createState() => _Simulation3DWidgetState();
}

class _Simulation3DWidgetState extends State<Simulation3DWidget> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initWebView();
    } else {
      _isLoading = false;
    }
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF090D16))
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

  Future<void> _switchTabFromFlutter(String tabName) async {
    if (!kIsWeb && _controller != null) {
      try {
        await _controller!.runJavaScript("switchTab('$tabName');");
      } catch (e) {
        debugPrint("Gagal memanggil JS switchTab: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LanguageController.instance.isEnglish;
    // Panggil sinkronisasi bahasa jika controller sudah aktif
    _syncLanguage();

    return Column(
      children: [
        // Sub-header Bar Simulasi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.view_in_ar_rounded, color: Color(0xFF6366F1), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isEn ? 'Interactive 3D Visualizer' : 'Visualisasi 3D Interaktif',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
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
        ),

        // Area Layar Canvas 3D WebView
        Expanded(
          child: Container(
            color: const Color(0xFF090D16),
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
                            style: const TextStyle(
                              color: Colors.white,
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
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isLoading && !kIsWeb)
                  Container(
                    color: const Color(0xFF090D16),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF6366F1)),
                        const SizedBox(height: 14),
                        Text(
                          isEn ? 'Loading 3D Simulation...' : 'Memuat Simulasi 3D...',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton('Stack', 'stack', Icons.layers_rounded),
              _buildNavButton('Queue', 'queue', Icons.people_alt_rounded),
              _buildNavButton('Linked List', 'linkedlist', Icons.link_rounded),
              _buildNavButton(isEn ? 'Sort & Search' : 'Sort & Search', 'sortsearch', Icons.sort_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(String label, String tabKey, IconData icon) {
    return InkWell(
      onTap: () => _switchTabFromFlutter(tabKey),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF818CF8)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}