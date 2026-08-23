import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ApprovalPendingScreen extends StatelessWidget {
  const ApprovalPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsValue.appBg,
      body: SafeArea(
        child: Padding(
          padding: Dimens.edgeInsets20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.hourglass_empty_rounded,
                size: Dimens.hundred,
                color: ColorsValue.appColor,
              ),
              Dimens.boxHeight32,
              Text(
                "approval_pending".tr,
                style: Styles.txtBlackColorBold32,
                textAlign: TextAlign.center,
              ),
              Dimens.boxHeight16,
              Text(
                "approval_pending_msg".tr,
                style: Styles.txtG5ColorsW40016,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              CustomButton(
                onPressed: () {
                  Get.offAllNamed(Routes.loginScreen);
                },
                text: "back_to_login".tr,
                textStyle: Styles.txtBlackColorW50016,
                isBorder: false,
                isColor: true,
                backgroundColor: ColorsValue.appColor,
              ),
              Dimens.boxHeight24,
            ],
          ),
        ),
      ),
    );
  }
}
