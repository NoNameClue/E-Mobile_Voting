import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {

  static const String physicalPhoneIp = '10.10.216.1';

  static String get baseUrl {
    // 1. CHROME / WEB TESTING
    if (kIsWeb) {
      return 'http://127.0.0.1:8000'; 
    } 
    
    // 2. ANDROID TESTING (Emulator vs. Physical Phone)
    if (Platform.isAndroid) {
      
      // 🟢 USE THIS LINE FOR THE ANDROID EMULATOR:
      return 'http://10.0.2.2:8000';

      // 🔴 USE THIS LINE FOR A REAL PHYSICAL PHONE:
      // return 'http://$physicalPhoneIp:8000';
    } 
    
    // 3. iOS SIMULATOR TESTING
    if (Platform.isIOS) {
      return 'http://127.0.0.1:8000';
    }

    // FALLBACK
    return 'http://127.0.0.1:8000'; 
  }
}