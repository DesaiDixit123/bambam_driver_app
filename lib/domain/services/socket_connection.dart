import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:bam_bam_driver/app/pages/home_screen/Screens/new_ride_popup.dart';
import 'package:bam_bam_driver/app/widgets/individual_ride_alert_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:bam_bam_driver/data/data.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:bam_bam_driver/domain/services/audio_service.dart';
import 'package:bam_bam_driver/domain/services/native_overlay_service.dart';
import 'package:bam_bam_driver/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_controller.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_binding.dart';
import 'package:bam_bam_driver/app/pages/home_screen/home_controller.dart';

abstract class SocketConnection {
  static IO.Socket? socket;
  static Timer? _heartbeatTimer;

  static socketDisconnect() {
    _heartbeatTimer?.cancel();
    socket?.disconnect();
  }

  /// Extracts the driver ID from channelId, userDetails, or decoded JWT token
  static String getDriverId() {
    try {
      if (!Get.isRegistered<Repository>()) return '';
      final repo = Get.find<Repository>();

      String channelId = repo.getStringValue(LocalKeys.channelId);
      if (channelId.isNotEmpty) return channelId;

      String userDetailsStr = repo.getStringValue(LocalKeys.userDetails);
      if (userDetailsStr.isNotEmpty) {
        final userDetails = jsonDecode(userDetailsStr);
        String id = userDetails['_id']?.toString() ??
            userDetails['driverId']?.toString() ??
            userDetails['id']?.toString() ??
            '';
        if (id.isNotEmpty) {
          repo.saveValue(LocalKeys.channelId, id);
          return id;
        }
      }

      String token = repo.getStringValue(LocalKeys.authToken);
      if (token.isNotEmpty) {
        final parts = token.split('.');
        if (parts.length == 3) {
          String normalized = base64Url.normalize(parts[1]);
          String payloadStr = utf8.decode(base64Url.decode(normalized));
          final payload = jsonDecode(payloadStr);
          String id = payload['driverId']?.toString() ??
              payload['_id']?.toString() ??
              payload['id']?.toString() ??
              '';
          if (id.isNotEmpty) {
            repo.saveValue(LocalKeys.channelId, id);
            return id;
          }
        }
      }
    } catch (e) {
      print("Error resolving driverId: $e");
    }
    return '';
  }

