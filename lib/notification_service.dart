import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  initFCM () async {
    await _firebaseMessaging.requestPermission();

    final fcmtoken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmtoken");

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message: ${message.notification?.title}');
    });

    // FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
    //   print('Background Message: ${message.notification?.title}');
    // });
  }
}