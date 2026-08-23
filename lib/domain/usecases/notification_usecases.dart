import 'dart:async';
import 'dart:convert';

import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:bam_bam_driver/domain/domain.dart';

class NotificationUsecases {
  final Repository repository;
  NotificationUsecases(this.repository);

  /// Calls POST /driver/application/notifications/list
  Future<ResponseModel> getNotificationList({
    required int page,
    required int limit,
    bool showLoader = false,
  }) async {
    final api = ApiWrapper();
    final headers = Utility.commonHeader(isDefaultAuthorizationKeyAdd: true);

    final String url = 'application/notifications/list';
    final Map<String, dynamic> data = {
      "page": page,
      "limit": limit,
    };

    try {
      final res = await api.makeRequest(
        url,
        Request.post,
        data,
        showLoader,
        headers,
        isTokenRequired: true,
      );
      return res;
    } catch (e) {
      return ResponseModel(
        data: '{"Message": "Error fetching notifications: $e"}',
        hasError: true,
        statusCode: 500,
      );
    }
  }
}
