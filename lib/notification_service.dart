import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Download image from URL and save locally
  Future<String?> _downloadAndSaveImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/notification_image.jpg');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }

  initFCM () async {
    final permission = await _firebaseMessaging.requestPermission();
    print('Permission: ${permission}');
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      throw Exception('User has denied permission');
    }


    final fcmtoken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmtoken");

    // Background notification listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message: ${message.notification?.title}');
    });

    // Foreground notification listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      
      // forground
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      AppleNotification? apple = message.notification?.apple;
      
      if (notification != null) {
        // Get image URL from platform-specific notification
        String? imageUrl = android?.imageUrl ?? apple?.imageUrl;
        String? localImagePath;
        
        // Download image if URL exists
        if (imageUrl != null && imageUrl.isNotEmpty) {
          localImagePath = await _downloadAndSaveImage(imageUrl);
        }
        
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              styleInformation: localImagePath != null
                  ? BigPictureStyleInformation(
                      FilePathAndroidBitmap(localImagePath),
                      largeIcon: FilePathAndroidBitmap(localImagePath),
                      contentTitle: notification.title,
                      summaryText: notification.body,
                      hideExpandedLargeIcon: false,
                    )
                  : null,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              attachments: localImagePath != null
                  ? [DarwinNotificationAttachment(localImagePath)]
                  : null,
            ),
          ),
        );
      }
    });

    // Local notification initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );

    await createLocalNotificationChannel();
  

    // FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
    //   print('Background Message: ${message.notification?.title}');
    // });
  }

  // Create local notification channel
  Future<void> createLocalNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Get access token using service account
  Future <AccessCredentials> _getAccessToken() async {
    final serviceAccountPath = dotenv.env['PATH_TO_SECRET'];

    String serviceAccountJson = await rootBundle.loadString(
      serviceAccountPath!
    );

    // log("json: $serviceAccountJson");
    final serviceAccount = ServiceAccountCredentials.fromJson(
      serviceAccountJson
    );

    final scopes = [
      'https://www.googleapis.com/auth/firebase.messaging'
    ];

    final client = await clientViaServiceAccount(
      serviceAccount,
      scopes
    );
    return client.credentials;
  }

  Future<bool> sendPushNotification({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    if (deviceToken.isEmpty)  return false;

    final credentials = await _getAccessToken();
    final accessToken = credentials.accessToken.data;
    final projectId = dotenv.env['PROJECT_ID'];

    await Future.delayed(const Duration(seconds: 2));

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'
    );

    final message = {
      "message": {
        "token": deviceToken,
        "notification": {
          "title": title,
          "body": body,
          if (imageUrl != null) "image": imageUrl,
        },
        "data": data ?? {},
      }
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Push notification sent successfully');
      return true;
    } else {
      print('Failed to send push notification: ${response.body}');
      return false;
    }
  }
}

onDidReceiveNotificationResponse(NotificationResponse details) {
  // Handle the notification response here
  print('Details: ${details}');
}

onDidReceiveBackgroundNotificationResponse(NotificationResponse details) {
  // Handle the background notification response here
  print('Background Details: ${details}');
}