// File generated manually for JAYA FREIGHT.
// This file connects your app to your Firebase project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    // Flutter Web and Desktop will use the 'web' config.
    return web;
  }

  // --- YOUR KEYS ARE PASTED BELOW ---

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDsqGufQ6NFGSd2mw5mqp-qtGiW9QneU-c",
    appId: "1:835535214409:web:3836154efdeb73951cec98",
    messagingSenderId: "835535214409",
    projectId: "jaya-freight",
    authDomain: "jaya-freight.firebaseapp.com",
    storageBucket: "jaya-freight.firebasestorage.app",
  );

  // We use the same 'web' keys for Android and iOS
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDsqGufQ6NFGSd2mw5mqp-qtGiW9QneU-c",
    appId: "1:835535214409:web:3836154efdeb73951cec98",
    messagingSenderId: "835535214409",
    projectId: "jaya-freight",
    authDomain: "jaya-freight.firebaseapp.com",
    storageBucket: "jaya-freight.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyDsqGufQ6NFGSd2mw5mqp-qtGiW9QneU-c",
    appId: "1:835535214409:web:3836154efdeb73951cec98",
    messagingSenderId: "835535214409",
    projectId: "jaya-freight",
    authDomain: "jaya-freight.firebaseapp.com",
    storageBucket: "jaya-freight.firebasestorage.app",
  );
}
