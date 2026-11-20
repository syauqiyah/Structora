/// Robust YouTube videoId extractor (always returns exactly 11 chars or '').
///
/// Supports: watch?v=, m.youtube.com, music.youtube.com, youtu.be/, shorts/,
/// embed/, live/, v/, youtube-nocookie.com/embed/, extra params (&t=, ?si=,
/// &list=, &feature=) and a bare 11-character ID.
final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

String extractYouTubeVideoId(String input) {
  final String raw = input.trim();
  if (raw.isEmpty) return '';
  if (_idPattern.hasMatch(raw)) return raw;

  Uri? uri = Uri.tryParse(raw);
  if (uri != null && !uri.hasScheme) {
    uri = Uri.tryParse('https://$raw');
  }

  if (uri != null && uri.host.isNotEmpty) {
    final String host = uri.host.toLowerCase();
    final bool isYoutu = host == 'youtu.be' || host.endsWith('.youtu.be');
    final bool isYoutube =
        host.contains('youtube.com') || host.contains('youtube-nocookie.com');

    if (isYoutu && uri.pathSegments.isNotEmpty) {
      final String id = uri.pathSegments.first;
      if (_idPattern.hasMatch(id)) return id;
    }

    if (isYoutube) {
      final String? v = uri.queryParameters['v'];
      if (v != null && _idPattern.hasMatch(v)) return v;

      final List<String> seg = uri.pathSegments;
      const markers = {'shorts', 'embed', 'live', 'v', 'e'};
      for (int i = 0; i < seg.length - 1; i++) {
        if (markers.contains(seg[i].toLowerCase()) &&
            _idPattern.hasMatch(seg[i + 1])) {
          return seg[i + 1];
        }
      }
    }
  }

  // Last resort: pattern search inside the raw string.
  final Match? m = RegExp(
    r'(?:v=|youtu\.be/|shorts/|embed/|live/|/v/)([A-Za-z0-9_-]{11})',
  ).firstMatch(raw);
  return m?.group(1) ?? '';
}

/// Canonical watch URL used by the "Open in YouTube" fallback.
String youTubeWatchUrl(String videoId) =>
    'https://www.youtube.com/watch?v=$videoId';
