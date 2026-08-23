import 'dart:convert';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/models/response_model.dart';
import 'package:get/get.dart';

class RejectedRidesController extends GetxController {
  RejectedRidesController(this._tripPresenter);
  final TripPresenter _tripPresenter;

  var isLoading = false.obs;
  var rejectedRides = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchRejectedRides();
  }

  Future<void> fetchRejectedRides() async {
    isLoading.value = true;
    try {
      // We'll add this method to TripPresenter
      ResponseModel response = await _tripPresenter.getRejectedRideList();
      if (response.hasError) {
        Utility.errorMessage('Error: ${response.data}');
      } else {
        var decoded = jsonDecode(response.data);
        if (decoded['IsSuccess'] == true) {
          rejectedRides.value = decoded['Data'] ?? [];
        } else {
          Utility.errorMessage(decoded['Message'] ?? 'Failed to fetch rejected rides');
        }
      }
    } catch (e) {
      Utility.errorMessage('Something went wrong: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onBack() {
    Get.back();
  }

  void gotoTripDetails(var ride) {
    if (ride['booking_id'] != null) {
      RouteManagement.gotoTripDetilesScreen(
        isComplectTrip: false,
        tripId: ride['booking_id']['_id'],
      );
    }
  }
}

