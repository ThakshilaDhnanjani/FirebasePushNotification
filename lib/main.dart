import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pushnotification/notification_service.dart';

import 'firebase_options.dart';

Future <void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  final notificationService = NotificationService();
  await notificationService.initFCM();

  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Push Notification'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child:InkWell(
          onTap: () async {
            // Send test notification
            NotificationService().sendPushNotification(
              deviceToken: 'fqz_odq5RhyRkLsxynTW6Z:APA91bHRx8KpBQetfOmjZgKV6iasNyErml78IeW14twIAFscS5hXoYjGtLvRZn7OQS1IzgnH1fuHtwjQmU71w4WdWdfASZ40APvdpGrTpemVsm_gKVc97Nw',
              title: 'Hesha',
              body: 'hi akka',
              imageUrl: 'https://www.newscientist.com/article/2339505-rspb-and-other-nature-charities-raise-alarm-over-uk-government-plans/',
            );
          },
          child: Text("Notifications")) 
        ),
    );
  }
}

Future <void> handleBackgroundMessage(RemoteMessage message) async {
  print("Message: ${message.notification?.title}");
}