  static void initSocket() {
    if (socket != null && socket!.connected) {
      print("Socket already connected, re-verifying channel join...");
      final driverId = getDriverId();
      if (driverId.isNotEmpty) {
        socket!.emit('init', {'channelid': driverId});
        _listenToChannel(driverId);
      }
      return;
    }

    String socketUrl = ApiWrapper.baseUrl.replaceAll('/driver/', '');
    print("Initializing socket at: $socketUrl");

    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 99999,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
    });

    socket!.onConnect((_) {
      print("Socket Connected Successfully...");
      final driverId = getDriverId();
      print("Socket: Joining driver channel: $driverId");
      if (driverId.isNotEmpty) {
        socket!.emit('init', {'channelid': driverId});
        _listenToChannel(driverId);
      }
    });

    socket!.on('reconnect', (_) {
      print("Socket Reconnected...");
      final driverId = getDriverId();
      if (driverId.isNotEmpty) {
        socket!.emit('init', {'channelid': driverId});
      }
    });

    // Listen to global / room new_ride_request
    socket!.on('new_ride_request', (data) async {
      print("Socket: 'new_ride_request' event received: $data");
      showRidePopup(data);
    });

    void handleRideUnavailable(dynamic data, String eventName) {
      print("Socket: $eventName: $data");
      AudioService.stopRingtone();

      if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
        Get.back();
      }

      if (Get.isRegistered<TripController>()) {
        Get.find<TripController>().fetchAssignedTrips();
      }
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().stopRingtone();
        Get.find<HomeController>().fetchDashboardSafe();
      }
    }

    socket!.on('ride_expired', (data) => handleRideUnavailable(data, 'ride_expired'));
    socket!.on('ride_taken', (data) => handleRideUnavailable(data, 'ride_taken'));

    socket!.onDisconnect((reason) => print('Socket Connection Disconnected: $reason'));
    socket!.onConnectError((err) => print('Socket Connection Error: $err'));
    socket!.onError((err) => print('Socket Error: $err'));

    final currentId = getDriverId();
    if (currentId.isNotEmpty) {
      _listenToChannel(currentId);
    }

    // Heartbeat every 30s to keep socket room membership active
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (socket != null) {
        if (!socket!.connected) {
          print("Socket heartbeat: reconnecting...");
          socket!.connect();
        } else {
          final id = getDriverId();
          if (id.isNotEmpty) {
            socket!.emit('init', {'channelid': id});
          }
        }
      }
    });
  }

  static void updateChannelId(String newChannelId) {
    if (newChannelId.isEmpty) return;
    if (Get.isRegistered<Repository>()) {
      Get.find<Repository>().saveValue(LocalKeys.channelId, newChannelId);
    }
    if (socket != null && socket!.connected) {
      print("Socket: Updating and joining channel ID: $newChannelId");
      socket!.emit('init', {'channelid': newChannelId});
      _listenToChannel(newChannelId);
    } else {
      initSocket();
    }
  }

  static void _listenToChannel(String channelId) {
    if (socket == null || channelId.isEmpty) return;

    socket!.off(channelId);
    socket!.on(channelId, (data) async {
      print("Socket Channel ($channelId) Event Received: $data");
      if (data is Map) {
        String event = data['event']?.toString() ?? '';
        if (event == 'new_ride_request') {
          showRidePopup(data);
          return;
        } else if (event == 'ride_expired' || event == 'ride_taken') {
          AudioService.stopRingtone();
          if (Get.isDialogOpen == true) Get.back();
          return;
        }
      }
    });
  }

  /// Core handler to play ringtone and show ride popup dialog
  static Future<void> showRidePopup(dynamic rawData) async {
    try {
      print("SocketConnection.showRidePopup triggered with: $rawData");
      Map<String, dynamic> data = (rawData is Map)
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

      Map<String, dynamic> ride = (data['rideDetails'] is Map)
          ? Map<String, dynamic>.from(data['rideDetails'])
          : data;

      final String notifType = (data['type'] ?? ride['type'] ?? data['event'] ?? '').toString().toLowerCase();
      if (notifType.contains('completed') ||
          notifType.contains('cancel') ||
          notifType.contains('expired') ||
          notifType.contains('taken')) {
        print("showRidePopup: Ignoring non-request notification type: $notifType");
        return;
      }

      final String bStatus = (ride['booking_status'] ?? data['booking_status'] ?? '').toString().toLowerCase();
      if (bStatus == 'completed' || bStatus == 'cancelled' || bStatus == 'rejected') {
        print("showRidePopup: Ignoring booking with completed/cancelled status: $bStatus");
        return;
      }

      final String bookingId = ride['_id']?.toString() ??
          data['bookingId']?.toString() ??
          data['booking_id']?.toString() ??
          ride['booking_id']?.toString() ??
          "";

      if (bookingId.isEmpty) {
        print("showRidePopup: Booking ID is empty, skipping...");
        return;
      }

      Map<String, dynamic> mergedRide = Map<String, dynamic>.from(ride);
      data.forEach((k, v) {
        if (!mergedRide.containsKey(k) || mergedRide[k] == null || mergedRide[k].toString().isEmpty) {
          mergedRide[k] = v;
        }
      });

      final String finalRequestId = (data['request_id'] ??
              mergedRide['request_id'] ??
              data['vendorRequestId'] ??
              mergedRide['vendorRequestId'] ??
              data['bookingId'] ??
              bookingId)
          .toString();

      // 1. Force wake up screen & bring app to foreground over lock screen
      try {
        NativeOverlayService.bringToForeground(mergedRide);
      } catch (e) {
        print("showRidePopup: bringToForeground error: $e");
      }

      // 2. Play Ringtone immediately
      AudioService.playRingtone();

      // 3. Show high priority heads-up notification with alarm ringtone
      try {
        const androidDetails = AndroidNotificationDetails(
          'ride_alert_channel',
          'Ride Alert Notifications',
          channelDescription: 'High priority incoming ride alerts with alarm ringtone.',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm_clock'),
          enableVibration: true,
          visibility: NotificationVisibility.public,
        );
        flutterLocalNotificationsPlugin.show(
          id: bookingId.hashCode,
          title: '🚖 New Ride Request!',
          body: 'A new ride request is available. Tap to view and accept.',
          notificationDetails: const NotificationDetails(android: androidDetails),
          payload: jsonEncode(data),
        );
      } catch (e) {
        print("showRidePopup: Notification error: $e");
      }

      // 4. Show Popup IMMEDIATELY - no waiting on controllers or network!
      _showNewRidePopupDialog(
        ride: mergedRide,
        bookingId: bookingId,
        finalRequestId: finalRequestId,
      );

      // 5. Refresh Trip & Home controllers
      if (Get.isRegistered<TripController>()) {
        final tripCtrl = Get.find<TripController>();
        final bool alreadyExists = tripCtrl.rideRequests.any((r) {
          final b = r['booking_details'] ?? r['booking'] ?? r['rideDetails'] ?? r;
          final rawBid = b is Map ? b['booking_id'] : null;
          final id = (rawBid is Map
                  ? (rawBid['booking_id'] ?? rawBid['_id'])
                  : (rawBid ?? (b is Map ? b['_id'] : null) ?? r['request_id'] ?? r['_id']))
              ?.toString();
          return id != null && (id == bookingId || id == finalRequestId);
        });

        if (!alreadyExists && bookingId.isNotEmpty) {
          tripCtrl.rideRequests.insert(0, {
            'request_id': finalRequestId,
            'booking_id': bookingId,
            'booking': mergedRide,
            'rideDetails': mergedRide,
            'booking_details': mergedRide,
            'status': 'Pending',
          });
          tripCtrl.update();
        }

        tripCtrl.fetchAssignedTrips();
        tripCtrl.fetchRideRequests();
      }
      if (Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        if (homeCtrl.newRequests <= 0) homeCtrl.newRequests = 1;
        homeCtrl.startRingtone();
        homeCtrl.update();
      }

      // 6. Non-blocking background fetch if full travel data is missing
      final travelData = mergedRide['travelDetailsId'];
      if ((travelData == null || travelData is String) && bookingId.isNotEmpty) {
        Future.microtask(() async {
          try {
            if (!Get.isRegistered<TripController>()) {
              TripBinding().dependencies();
            }
            final tripCtrl = Get.find<TripController>();
            final res = await tripCtrl.tripPresenter.getTripDetails(bookingId);
            if (!res.hasError) {
              final body = jsonDecode(res.data);
              if (body['IsSuccess'] == true && body['Data'] != null) {
                print("showRidePopup: Background details fetched successfully.");
              }
            }
          } catch (e) {
            print("showRidePopup: Background details fetch note: $e");
          }
        });
      }
    } catch (e) {
      print("showRidePopup top-level error: $e");
    }
  }

  static void _showNewRidePopupDialog({
    required Map<String, dynamic> ride,
    required String bookingId,
    required String finalRequestId,
    int retryCount = 0,
  }) {
    if (bookingId.isNotEmpty && NewRidePopup.activeBookingIds.contains(bookingId)) {
      print("showRidePopup: Popup for $bookingId already open, skipping duplicate...");
      return;
    }

    if (finalRequestId.isNotEmpty && NewRidePopup.activeBookingIds.contains(finalRequestId)) {
      print("showRidePopup: Popup for $finalRequestId already open, skipping duplicate...");
      return;
    }

    final String bNum = (ride['booking_id'] ?? '').toString();
    if (bookingId.isNotEmpty) {
      NewRidePopup.activeBookingIds.add(bookingId);
      NewRidePopup.dismissedOrSeenBookingIds.add(bookingId);
    }
    if (finalRequestId.isNotEmpty) {
      NewRidePopup.activeBookingIds.add(finalRequestId);
      NewRidePopup.dismissedOrSeenBookingIds.add(finalRequestId);
    }
    if (bNum.isNotEmpty) {
      NewRidePopup.dismissedOrSeenBookingIds.add(bNum);
    }

    // Detect whether current driver is a Company Driver or Individual Driver
    bool isCompanyDriver = false;
    try {
      String storedLoginType = '';
      if (Get.isRegistered<Repository>()) {
        final repo = Get.find<Repository>();
        storedLoginType = repo.getStringValue(LocalKeys.loginType).toLowerCase().trim();
        if (storedLoginType == 'company') {
          isCompanyDriver = true;
        } else if (storedLoginType.isEmpty) {
          final userDetailsStr = repo.getStringValue(LocalKeys.userDetails);
          if (userDetailsStr.isNotEmpty) {
            final ud = jsonDecode(userDetailsStr);
            if (ud is Map && ud['login_type']?.toString().toLowerCase().trim() == 'company') {
              isCompanyDriver = true;
            }
          }
        }
      }
      if (!isCompanyDriver && Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        if (homeCtrl.loginType.toLowerCase().trim() == 'company' || !homeCtrl.isIndividual) {
          isCompanyDriver = true;
        }
      }
      if (!isCompanyDriver && Get.isRegistered<TripController>()) {
        final tripCtrl = Get.find<TripController>();
        if (tripCtrl.isCompany || tripCtrl.loginType.toLowerCase().trim() == 'company') {
          isCompanyDriver = true;
        }
      }

      // Check ride metadata if driver login type is not explicitly 'individual'
      if (!isCompanyDriver && storedLoginType != 'individual') {
        final String targetType = (ride['target_register_type'] ??
                ride['register_type'] ??
                ride['booking']?['target_register_type'] ??
                ride['rideDetails']?['target_register_type'] ??
                '')
            .toString()
            .toLowerCase()
            .trim();
        if (targetType == 'company' ||
            ride['is_assigned_by_vendor'] == true ||
            ride['driver_assigned_by_vendor'] != null ||
            (ride['vendor_id'] != null && ride['vendor_id'].toString().isNotEmpty && ride['vendor_id'].toString() != 'null')) {
          isCompanyDriver = true;
        }
      }
    } catch (_) {}

    final bool isIndividual = !isCompanyDriver;

    void presentDialog() {
      try {
        if (isIndividual) {
          // Individual Driver: 40% Opacity Frosted Blur Background + IndividualRideAlertCard
          Get.dialog(
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: PopScope(
                canPop: false,
                child: Material(
                  type: MaterialType.transparency,
                  child: IndividualRideAlertCard(
                    rideData: ride,
                    requestId: finalRequestId,
                  ),
                ),
              ),
            ),
            barrierDismissible: false,
            barrierColor: Colors.black.withOpacity(0.40),
          );
          print("showRidePopup: Successfully presented IndividualRideAlertCard with 40% blur.");
        } else {
          // Company Driver: Original NewRidePopup untouched
          Get.dialog(
            PopScope(
              canPop: false,
              child: Material(
                type: MaterialType.transparency,
                child: NewRidePopup(
                  rideData: ride,
                  requestId: finalRequestId,
                ),
              ),
            ),
            barrierDismissible: false,
            barrierColor: Colors.black54,
          );
          print("showRidePopup: Successfully presented original NewRidePopup for Company Driver.");
        }
      } catch (e) {
        print("showRidePopup: Get.dialog error: $e, falling back to showDialog");
        try {
          final BuildContext? ctx = Get.key.currentContext ?? Get.context;
          if (ctx != null) {
            showDialog(
              context: ctx,
              barrierDismissible: false,
              useRootNavigator: true,
              barrierColor: isIndividual ? Colors.black.withOpacity(0.40) : Colors.black54,
              builder: (_) => isIndividual
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: PopScope(
                        canPop: false,
                        child: Material(
                          type: MaterialType.transparency,
                          child: IndividualRideAlertCard(
                            rideData: ride,
                            requestId: finalRequestId,
                          ),
                        ),
                      ),
                    )
                  : PopScope(
                      canPop: false,
                      child: Material(
                        type: MaterialType.transparency,
                        child: NewRidePopup(
                          rideData: ride,
                          requestId: finalRequestId,
                        ),
                      ),
                    ),
            );
          } else if (retryCount < 5) {
            Future.delayed(const Duration(milliseconds: 300), () {
              _showNewRidePopupDialog(
                ride: ride,
                bookingId: bookingId,
                finalRequestId: finalRequestId,
                retryCount: retryCount + 1,
              );
            });
          }
        } catch (err) {
          print("showRidePopup: Fallback showDialog also failed: $err");
          if (bookingId.isNotEmpty) NewRidePopup.activeBookingIds.remove(bookingId);
        }
      }
    }

    void doPresent() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        presentDialog();
      });
    }

    // Close any previous dialog with a slight delay before presenting the new ride popup
    if (Get.isDialogOpen == true) {
      Get.back();
      Future.delayed(const Duration(milliseconds: 150), doPresent);
    } else {
      doPresent();
    }
  }
}
