import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/app_translations.dart';
import '../utils/youtube_utils.dart';

/// In-app YouTube player built on webview_flutter.
///
/// The IFrame player is loaded with `loadHtmlString(html, baseUrl: ...)` so the
/// WebView sends a valid Origin/Referer (no more Error 150/152/153 caused by an
/// empty origin). The video stays visible and playable at all times; the
/// "Open in YouTube" button is only a small secondary action under the player.
/// Watch progress is reported through [onPlayTriggered] (when playback starts
/// or when the external button is used) so the learning flow never gets stuck.
class YouTubeVideoPlayerWidget extends StatefulWidget {
  final String videoId;
  final VoidCallback? onPlayTriggered;

  const YouTubeVideoPlayerWidget({
    super.key,
    required this.videoId,
    this.onPlayTriggered,
  });

  @override
  State<YouTubeVideoPlayerWidget> createState() =>
      _YouTubeVideoPlayerWidgetState();
}

class _YouTubeVideoPlayerWidgetState extends State<YouTubeVideoPlayerWidget> {
  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  static const String _hostNoCookie = 'https://www.youtube-nocookie.com';
  static const String _hostYoutube = 'https://www.youtube.com';

  WebViewController? _controller;
  String _currentId = '';
  String _host = _hostNoCookie;
  bool _retriedWithYoutubeHost = false;
  bool _pageLoaded = false;
  bool _progressRecorded = false;
  String _embedErrorCode = '';

  @override
  void initState() {
    super.initState();
    _setup(widget.videoId);
  }

  @override
  void didUpdateWidget(covariant YouTubeVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _setup(widget.videoId);
    }
  }

  void _setup(String rawId) {
    final String id = extractYouTubeVideoId(rawId);
    _currentId = id;
    _host = _hostNoCookie;
    _retriedWithYoutubeHost = false;
    _pageLoaded = false;
    _progressRecorded = false;
    _embedErrorCode = '';
    if (id.isEmpty) {
      _controller = null;
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(_userAgent)
      ..addJavaScriptChannel(
        'YtBridge',
        onMessageReceived: (msg) => _onBridgeMessage(msg.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted && !_pageLoaded) setState(() => _pageLoaded = true);
          },
          onNavigationRequest: (request) {
            // Allow the initial HTML + every sub-frame (the YouTube iframe).
            // Block the top frame from navigating away after first load.
            if (!request.isMainFrame || !_pageLoaded) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            // Android fires this for sub-resources (ads, analytics, favicon)
            // even when the video plays fine. Only a main-frame failure counts.
            if (error.isForMainFrame != true) return;
            debugPrint('YouTube WebView main-frame error: '
                '${error.errorCode} ${error.description}');
            if (mounted) setState(() => _embedErrorCode = 'network');
          },
        ),
      );
    _controller = controller;
    _load();
  }

  void _load() {
    final controller = _controller;
    if (controller == null || _currentId.isEmpty) return;
    controller.loadHtmlString(
      _buildHtml(_currentId, _host),
      baseUrl: _host,
    );
  }

  String _buildHtml(String id, String host) {
    final String src = '$host/embed/$id'
        '?playsinline=1&rel=0&modestbranding=1&enablejsapi=1&origin=$host';
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  html, body { margin:0; padding:0; background:#000; height:100%; overflow:hidden; }
  iframe { position:absolute; top:0; left:0; width:100%; height:100%; border:0; }
</style>
</head>
<body>
<iframe id="player" src="$src"
  frameborder="0"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
  referrerpolicy="strict-origin-when-cross-origin"
  allowfullscreen></iframe>
<script>
  var f = document.getElementById('player');
  function listen() {
    try {
      f.contentWindow.postMessage(
        JSON.stringify({event: 'listening', id: 1, channel: 'widget'}), '*');
    } catch (e) {}
  }
  f.addEventListener('load', function () {
    listen(); setTimeout(listen, 500); setTimeout(listen, 1500);
  });
  window.addEventListener('message', function (e) {
    try {
      var d = typeof e.data === 'string' ? JSON.parse(e.data) : e.data;
      if (!d) return;
      if (d.event === 'onStateChange') {
        YtBridge.postMessage('state:' + d.info);
      } else if (d.event === 'infoDelivery' && d.info &&
                 d.info.playerState !== undefined) {
        YtBridge.postMessage('state:' + d.info.playerState);
      } else if (d.event === 'onError') {
        YtBridge.postMessage('error:' + d.info);
      }
    } catch (x) {}
  });
</script>
</body>
</html>
''';
  }

  void _onBridgeMessage(String message) {
    if (!mounted) return;
    if (message.startsWith('state:')) {
      final int? state = int.tryParse(message.substring(6));
      // 1 = playing, 0 = ended.
      if (state == 1 || state == 0) _recordProgressOnce();
      return;
    }
    if (message.startsWith('error:')) {
      final String code = message.substring(6);
      // 101/150 = embed disabled by owner, 152/153 = origin/config problem.
      if (!_retriedWithYoutubeHost &&
          (code == '152' || code == '153' || code == '150' || code == '101')) {
        // One automatic retry with the main youtube.com origin.
        _retriedWithYoutubeHost = true;
        _host = _hostYoutube;
        _load();
        return;
      }
      setState(() => _embedErrorCode = code);
    }
  }

  void _recordProgressOnce() {
    if (_progressRecorded) return;
    _progressRecorded = true;
    widget.onPlayTriggered?.call();
  }

  Future<void> _openInYouTube() async {
    final bool isEn = LanguageController.instance.isEnglish;
    // Keep the learning flow unblocked: mark the video as watched.
    _recordProgressOnce();

    final Uri webUri = Uri.parse(youTubeWatchUrl(_currentId));
    try {
      final bool ok =
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (e) {
      debugPrint('Error launching YouTube: $e');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEn
            ? 'Cannot open video link'
            : 'Tidak dapat membuka tautan video'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageController.instance.isEnglish;

    if (_currentId.isEmpty || _controller == null) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WebViewWidget(
                    key: ValueKey('yt_$_currentId'),
                    controller: _controller!,
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                  if (!_pageLoaded)
                    const IgnorePointer(
                      child: Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFFFF0000),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Secondary, non-blocking action under the player.
        Row(
          children: [
            if (_embedErrorCode.isNotEmpty)
              Expanded(
                child: Text(
                  isEn
                      ? 'Video blocked for embedding (code $_embedErrorCode).'
                      : 'Video dibatasi untuk embed (kode $_embedErrorCode).',
                  style:
                  const TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
              )
            else
              const Spacer(),
            TextButton.icon(
              onPressed: _openInYouTube,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: Colors.white70,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: Text(
                isEn ? 'Open in YouTube' : 'Buka di YouTube',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
