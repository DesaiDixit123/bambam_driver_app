import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'notification_controller.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "Notifications",
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () =>
                      controller.fetchNotifications(showLoader: false),
                  child: controller.notifications.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: Get.height * 0.3),
                            Center(
                              child: Text(
                                "No Notifications Found",
                                style: Styles.txtG7Colors40014,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: controller.scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount:
                              controller.notifications.length +
                              (controller.isMoreLoading ? 1 : 0),
                          padding: Dimens.edgeInsets20,
                          itemBuilder: (context, index) {
                            if (index == controller.notifications.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final notification =
                                controller.notifications[index];
                            return InkWell(
                              onTap: () {
                                if (notification.bookingId != null &&
                                    notification.bookingId!.isNotEmpty) {
                                  final bool isCompleted = notification.event
                                          ?.toLowerCase()
                                          .contains("completed") ??
                                      false;
                                  final bool isCancelled = notification.event
                                          ?.toLowerCase()
                                          .contains("cancel") ??
                                      false;
                                  RouteManagement.gotoTripDetilesScreen(
                                    isComplectTrip: isCompleted || isCancelled,
                                    tripId: notification.bookingId,
                                  );
                                }
                              },
                              child: Column(
                                children: [
                                  Row(
                                    spacing: Dimens.ten,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            Dimens.fifty,
                                          ),
                                          border: Border.all(
                                            color: ColorsValue.borderColors,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: Dimens.edgeInsets8,
                                          child: Image.asset(
                                            AssetConstants.car_Fill,
                                            height: Dimens.sixteen,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notification.title ??
                                                        "Notification",
                                                    style: Styles
                                                        .txtBlackColorW50016,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  notification.formattedDate,
                                                  style: Styles.txtG7Colors40014
                                                      .copyWith(
                                                        fontSize: Dimens.twelve,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              notification.description ?? "",
                                              style: Styles.txtG5ColorsW40014,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Dimens.boxHeight20,
                                ],
                              ),
                            );
                          },
                        ),
                ),
        );
      },
    );
  }
}
