import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/data.dart';
import 'package:bam_bam_driver/device/device.dart';
import 'package:bam_bam_driver/domain/domain.dart';

const AndroidNotificationChannel _firebaseChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important foreground notifications.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('FCM Background Message received: ${message.messageId}');
  
  // Filtering Logic for Background
  try {
    // Note: In background, we might need to re-initialize Hive/Get if not already done
    // but usually, for simple key reading, we can try to find the repository.
    if (message.data['type'] == 'new_ride_request' || message.data['bookingId'] != null) {
       // If it's a ride request, we usually want the foreground app to handle it via Socket
       // but if we play sound here, we should filter.
    }
  } catch (e) {
    print("FCM Background Filtering Error: $e");
  }
}

Future<void> _showForegroundNotification(RemoteMessage message) async {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title']?.toString() ?? '';
  final body = notification?.body ?? message.data['body']?.toString() ?? '';

  // --- FILTERING LOGIC ---
  try {
    if (Get.isRegistered<Repository>()) {
      final repo = Get.find<Repository>();
      final currentLoginType = repo.getStringValue(LocalKeys.loginType);
      
      // Check if it's a ride request (from type or bookingId presence)
      if (message.data['type'] == 'new_ride_request' || 
          message.data['bookingId'] != null || 
          title.toLowerCase().contains('ride') || 
          title.toLowerCase().contains('booking')) {
        
        final rideSource = message.data['source']?.toString();
        final vendorId = message.data['vendor_id']?.toString() ?? message.data['vendorRequestId']?.toString();
        
        // A ride is considered a "Company Ride" if it comes from a Vendor source or has a vendor identifier
        bool isCompanyRide = (rideSource == 'Vendor') || (vendorId != null && vendorId.isNotEmpty && vendorId != "null");
        
        if (currentLoginType == 'individual' && isCompanyRide) {
          print("FCM: Ignoring COMPANY ride notification in INDIVIDUAL mode.");
          return;
        } else if (currentLoginType == 'company' && !isCompanyRide) {
          print("FCM: Ignoring INDIVIDUAL ride notification in COMPANY mode.");
          return;
        }
      }
    }
  } catch (e) {
    print("FCM: Error in foreground filtering: $e");
  }
  // -----------------------

  final androidDetails = AndroidNotificationDetails(
    _firebaseChannel.id,
    _firebaseChannel.name,
    channelDescription: _firebaseChannel.description,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  final platformDetails = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    id: notification?.hashCode ?? message.hashCode,
    title: title,
    body: body,
    notificationDetails: platformDetails,
    payload: message.data.isNotEmpty ? message.data.toString() : null,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize services early so Repository is available for FCM listeners
  await initServices();

  const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettingsDarwin = DarwinInitializationSettings();
  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_firebaseChannel);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('FCM Foreground Message received: ${message.messageId}');
    await _showForegroundNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('FCM Notification opened: ${message.messageId}');
  });

  runApp(const MyApp());
}

Future<void> initServices() async {
  await Hive.initFlutter();

  Get.put(
    Repository(
      Get.put(DeviceRepository(), permanent: true),
      Get.put(
        DataRepository(Get.put(ConnectHelper(), permanent: true)),
        permanent: true,
      ),
    ),
  );

  /// Services
  await Get.putAsync(() => CommonService().init());
  await Get.putAsync(() => DbService().init());

  SocketConnection.initSocket();
}

class DbService extends GetxService {
  Future<DbService> init() async {
    await Get.find<DeviceRepository>().init();
    return this;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: ColorsValue.appColor,
      ),
    );
    // i will check
    return ScreenUtilInit(
      minTextAdapt: true,
      designSize: const Size(375, 745),
      builder: (_, child) => GetMaterialApp(
        locale: const Locale('en'),
        debugShowCheckedModeBanner: false,
        title: StringConstants.appName,
        theme: themeData(context),
        darkTheme: darkThemeData(context),
        themeMode: ThemeMode.light,
        getPages: AppPages.pages,
        initialRoute: Routes.splashScreen,
        translations: TranslationsFile(),
        navigatorKey: Get.key,
        enableLog: true,
      ),
    );
  }
}
