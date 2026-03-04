import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Chrome / Web always uses standard localhost
      return 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      // Android Emulators strictly require this bridge IP
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000'; // Fallback
  }
}