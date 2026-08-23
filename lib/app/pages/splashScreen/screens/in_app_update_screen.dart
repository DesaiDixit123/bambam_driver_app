import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:lottie/lottie.dart';

class InAppUpdateScreen extends StatelessWidget {
  const InAppUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      initState: (state) {
        var controller = Get.find<SplashController>();
        controller.appUrl = Get.arguments ?? "";
      },
      builder: (controller) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              exit(0);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    Utility.launchLinkURL(controller.appUrl ?? "");
                  },
                  child: Container(
                    height: Dimens.fourtyFive,
                    margin: Dimens.edgeInsets20_00_20_00,
                    color: ColorsValue.appColor,
                    alignment: Alignment.center,
                    child: Text("Update now", style: Styles.whiteColorW60016),
                  ),
                ),
                InkWell(
                  onTap: () {
                    exit(0);
                  },
                  child: Container(
                    height: Dimens.fourtyFive,
                    margin: Dimens.edgeInsets20_00_20_00,
                    alignment: Alignment.center,
                    child: Text(
                      "No, Thanks! Close the app",
                      style: Styles.black50014,
                    ),
                  ),
                ),
                Dimens.boxHeight20,
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Lottie.asset(
                  AssetConstants.app_update_lottie,
                  fit: BoxFit.cover,
                  repeat: true,
                  width: double.maxFinite,
                  reverse: true,
                ),
                Dimens.boxHeight30,
                Padding(
                  padding: Dimens.edgeInsets20_00_20_00,
                  child: Text(
                    "New update is available",
                    style: Styles.txtBlackColorW70020,
                  ),
                ),
                Dimens.boxHeight30,
                Padding(
                  padding: Dimens.edgeInsets20_00_20_00,
                  child: Text(
                    "The current version of this application is no longer supported. A new version of the app is available. Please update to continue.",
                    textAlign: TextAlign.center,
                    style: Styles.black50014,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
