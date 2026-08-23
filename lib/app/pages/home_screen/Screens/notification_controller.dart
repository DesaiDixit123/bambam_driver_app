import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:bam_bam_driver/domain/usecases/notification_usecases.dart';

class NotificationController extends GetxController {
  final NotificationUsecases notificationUsecases;
  NotificationController(this.notificationUsecases);

  List<NotificationModel> notifications = [];
  int currentPage = 1;
  int limit = 20;
  bool isLoading = false;
  bool isMoreLoading = false;
  bool hasMoreData = true;

  ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (hasMoreData && !isMoreLoading && !isLoading) {
        loadMoreNotifications();
      }
    }
  }

  Future<void> fetchNotifications({bool showLoader = true}) async {
    if (showLoader) {
      isLoading = true;
    }
    currentPage = 1;
    hasMoreData = true;
    update();

    final response = await notificationUsecases.getNotificationList(
      page: currentPage,
      limit: limit,
      showLoader: false,
    );

    isLoading = false;
    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);
        Utility.showMessage(body['Message'] ?? 'Failed to fetch notifications', MessageType.error, null, 'OK');
      } catch (_) {
        Utility.showMessage('Failed to fetch notifications', MessageType.error, null, 'OK');
      }
      update();
      return;
    }

    try {
      final body = jsonDecode(response.data);
      if (body['IsSuccess'] == true && body['Data'] != null) {
        final data = body['Data'];
        List dataList = [];
        if (data is List) {
          dataList = data;
        } else if (data is Map && data['notifications'] is List) {
          dataList = data['notifications'];
        }
        notifications = dataList.map((e) => NotificationModel.fromJson(e)).toList();
        if (dataList.length < limit) {
          hasMoreData = false;
        }
      } else {
        notifications = [];
        hasMoreData = false;
      }
    } catch (e) {
      notifications = [];
      hasMoreData = false;
    }
    update();
  }

  Future<void> loadMoreNotifications() async {
    isMoreLoading = true;
    update();

    final response = await notificationUsecases.getNotificationList(
      page: currentPage + 1,
      limit: limit,
      showLoader: false,
    );

    isMoreLoading = false;
    if (response.hasError) {
      update();
      return;
    }

    try {
      final body = jsonDecode(response.data);
      if (body['IsSuccess'] == true && body['Data'] != null) {
        final data = body['Data'];
        List dataList = [];
        if (data is List) {
          dataList = data;
        } else if (data is Map && data['notifications'] is List) {
          dataList = data['notifications'];
        }
        if (dataList.isEmpty) {
          hasMoreData = false;
        } else {
          notifications.addAll(dataList.map((e) => NotificationModel.fromJson(e)).toList());
          currentPage++;
          if (dataList.length < limit) {
            hasMoreData = false;
          }
        }
      } else {
        hasMoreData = false;
      }
    } catch (e) {
      hasMoreData = false;
    }
    update();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
