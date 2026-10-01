import 'package:http/http.dart' as http;

class PinterestImageUrl {
  static Future<String> resolve(String url) async {
    final trimmedUrl = url.trim();
    final lowerUrl = trimmedUrl.toLowerCase();

    if (lowerUrl.contains('i.pinimg.com') ||
        RegExp(
          r'\.(jpg|jpeg|png|webp)(\?.*)?$',
          caseSensitive: false,
        ).hasMatch(lowerUrl)) {
      return trimmedUrl;
    }

    if (lowerUrl.contains('pin.it') || lowerUrl.contains('pinterest.com')) {
      try {
        final response = await http.get(
          Uri.parse(trimmedUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
          },
        );

        if (response.statusCode == 200) {
          final html = response.body;
          final imagePatterns = [
            RegExp(
              r'<meta[^>]*property=["'
              ']og:image["'
              '][^>]*content=["'
              ']([^"'
              ']+)["'
              ']',
              caseSensitive: false,
            ),
            RegExp(
              r'<meta[^>]*content=["'
              ']([^"'
              ']+)["'
              '][^>]*property=["'
              ']og:image["'
              ']',
              caseSensitive: false,
            ),
          ];

          for (final pattern in imagePatterns) {
            final match = pattern.firstMatch(html);
            if (match != null) {
              return match
                  .group(1)!
                  .replaceAll(RegExp(r'/\d+x/'), '/originals/');
            }
          }
        }
      } catch (_) {}
    }

    return trimmedUrl;
  }
}
