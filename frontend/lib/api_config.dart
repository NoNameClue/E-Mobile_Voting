import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // Your laptop's actual Wi-Fi IP (You mentioned earlier it was 192.168.1.16)
  // You only need this when testing on your REAL, physical phone.
  static const String physicalPhoneIp = '192.168.1.16';

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