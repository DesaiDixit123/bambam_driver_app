// personal_detiles_screen.dart
import 'dart:io';

import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/app/widgets/droup_down_widgets.dart' show DroupDownButtonWigeat;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class PersonalDetilesScreen extends StatelessWidget {
  const PersonalDetilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        return Scaffold(
          bottomSheet: Padding(
            padding: Dimens.edgeInsets20_30_20_30,
            child: CustomButton(
              onPressed: () async {
                if (controller.saveKey.currentState!.validate()) {
                  await controller.updateProfile();
                  if (!controller.isUpdating) {
                    Get.back();
                  }
                }
              },
              text: "Save".tr,
              textStyle: Styles.txtBlackColorW50016,
              isBorder: false,
              isColor: true,
              backgroundColor: ColorsValue.appColor,
            ),
          ),
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "Personal Information",
          ),
          body: controller.isLoadingProfile
              ? Center(child: Utility.loaderWidget())
              : Form(
                  key: controller.saveKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    padding: Dimens.edgeInsets20,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            // show driver photo: either local picked file, server url preview, or placeholder
                            ClipRRect(
                              borderRadius: BorderRadius.circular(Dimens.hundred),
                              child: controller.driverPhotoPath != null
                                  ? Image.file(File(controller.driverPhotoPath!), height: Dimens.hundred, width: Dimens.hundred, fit: BoxFit.cover)
                                  : (controller.driverPhotoUrl.isNotEmpty
                                      ? Image.network(controller.driverPhotoUrl, height: Dimens.hundred, width: Dimens.hundred, fit: BoxFit.cover)
                                      : Image.asset(AssetConstants.person, height: Dimens.hundred, width: Dimens.hundred)),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () async {
                                  await controller.pickDriverPhoto();
                                },
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.asset(
                                    AssetConstants.ic_edit_Imge,
                                    height: Dimens.twentyFour,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Dimens.boxHeight20,
                      CustomTextFormField(
                        style: Styles.txtBlackColorW50016,
                        hintText: "enter_full_name".tr,
                        isBorder: true,
                        isTitle: true,
                        textEditingController: controller.fullNameController,
                        onChanged: (vaule) {
                          controller.update();
                        },
                        isCompulsory: true,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "enter_full_name".tr;
                          }
                          return null;
                        },
                        title: "full_name".tr,
                        hintStyle: Styles.txtG7Colors50016,
                        titleStyle: Styles.txtG6ColorW40014,
                      ),
                      Dimens.boxHeight16,
                      CustomTextFormField(
                        style: Styles.txtBlackColorW50016,
                        hintText: "enter_email".tr,
                        isBorder: true,
                        isTitle: true,
                        textEditingController: controller.emailController,
                        onChanged: (vaule) {
                          controller.update();
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "enter_email".tr;
                          }
                          return null;
                        },
                        title: "email".tr,
                        hintStyle: Styles.txtG7Colors50016,
                        titleStyle: Styles.txtG6ColorW40014,
                      ),
                      Dimens.boxHeight16,
                      CustomTextFormField(
                        hintText: "enter_phone_no".tr,
                        isBorder: true,
                        isTitle: true,
                        style: Styles.txtBlackColorW50016,
                        textEditingController: controller.phoneNumberController,
                        onChanged: (vaule) {
                          controller.update();
                        },
                        isCompulsory: true,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "enter_phone_no".tr;
                          }
                          return null;
                        },
                        title: "phone_no".tr,
                        hintStyle: Styles.txtG7Colors50016,
                        titleStyle: Styles.txtG6ColorW40014,
                      ),
                      Dimens.boxHeight16,
                      DroupDownButtonWigeat<String>(
                        hintText: "select_city".tr,
                        isTitle: true,
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                        items: controller.cityList,
                        value: controller.selectedCity,
                        onChanged: (newValue) {
                          controller.selectedCity = newValue ?? "";
                          controller.update();
                        },
                        textStyle: Styles.txtBlackColorW50016,
                        isCompulsory: true,
                        title: "select_city".tr,
                        hintStyle: Styles.txtG7Colors50016,
                        titleStyle: Styles.txtG6ColorW40014,
                        isBorder: true,
                      ),
                      Dimens.boxHeight16,
                      CustomTextFormField(
                        hintText: "enter_code".tr,
                        isBorder: true,
                        isTitle: true,
                        style: Styles.txtBlackColorW50016,
                        textEditingController: controller.pinCodeController,
                        onChanged: (vaule) {
                          controller.update();
                        },
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "enter_code".tr;
                          }
                          return null;
                        },
                        title: "zip_code".tr,
                        hintStyle: Styles.txtG7Colors50016,
                        titleStyle: Styles.txtG6ColorW40014,
                      ),

                      // ---------- DOB ----------
                      Dimens.boxHeight16,
                      CustomTextFormField(
                        hintText: "select".tr,
                        isBorder: true,
                        isTitle: true,
                        readOnly: true,
                        textEditingController: controller.dobController,
                        title: "Date of Birth".tr,
                        suffixIcon: IconButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: controller.dobController.text.isNotEmpty
                                  ? DateTime.parse(controller.dobController.text)
                                  : DateTime(1990),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              controller.dobController.text = picked.toIso8601String().split('T').first;
                              controller.update();
                            }
                          },
                          icon: Icon(Icons.calendar_month_outlined, color: ColorsValue.txtBlackColor),
                        ),
                        validator: (value) {
                          return null;
                        },
                      ),

                      // ---------- DL Number ----------
                      Dimens.boxHeight16,
                      CustomTextFormField(
                        hintText: "Enter DL Number".tr,
                        isBorder: true,
                        isTitle: true,
                        textEditingController: controller.dlNumberController,
                        title: "DL Number".tr,
                      ),

                      // ---------- DL issue & expiry ----------
                      Dimens.boxHeight16,
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              hintText: "select".tr,
                              isBorder: true,
                              isTitle: true,
                              readOnly: true,
                              textEditingController: controller.dlIssueController,
                              title: "DL issue date".tr,
                              suffixIcon: IconButton(
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: controller.dlIssueController.text.isNotEmpty
                                        ? DateTime.parse(controller.dlIssueController.text)
                                        : DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2050),
                                  );
                                  if (picked != null) {
                                    controller.dlIssueController.text = picked.toIso8601String().split('T').first;
                                    controller.update();
                                  }
                                },
                                icon: Icon(Icons.calendar_month_outlined, color: ColorsValue.txtBlackColor),
                              ),
                            ),
                          ),
                          Dimens.boxWidth10,
                          Expanded(
                            child: CustomTextFormField(
                              hintText: "select".tr,
                              isBorder: true,
                              isTitle: true,
                              readOnly: true,
                              textEditingController: controller.dlExpiryController,
                              title: "DL expiry date".tr,
                              suffixIcon: IconButton(
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: controller.dlExpiryController.text.isNotEmpty
                                        ? DateTime.parse(controller.dlExpiryController.text)
                                        : DateTime.now().add(const Duration(days: 365)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2050),
                                  );
                                  if (picked != null) {
                                    controller.dlExpiryController.text = picked.toIso8601String().split('T').first;
                                    controller.update();
                                  }
                                },
                                icon: Icon(Icons.calendar_month_outlined, color: ColorsValue.txtBlackColor),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // DL photo preview & pick
                      Dimens.boxHeight16,
                      Text("DL Photo", style: Styles.txtG6ColorW40014),
                      Dimens.boxHeight8,
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimens.twelve),
                                color: ColorsValue.l4CB,
                              ),
                              child: Center(
                                child: controller.dlPhotoPath != null
                                    ? Image.file(File(controller.dlPhotoPath!), fit: BoxFit.cover, width: double.infinity, height: 120)
                                    : (controller.dlPhotoUrl.isNotEmpty
                                        ? Image.network(controller.dlPhotoUrl, fit: BoxFit.cover, width: double.infinity, height: 120)
                                        : Text("No DL image")),
                              ),
                            ),
                          ),
                          Dimens.boxWidth10,
                          ElevatedButton(
                            onPressed: () async {
                              await controller.pickDlPhoto();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: ColorsValue.appColor),
                            child: Text("Upload".tr),
                          ),
                        ],
                      ),

                      // language multi-select chips
                      Dimens.boxHeight16,
                      Text("Languages Known", style: Styles.txtG6ColorW40014),
                      Dimens.boxHeight8,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.languagesList.map((lang) {
                          final id = lang['id']!;
                          final name = lang['name']!;
                          final selected = controller.selectedLanguageIds.contains(id);
                          return ChoiceChip(
                            label: Text(name),
                            selected: selected,
                            onSelected: (_) {
                              controller.toggleLanguage(id);
                            },
                          );
                        }).toList(),
                      ),

                      // vehicles multi-select chips
                      Dimens.boxHeight16,
                      Text("Vehicles you drive", style: Styles.txtG6ColorW40014),
                      Dimens.boxHeight8,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.vehiclesList.map((veh) {
                          final id = veh['id']!;
                          final name = veh['name']!;
                          final selected = controller.selectedVehicleIds.contains(id);
                          return ChoiceChip(
                            label: Text(name),
                            selected: selected,
                            onSelected: (_) {
                              controller.toggleVehicle(id);
                            },
                          );
                        }).toList(),
                      ),

                      // small spaces to finalize
                      Dimens.boxHeight36,
                      Dimens.boxHeight36,
                      Dimens.boxHeight36,
                    ],
                  ),
                ),
        );
      },
    );
  }
}
