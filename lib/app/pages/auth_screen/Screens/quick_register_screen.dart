import 'dart:io';
import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class QuickRegisterScreen extends StatelessWidget {
  const QuickRegisterScreen({super.key});

  void _showImagePickerSheet(BuildContext context, AuthController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Profile Photo",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        controller.pickQuickDriverPhoto(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 36, color: ColorsValue.appColor),
                            const SizedBox(height: 8),
                            const Text("Camera", style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        controller.pickQuickDriverPhoto(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_rounded, size: 36, color: ColorsValue.appColor),
                            const SizedBox(height: 8),
                            const Text("Gallery", style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Driver Registration",
          ),
          body: SafeArea(
            child: Form(
              key: controller.quickRegisterKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                children: [
                  Image.asset(
                    AssetConstants.bam_bam_driver,
                    height: Dimens.fifty,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Driver Registration",
                    style: Styles.txtBlackColorBold32,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Enter your basic details to create an Individual Driver account",
                    style: Styles.txtDrakBulyColorw40014,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // ─── Profile Photo Upload Box ───
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showImagePickerSheet(context, controller),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: controller.quickDriverPhotoPath != null
                                    ? ColorsValue.appColor
                                    : Colors.grey.shade300,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: controller.quickDriverPhotoPath != null
                                ? ClipOval(
                                    child: Image.file(
                                      File(controller.quickDriverPhotoPath!),
                                      fit: BoxFit.cover,
                                      width: 110,
                                      height: 110,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Add Photo *",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: ColorsValue.appColor,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _showImagePickerSheet(context, controller),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorsValue.appColor,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      "Tap to upload profile photo",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ─── Driver Name ───
                  CustomTextFormField(
                    style: Styles.txtBlackColorW50016,
                    hintText: "Enter full name",
                    isBorder: true,
                    isTitle: true,
                    title: "Driver Name *",
                    hintStyle: Styles.txtG7Colors50016,
                    titleStyle: Styles.txtG6ColorW40014,
                    textEditingController: controller.quickNameController,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter your full name";
                      }
                      if (value.trim().length < 3) {
                        return "Name must be at least 3 characters";
                      }
                      return null;
                    },
                    onChanged: (_) => controller.update(),
                  ),

                  const SizedBox(height: 20),

                  // ─── Mobile Number ───
                  CustomTextFormField(
                    style: Styles.txtBlackColorW50016,
                    hintText: "Enter 10-digit mobile number",
                    isBorder: true,
                    isTitle: true,
                    title: "Mobile Number *",
                    hintStyle: Styles.txtG7Colors50016,
                    titleStyle: Styles.txtG6ColorW40014,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    textEditingController: controller.quickMobileController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter mobile number";
                      }
                      if (value.trim().length != 10) {
                        return "Please enter a valid 10-digit mobile number";
                      }
                      return null;
                    },
                    onChanged: (_) => controller.update(),
                  ),

                  const SizedBox(height: 20),

                  // ─── Email (Optional) ───
                  CustomTextFormField(
                    style: Styles.txtBlackColorW50016,
                    hintText: "Enter email address (optional)",
                    isBorder: true,
                    isTitle: true,
                    title: "Email Address (Optional)",
                    hintStyle: Styles.txtG7Colors50016,
                    titleStyle: Styles.txtG6ColorW40014,
                    textEditingController: controller.quickEmailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty && !GetUtils.isEmail(value.trim())) {
                        return "Please enter a valid email address";
                      }
                      return null;
                    },
                    onChanged: (_) => controller.update(),
                  ),

                  const SizedBox(height: 35),

                  // ─── Continue Button ───
                  CustomButton(
                    onPressed: controller.isQuickRegistering
                        ? null
                        : () {
                            if (controller.quickRegisterKey.currentState?.validate() ?? false) {
                              controller.quickRegister();
                            }
                          },
                    text: controller.isQuickRegistering ? "Sending OTP..." : "Continue",
                    textStyle: Styles.txtBlackColorW50016,
                    isBorder: false,
                    isColor: true,
                    backgroundColor: ColorsValue.appColor,
                  ),

                  const SizedBox(height: 24),

                  // ─── Back to Login ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: Styles.txtDrakBulyColorw40014,
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Text(
                          "Log in",
                          style: Styles.txtBlackColorW50016.copyWith(
                            color: ColorsValue.appColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
