// Placeholder Firebase configuration.
// Replace the values with those from your Firebase console.
// The FlutterFire CLI can generate this file for you.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web configuration
      return const FirebaseOptions(
        apiKey: 'YOUR-API-KEY',
        authDomain: 'YOUR-PROJECT.firebaseapp.com',
        projectId: 'YOUR-PROJECT',
        storageBucket: 'YOUR-PROJECT.appspot.com',
        messagingSenderId: 'YOUR-MESSAGING-SENDER-ID',
        appId: 'YOUR-APP-ID',
        measurementId: 'YOUR-MEASUREMENT-ID',
      );
    }
    // Default to Android configuration; replace with your own values.
    return const FirebaseOptions(
      apiKey: 'YOUR-API-KEY',
      appId: 'YOUR-APP-ID',
      messagingSenderId: 'YOUR-MESSAGING-SENDER-ID',
      projectId: 'YOUR-PROJECT',
      storageBucket: 'YOUR-PROJECT.appspot.com',
    );
  }
}
