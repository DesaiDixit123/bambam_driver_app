import 'dart:convert';

import 'package:bam_bam_driver/app/pages/home_screen/Screens/new_ride_popup.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:bam_bam_driver/data/data.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:bam_bam_driver/domain/services/audio_service.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_controller.dart';
import 'package:bam_bam_driver/app/pages/home_screen/home_controller.dart';

abstract class SocketConnection {
  static IO.Socket? socket;

  static socketDisconnect() {
    socket?.disconnect();
  }

  static initSocket() {
    // Note: We use the base URL of the API for the socket connection.
    // Strip '/driver/' if needed, but often the socket server is at the root.
    // Given ApiWrapper.baseUrl is https://apis.bambamcabs.com/driver/
    String socketUrl = ApiWrapper.baseUrl.replaceAll('/driver/', '');

    socket = IO.io(socketUrl, <String, dynamic>{
      'autoConnect': false,
      'transports': ['websocket'],
    });

    socket!.connect();

    socket!.onConnect((_) {
      print("Socket Connected Successfully...");
      String channelId = Get.find<Repository>().getStringValue(
        LocalKeys.channelId,
      );

      // If channelId is not explicitly set, try to extract it from userDetails
      if (channelId.isEmpty) {
        String userDetailsStr = Get.find<Repository>().getStringValue(
          LocalKeys.userDetails,
        );
        if (userDetailsStr.isNotEmpty) {
          try {
            final userDetails = jsonDecode(userDetailsStr);
            channelId = userDetails['_id']?.toString() ?? '';
          } catch (e) {
            print("Error parsing userDetails for channelId: $e");
          }
        }
      }

      print("Joining channel: $channelId");
      if (channelId.isNotEmpty) {
        socket!.emit('init', {'channelid': channelId});
      }
    });

    // Main event listener for the channel
    String channelId = Get.find<Repository>().getStringValue(
      LocalKeys.channelId,
    );

    if (channelId.isEmpty) {
      String userDetailsStr = Get.find<Repository>().getStringValue(
        LocalKeys.userDetails,
      );
      if (userDetailsStr.isNotEmpty) {
        try {
          final userDetails = jsonDecode(userDetailsStr);
          channelId = userDetails['_id']?.toString() ?? '';
        } catch (_) {}
      }
    }
    
    if (channelId.isNotEmpty) {
      _listenToChannel(channelId);
    }

    socket!.on('new_ride_request', (data) async {
      print("Socket: New ride request received: $data");

      // --- FILTERING LOGIC ---
      Map<String, dynamic> ride = data['rideDetails'] ?? data;
      try {
        final repo = Get.find<Repository>();
        final currentLoginType = repo.getStringValue(LocalKeys.loginType);
        
        final rideSource = data['source']?.toString();
        final vendorId = ride['vendor_id']?.toString();
        
        // A ride is considered a "Company Ride" if it comes from a Vendor source or has a vendor_id
        bool isCompanyRide = (rideSource == 'Vendor') || (vendorId != null && vendorId.isNotEmpty && vendorId != "null");
        
        if (currentLoginType == 'individual' && isCompanyRide) {
          print("Socket: Ignoring COMPANY ride because driver is in INDIVIDUAL mode.");
          return;
        } else if (currentLoginType == 'company' && !isCompanyRide) {
          print("Socket: Ignoring INDIVIDUAL ride because driver is in COMPANY mode.");
          return;
        }
      } catch (e) {
        print("Socket: Error in filtering logic: $e");
      }
      // -----------------------

      // 1. Resolve Full Data if Incomplete
      final String bookingId = ride['_id']?.toString() ?? data['bookingId']?.toString() ?? data['booking_id']?.toString() ?? "";
      final travelData = ride['travelDetailsId'];

      if (travelData is String && bookingId.isNotEmpty) {
        print("Socket: Incomplete data (travelDetailsId is String), fetching full details for $bookingId...");
        if (Get.isRegistered<TripController>()) {
          final res = await Get.find<TripController>().tripPresenter.getTripDetails(bookingId);
          if (!res.hasError) {
            try {
              final body = jsonDecode(res.data);
              if (body['IsSuccess'] == true && body['Data'] != null) {
                ride = body['Data'];
                print("Socket: Full details fetched successfully.");
              }
            } catch (e) {
              print("Socket: Error parsing fetched details: $e");
            }
          }
        }
      }
      
      // 2. Play Ringtone
      AudioService.playRingtone();

      // 3. Refresh Controllers
      if (Get.isRegistered<TripController>()) {
        Get.find<TripController>().fetchAssignedTrips();
      }
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().startRingtone();
        Get.find<HomeController>().fetchDashboardSafe();
      }

      // 4. Show Popup
      Future.delayed(const Duration(milliseconds: 200), () {
        try {
          if (bookingId.isNotEmpty) {
            if (NewRidePopup.activeBookingIds.contains(bookingId)) {
              print("Socket: Popup for $bookingId already active, skipping...");
              return;
            }
            NewRidePopup.activeBookingIds.add(bookingId);
          }

          if (Get.overlayContext != null) {
            showDialog(
              context: Get.overlayContext!,
              barrierDismissible: false,
              useRootNavigator: true,
              builder: (context) => WillPopScope(
                onWillPop: () async => false,
                child: Material(
                  type: MaterialType.transparency,
                  child: NewRidePopup(
                    rideData: ride,
                    requestId: data['request_id']?.toString() ?? data['vendorRequestId']?.toString() ?? "",
                  ),
                ),
              ),
            );
          }
        } catch (e) {
          print("Socket: Error showing dialog: $e");
        }
      });
    });

