import 'package:flutter/foundation.dart';

class ApiConfig {
  static String _overrideBaseUrl = '';

  static void setBaseUrl(String url) {
    _overrideBaseUrl = url;
  }

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5224/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5224/api';
    } else {
      return 'http://localhost:5224/api';
    }
  }
}
