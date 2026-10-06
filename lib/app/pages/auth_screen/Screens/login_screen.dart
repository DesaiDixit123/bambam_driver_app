import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      initState: (state) {
        var controller = Get.find<AuthController>();
        controller.initializeFieldListeners();
      },
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          body: SafeArea(
            child: Form(
              key: controller.singUpKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: Dimens.edgeInsets20,

                children: [
                  Image.asset(
                    AssetConstants.bam_bam_driver,
                    height: Dimens.sixty,
                  ),
                  Dimens.boxHeight40,
                  Text(
                    "driver_login".tr,
                    style: Styles.txtBlackColorBold32,
                    textAlign: TextAlign.center,
                  ),
                  Dimens.boxHeight4,
                  Text(
                    "logain_account".tr,
                    style: Styles.txtDrakBulyColorw40014,
                    textAlign: TextAlign.center,
                  ),

                  Dimens.boxHeight57,
                  SvgPicture.asset(AssetConstants.logain_BG),

                  Dimens.boxHeight24,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: 'individual',
                        groupValue: controller.loginType,
                        activeColor: ColorsValue.appColor,
                        onChanged: (value) {
                          controller.loginType = value!;
                          controller.update();
                        },
                      ),
                      Text("Individual".tr, style: Styles.txtBlackColorW50016),
                      SizedBox(width: Dimens.twenty),
                      Radio<String>(
                        value: 'company',
                        groupValue: controller.loginType,
                        activeColor: ColorsValue.appColor,
                        onChanged: (value) {
                          controller.loginType = value!;
                          controller.update();
                        },
                      ),
                      Text("Company".tr, style: Styles.txtBlackColorW50016),
                    ],
                  ),

                  // CustomInternationalPhoneFild(
                  //   hintStyle: Styles.txtG5ColorsW40016,
                  //   radius: Dimens.sixteen,
                  //   fillColor: ColorsValue.whiteColor,
                  //   hintText: 'Phone Number',
                  //   text: ''.tr,
                  //   initialvalue: PhoneNumber(
                  //     isoCode: PhoneNumber.getISO2CodeByPrefix(
                  //       controller.dailcode,
                  //     ),
                  //   ),
                  //   onInputChanged: (PhoneNumber number) {
                  //     controller.dailcode = number.dialCode ?? '';
                  //   },
                  //   oninitialValidation: (bool value) {
                  //     controller.isValid = value;
                  //     controller.update();
                  //   },
                  //   textEditingController:
                  //       controller.logainMobileNumberController,
                  //   validation: (value) {
                  //     if (value!.isEmpty) {
                  //       return "enteryournumber".tr;
                  //     } else if (!controller.isValid) {
                  //       return "enter_valid_phone_number".tr;
                  //     }
                  //     return null;
                  //   },
                  // ),
                  Dimens.boxHeight31,
                  CustomTextFormField(
                    style: Styles.txtBlackColorW50016,
                    hintText: "enter_phone_no".tr,
                    //filled: true,
                    isBorder: true,
                    isTitle: true,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    textEditingController:
                        controller.logainMobileNumberController,
                    onChanged: (vaule) {
                      controller.update();
                    },
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Enter Phone No";
                      }
                      if (value.trim().length != 10) {
                        return "Please enter a valid 10-digit Phone No";
                      }
                      return null;
                    },
                    title: "phone_no".tr,
                    hintStyle: Styles.txtG7Colors50016,
                    titleStyle: Styles.txtG6ColorW40014,
                  ),
                  Dimens.boxHeight36,
                  CustomButton(
                    onPressed: () {
    if (controller.logainMobileNumberController.text.isNotEmpty) {
      // call presenter to send otp
      controller.driverSendOtp();
    }
  },
                    text: "Log in".tr,
                    textStyle:
                        controller.logainMobileNumberController.text.isNotEmpty
                        ? Styles.txtBlackColorW50016
                        : Styles.txtG7Colors50016,
                    isBorder: false,
                    isColor: true,
                    backgroundColor:
                        controller.logainMobileNumberController.text.isNotEmpty
                        ? ColorsValue.appColor
                        : ColorsValue.bulycolorsCB,
                  ),
                  Dimens.boxHeight24,
                  if (controller.loginType == 'individual') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ".tr,
                          style: Styles.txtDrakBulyColorw40014,
                        ),
                        GestureDetector(
                          onTap: RouteManagement.gotoQuickRegisterScreen,
                          child: Text(
                            "Register here".tr,
                            style: Styles.txtBlackColorW50016.copyWith(
                              color: ColorsValue.appColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight24,
                  ],
                ],
              ),

            ),
          ),
        );
      },
    );
  }
}