    socket!.on('ride_expired', (data) {
      print("Socket: Ride expired: $data");
      AudioService.stopRingtone();
      
      // Close the popup if it's open (Get.back() will close the top-most dialog)
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      if (Get.isRegistered<TripController>()) {
        Get.find<TripController>().fetchAssignedTrips();
      }
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().stopRingtone();
        Get.find<HomeController>().fetchDashboardSafe();
      }
    });

    socket!.onDisconnect((_) => print('Socket Connection Disconnected'));
    socket!.onConnectError((err) => print('Socket Connection Error: $err'));
    socket!.onError((err) => print('Socket Error: $err'));
  }

  static void updateChannelId(String newChannelId) {
    if (socket == null || newChannelId.isEmpty) return;
    
    String currentChannelId = Get.find<Repository>().getStringValue(LocalKeys.channelId);
    if (currentChannelId == newChannelId) return; // Already joined
    
    print("Socket: Updating and joining channel ID: $newChannelId");
    Get.find<Repository>().saveValue(LocalKeys.channelId, newChannelId);
    socket!.emit('init', {'channelid': newChannelId});
    _listenToChannel(newChannelId);
  }

  static void _listenToChannel(String channelId) {
    socket!.on(channelId, (data) async {
      print("Socket Event Received: $data");
      if (data is Map && data.containsKey('event')) {
        String event = data['event'];

        switch (event) {
          case 'onuserlogin':
            print("User Login Event Received");
            break;
          case 'onroombooking':
            print("Room Booking Event Received");
            AudioService.playRingtone();
            Get.snackbar("Booking", "New booking received!");
            if (Get.isRegistered<TripController>()) {
              Get.find<TripController>().fetchAssignedTrips();
            }
            break;
          case 'onamenitiesbooking':
            print("Amenities Booking Event Received");
            Get.snackbar("Booking", "New booking received!");
            break;
          case 'onnewannouncement':
            print("New Announcement Received");
            Get.snackbar("Announcement", "You have a new announcement");
            break;
          case 'onroombookingcancelled':
            print("Room Booking Cancelled Received");
            Get.snackbar("Cancelled", "A  booking has been cancelled");
            break;
          case 'onamenitiesbookingcancelled':
            print("Amenities Booking Cancelled Received");
            Get.snackbar("Cancelled", "An booking has been cancelled");
            break;
          case 'onthemesave':
            Get.forceAppUpdate();
            break;
        }
      }
    });
  }
}
