import 'dart:convert';
import 'dart:typed_data';

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
import 'package:bam_bam_driver/domain/services/audio_service.dart';
import 'package:bam_bam_driver/domain/services/native_overlay_service.dart';
import 'package:bam_bam_driver/domain/services/socket_connection.dart';
import 'package:bam_bam_driver/app/pages/home_screen/Screens/new_ride_popup.dart';

const AndroidNotificationChannel _rideAlertChannel = AndroidNotificationChannel(
  'ride_alert_channel',
  'Ride Alert Notifications',
  description: 'High priority incoming ride alerts with alarm ringtone.',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('alarm_clock'),
  enableVibration: true,
);

const AndroidNotificationChannel _firebaseChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important foreground notifications.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('FCM Background Message received: ${message.messageId}, data: ${message.data}');

  final String type = (message.data['type'] ?? '').toString().toLowerCase();
  final bool isRideMessage = type == 'new_ride' || type == 'new_ride_request';

  if (isRideMessage) {
    try {
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_rideAlertChannel);

      // Force screen wake up and bring to foreground over lockscreen
      NativeOverlayService.bringToForeground(message.data);

      // Play ringtone
      AudioService.playRingtone();

      // Show full-screen heads-up notification with alarm ringtone
      final androidDetails = AndroidNotificationDetails(
        _rideAlertChannel.id,
        _rideAlertChannel.name,
        channelDescription: _rideAlertChannel.description,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm_clock'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        visibility: NotificationVisibility.public,
        autoCancel: true,
      );

      final platformDetails = NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        id: message.hashCode,
        title: message.notification?.title ?? message.data['title'] ?? '🚖 New Ride Request!',
        body: message.notification?.body ?? message.data['body'] ?? 'You have a new ride request. Tap to view and accept.',
        notificationDetails: platformDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      print("FCM Background Notification Error: $e");
    }
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
      final currentLoginType = repo.getStringValue(LocalKeys.loginType).toLowerCase().trim();

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

  final String type = (message.data['type'] ?? '').toString().toLowerCase();
  final bool isRideMessage = type == 'new_ride' || type == 'new_ride_request';

  final androidDetails = isRideMessage
      ? AndroidNotificationDetails(
          _rideAlertChannel.id,
          _rideAlertChannel.name,
          channelDescription: _rideAlertChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('alarm_clock'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
          visibility: NotificationVisibility.public,
        )
      : AndroidNotificationDetails(
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
    title: title.isNotEmpty
        ? title
        : (isRideMessage ? '🚖 New Ride Request!' : 'BamBam Cabs Notification'),
    body: body.isNotEmpty
        ? body
        : (isRideMessage ? 'A new ride request is available in your area.' : ''),
    notificationDetails: platformDetails,
    payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
  );

  // If this foreground notification is a new ride request, show dialog & play ringtone immediately
  if (isRideMessage) {
    NativeOverlayService.bringToForeground(message.data);
    AudioService.playRingtone();
    print("FCM Foreground: Triggering showRidePopup fallback for new ride request...");
    SocketConnection.showRidePopup(message.data);
  }
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
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null && response.payload!.isNotEmpty) {
        try {
          final data = jsonDecode(response.payload!);
          if (data is Map<String, dynamic>) {
            final String type = (data['type'] ?? '').toString().toLowerCase();
            if (type == 'new_ride' || type == 'new_ride_request') {
              final bId = (data['bookingId'] ?? data['booking_id'] ?? '').toString();
              if (bId.isNotEmpty) {
                NewRidePopup.activeBookingIds.remove(bId);
              }
              NativeOverlayService.bringToForeground(data);
              SocketConnection.showRidePopup(data);
            }
          }
        } catch (e) {
          print("Error handling notification payload: $e");
        }
      }
    },
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  // Create both notification channels
  await androidPlugin?.createNotificationChannel(_rideAlertChannel);
  await androidPlugin?.createNotificationChannel(_firebaseChannel);

  // Request Android 13+ Notification Permission
  await androidPlugin?.requestNotificationsPermission();

  // Request FCM Permission
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
  } catch (e) {
    print("FCM permission request error: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('FCM Foreground Message received: ${message.messageId}');
    await _showForegroundNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('FCM Notification opened: ${message.messageId}');
    if (message.data.isNotEmpty) {
      final String type = (message.data['type'] ?? '').toString().toLowerCase();
      if (type == 'new_ride' || type == 'new_ride_request') {
        final bId = (message.data['bookingId'] ?? message.data['booking_id'] ?? '').toString();
        if (bId.isNotEmpty) {
          NewRidePopup.activeBookingIds.remove(bId);
        }
        NativeOverlayService.bringToForeground(message.data);
        SocketConnection.showRidePopup(message.data);
      }
    }
  });

  // Handle cold launch from notification
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null && message.data.isNotEmpty) {
      final String type = (message.data['type'] ?? '').toString().toLowerCase();
      if (type == 'new_ride' || type == 'new_ride_request') {
        Future.delayed(const Duration(milliseconds: 1000), () {
          final bId = (message.data['bookingId'] ?? message.data['booking_id'] ?? '').toString();
          if (bId.isNotEmpty) {
            NewRidePopup.activeBookingIds.remove(bId);
          }
          SocketConnection.showRidePopup(message.data);
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: ColorsValue.appColor,
      ),
    );

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
