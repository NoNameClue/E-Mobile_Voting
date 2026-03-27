import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // ⚠️ CRITICAL: Change this to your laptop's actual IPv4 address!
  // 1. Open CMD on your laptop.
  // 2. Type 'ipconfig' and press Enter.
  // 3. Look for "IPv4 Address" under your Wi-Fi network.
  static const String _laptopIpAddress = '127.0.0.1'; // <--- PUT YOUR IP HERE

  static String get baseUrl {
    // For testing on a real physical phone via APK, you MUST use the laptop's Wi-Fi IP.
    // This will also work perfectly for Web and Emulators!
    return 'http://$_laptopIpAddress:8000';

    /* --- I kept your old code here just in case you want to revert later ---
    if (kIsWeb) {
      // Chrome / Web always uses standard localhost
      return 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      // Android Emulators strictly require this bridge IP (BUT REAL PHONES DON'T)
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000'; // Fallback
    */
  }
}