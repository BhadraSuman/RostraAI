import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDVA0eWXP6v06k0TxHrdrAXYeUmafsBJ_A',
    appId: '1:5676201507:android:0ce633f01b451a1ca32396',
    messagingSenderId: '5676201507',
    projectId: 'rostraai',
    storageBucket: 'rostraai.firebasestorage.app',
  );
}
