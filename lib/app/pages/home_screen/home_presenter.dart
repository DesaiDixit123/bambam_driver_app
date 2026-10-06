import 'package:bam_bam_driver/domain/domain.dart';

class HomePresenter {
  HomePresenter(this.homeUsecases);

  final HomeUsecases homeUsecases;

  Future<ResponseModel> getEarningsVaultData({
    String? startDate,
    String? endDate,
    String? tripType,
    int page = 1,
    int limit = 10,
    bool showLoader = true,
  }) {
    return homeUsecases.getEarningsVaultData(
      startDate: startDate,
      endDate: endDate,
      tripType: tripType,
      page: page,
      limit: limit,
      showLoader: showLoader,
    );
  }

  Future<ResponseModel> withdrawEarnings({
    required int amount,
    String method = "Bank",
    Map<String, dynamic>? bankDetails,
    String? upiId,
    String? notes,
    bool showLoader = true,
  }) {
    return homeUsecases.withdrawEarnings(
      amount: amount,
      method: method,
      bankDetails: bankDetails,
      upiId: upiId,
      notes: notes,
      showLoader: showLoader,
    );
  }

  Future<ResponseModel> createTopUpOrder({
    required int amount,
    String? razorpayUserId,
    bool showLoader = true,
  }) {
    return homeUsecases.createTopUpOrder(
      amount: amount,
      razorpayUserId: razorpayUserId,
      showLoader: showLoader,
    );
  }

  Future<ResponseModel> verifyTopUpPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    bool showLoader = true,
  }) {
    return homeUsecases.verifyTopUpPayment(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      showLoader: showLoader,
    );
  }

  Future<ResponseModel> reverseGeocode({
    required double lat,
    required double lng,
  }) {
    return homeUsecases.reverseGeocode(lat: lat, lng: lng);
  }

  Future<ResponseModel> updateDriverLocation({
    required double lat,
    required double lng,
  }) {
    return homeUsecases.updateDriverLocation(lat: lat, lng: lng);
  }
}
