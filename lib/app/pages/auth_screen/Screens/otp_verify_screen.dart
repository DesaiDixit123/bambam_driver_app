import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerifyScreen extends StatelessWidget {
  const OtpVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "",
            isVisible: true,
          ),
          body: Form(
            key: controller.otpKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: Dimens.edgeInsets20,
              children: [
                Text(
                  "otp_very".tr,
                  style: Styles.txtBlackColorBold32,
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight5,
                Text(
                  "Enter OTP send to +91 ${controller.logainMobileNumberController.text} to continue login to your account",
                  textAlign: TextAlign.center,
                  style: Styles.txtG5ColorsW40016,
                ),

                // ✅ Show received OTP for debugging
                // if (controller.receivedOtp.isNotEmpty) ...[
                //   Dimens.boxHeight10,
                //   Text(
                //     "OTP: ${controller.receivedOtp}",
                //     textAlign: TextAlign.center,
                //     style: Styles.txtGreenColorW60014.copyWith(
                //       fontWeight: FontWeight.bold,
                //       color: Colors.green,
                //     ),
                //   ),
                // ],
                Dimens.boxHeight90,
                SvgPicture.asset(AssetConstants.otp),
                Dimens.boxHeight30,
                Text("otp".tr, style: Styles.txtG6ColorW40014),
                Dimens.boxHeight10,

                // PIN FIELD
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  autoFocus: true,
                  hintCharacter: "0",
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    activeColor: ColorsValue.borderColors,
                    selectedColor: ColorsValue.borderColors,
                    inactiveColor: ColorsValue.borderColors,
                    errorBorderColor: Colors.red,
                    selectedFillColor: ColorsValue.whiteColor,
                    inactiveFillColor: ColorsValue.whiteColor,
                    activeFillColor: ColorsValue.whiteColor,
                    borderWidth: 1,
                    borderRadius: BorderRadius.circular(Dimens.twenty),
                    fieldHeight: Get.width / 8,
                    fieldWidth: Get.width / 8,
                  ),
                  cursorColor: ColorsValue.appColor,
                  enableActiveFill: true,
                  keyboardType: TextInputType.number,
                  errorTextMargin: const EdgeInsets.only(top: 20),
                  errorTextSpace: 25,
                  boxShadows: const [
                    BoxShadow(
                      offset: Offset(0, 1),
                      color: Colors.black12,
                      blurRadius: 2,
                    ),
                  ],
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Enter Otp".tr;
                    } else if (value.length != 6) {
                      return "Enter Valid Otp".tr;
                    } else {
                      return null;
                    }
                  },
                  onCompleted: (pin) {
                    controller.code = pin;
                  },
                  onChanged: (value) {
                    debugPrint(value);
                  },
                  beforeTextPaste: (text) {
                    debugPrint("Allowing to paste $text");
                    return true;
                  },
                ),

                Dimens.boxHeight36,
                CustomButton(
                  onPressed: () {
                    if (controller.otpKey.currentState!.validate()) {
                      controller.driverVerifyOtp();
                    }
                  },
                  text: "verify".tr,
                  textStyle: Styles.txtBlackColorW50016,
                  isBorder: false,
                  isColor: true,
                  backgroundColor: ColorsValue.appColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
