import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static final bool isEmulator = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static final bool isRelease = bool.fromEnvironment("dart.vm.product");

  static String get baseUrl {
    if (isEmulator) {
      // Emulator case
      return isRelease
          ? 'https://crowdease-api.onrender.com' // App built and tested on emulator with Render
          : 'http://10.0.2.2:8000';               // App run via emulator with local backend
    } else {
      // Real phone or web build
      return 'https://crowdease-api.onrender.com'; // Always use live backend
    }
  }
}



// const bool isLocal = true; // false if deployed

// // final String baseUrl = isLocal
// //     // ? 'http://10.0.2.2:8000'  // For emulator to access local backend
// //     ? 'https://crowdease-api.onrender.com'  // For emulator to access local backend
// //     : 'https://crowdease-api.onrender.com'; // Render backend URL

// final String baseUrl = 'http://10.0.2.2:8000';

