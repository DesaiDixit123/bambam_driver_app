import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Trip Tracking",
          ),
          backgroundColor: ColorsValue.appBg,
          body: Form(
            key: controller.otpKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: Dimens.edgeInsets20,
              children: [
                Text(
                  "OTP".tr,
                  style: Styles.txtBlackColorBold32,
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight5,
                Text(
                  "Enter OTP From Customer continue your trip".tr,
                  textAlign: TextAlign.center,
                  style: Styles.txtG5ColorsW40014,
                ),
                Dimens.boxHeight90,
                SvgPicture.asset(AssetConstants.otp),
                Dimens.boxHeight30,
                Text("otp".tr, style: Styles.txtG6ColorW40014),
                Dimens.boxHeight10,
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
             

// Continue button:
CustomButton(
  onPressed: () async {
    if (controller.otpKey.currentState!.validate()) {
      final otp = controller.code.trim();
      await controller.verifyPickupOtp(otp: otp);
      // controller.verifyPickupOtp will navigate to VehicalMiterScreen on success
    }
  },
  text: "Continue".tr,
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
