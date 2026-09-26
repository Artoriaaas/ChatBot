import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DoiService {
  static const String doiBaseUrl = 'https://doi.org/';
  static const String handleApiBaseUrl = 'https://doi.org/api/handles/';

  /// Cleans the DOI string by trimming whitespace and stripping common prefixes
  /// like `https://doi.org/`, `http://dx.doi.org/`, or `doi:`.
  static String cleanDoi(String rawDoi) {
    var cleaned = rawDoi.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^https?://(dx\.)?doi\.org/', caseSensitive: false), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^doi:\s*', caseSensitive: false), '');

    // Normalize arXiv DOIs (10.48550/arXiv...)
    if (cleaned.toLowerCase().contains('10.48550/arxiv.')) {
      // Strip classification brackets like [math.AC] or (cs.AI)
      cleaned = cleaned.replaceAll(RegExp(r'\[.*?\]'), '').replaceAll(RegExp(r'\(.*?\)'), '').trim();
      // Strip version suffix like v1, v2
      cleaned = cleaned.replaceFirst(RegExp(r'v\d+$', caseSensitive: false), '').trim();
    }

    return cleaned.trim();
  }

  /// Formats the raw DOI into a clean, concise display string for UI display.
  /// For example:
  /// - "10.48550/arXiv.2609.29516v1[math.AC]" -> "arXiv:2609.29516"
  /// - "10.48550/arXiv.astro-ph/9508025" -> "arXiv:astro-ph/9508025"
  /// - "https://doi.org/10.1038/nature12373" -> "10.1038/nature12373"
  static String formatDisplay(String rawDoi) {
    final cleaned = cleanDoi(rawDoi);
    if (cleaned.isEmpty) return '';

    final arxivMatch = RegExp(r'^10\.48550/arXiv\.(.+)$', caseSensitive: false).firstMatch(cleaned);
    if (arxivMatch != null) {
      final id = arxivMatch.group(1);
      return 'arXiv:$id';
    }

    return cleaned;
  }

  /// Checks if a string has a valid DOI structure (usually starting with 10.xxxx/...).
  static bool isValidDoi(String rawDoi) {
    final cleaned = cleanDoi(rawDoi);
    if (cleaned.isEmpty) return false;
    // Standard DOI begins with "10." followed by a registrant code, a slash, and a suffix.
    final doiRegex = RegExp(r'^10\.\d{4,9}/.+$');
    return doiRegex.hasMatch(cleaned);
  }

  /// Constructs the standard direct resolution URL for a DOI.
  static String buildDoiUrl(String rawDoi) {
    final cleaned = cleanDoi(rawDoi);
    return '$doiBaseUrl$cleaned';
  }

  /// Resolves the destination URL using DOI.org Handle System REST API:
  /// `https://doi.org/api/handles/{DOI}`
  /// Returns the publisher's landing page URL if resolved, or null otherwise.
  static Future<String?> resolveTargetUrl(String rawDoi) async {
    final cleaned = cleanDoi(rawDoi);
    if (cleaned.isEmpty) return null;

    try {
      final uri = Uri.parse('$handleApiBaseUrl$cleaned');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['values'] is List) {
          final values = data['values'] as List;
          for (final item in values) {
            if (item is Map<String, dynamic> && item['type'] == 'URL') {
              final valData = item['data'];
              if (valData is Map<String, dynamic> && valData['value'] is String) {
                return valData['value'] as String;
              }
            }
          }
        }
      }
    } catch (_) {
      // In case of network errors or timeout, fallback gracefully
    }
    return null;
  }

  /// Opens the DOI link in the user's default external web browser.
  static Future<bool> openDoi(String rawDoi) async {
    final cleaned = cleanDoi(rawDoi);
    if (cleaned.isEmpty) return false;

    final urlString = buildDoiUrl(cleaned);
    final uri = Uri.tryParse(urlString);
    if (uri == null) return false;

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
