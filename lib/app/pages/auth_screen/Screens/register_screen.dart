import 'dart:io';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/app/widgets/droup_down_widgets.dart' show DroupDownButtonWigeat;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      initState: (state) {
        final controller = Get.find<AuthController>();
        controller.fetchRegisterMasters();
      },
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "Driver Registration",
          ),
          bottomSheet: Padding(
            padding: Dimens.edgeInsets20_30_20_30,
            child: controller.isRegistering
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    onPressed: () async {
                      await controller.submitRegistration();
                    },
                    text: "Register".tr,
                    textStyle: Styles.txtBlackColorW50016,
                    isBorder: false,
                    isColor: true,
                    backgroundColor: ColorsValue.appColor,
                  ),
          ),
          body: Form(
            key: controller.registerKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
              children: [
                // Title and description
                Text(
                  "Create an Account",
                  style: Styles.txtBlackColorBold32,
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight10,
                Text(
                  "Please fill out the form below to register as an individual driver.",
                  style: Styles.txtDrakBulyColorw40014,
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight30,

                // Driver Image and DL Image row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Driver Image *", style: Styles.txtG6ColorW40014),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: controller.pickDriverPhoto,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: controller.driverPhotoPath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(controller.driverPhotoPath!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 120,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image, color: Colors.grey.shade400, size: 36),
                                        const SizedBox(height: 4),
                                        Text("Upload Image", style: Styles.txtG7Colors50016),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("DL Image *", style: Styles.txtG6ColorW40014),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: controller.pickDlPhoto,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: controller.dlPhotoPath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(controller.dlPhotoPath!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 120,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.badge, color: Colors.grey.shade400, size: 36),
                                        const SizedBox(height: 4),
                                        Text("Upload DL Image", style: Styles.txtG7Colors50016),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Dimens.boxHeight20,

                // Driver Name
                CustomTextFormField(
                  style: Styles.txtBlackColorW50016,
                  hintText: "Enter Driver Name",
                  isBorder: true,
                  isTitle: true,
                  textEditingController: controller.registerNameController,
                  isCompulsory: true,
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return "Driver name must be at least 3 characters";
                    }
                    return null;
                  },
                  title: "Driver Name",
                  hintStyle: Styles.txtG7Colors50016,
                  titleStyle: Styles.txtG6ColorW40014,
                ),
                Dimens.boxHeight16,

                // Mobile Number
                CustomTextFormField(
                  style: Styles.txtBlackColorW50016,
                  hintText: "Enter 10 digit Mobile No.",
                  isBorder: true,
                  isTitle: true,
                  textEditingController: controller.registerMobileController,
                  keyboardType: TextInputType.phone,
                  isCompulsory: true,
                  validator: (value) {
                    if (value == null || !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                      return "Enter valid 10-digit mobile number";
                    }
                    return null;
                  },
                  title: "Mobile No.",
                  hintStyle: Styles.txtG7Colors50016,
                  titleStyle: Styles.txtG6ColorW40014,
                ),
                Dimens.boxHeight16,

                // Date of Birth
                CustomTextFormField(
                  hintText: "Select Date Of Birth",
                  isBorder: true,
                  isTitle: true,
                  readOnly: true,
                  textEditingController: controller.registerDobController,
                  title: "Date of Birth",
                  suffixIcon: IconButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // default to 18 years ago
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        controller.registerDobController.text =
                            picked.toIso8601String().split('T').first;
                        controller.update();
                      }
                    },
                    icon: Icon(Icons.calendar_month_outlined, color: ColorsValue.txtBlackColor),
                  ),
                  isCompulsory: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please select Date of Birth";
                    }
                    return null;
                  },
                ),
                Dimens.boxHeight16,

                // DL Number
                CustomTextFormField(
                  style: Styles.txtBlackColorW50016,
                  hintText: "Enter DL Number",
                  isBorder: true,
                  isTitle: true,
                  textEditingController: controller.registerDlNumberController,
                  isCompulsory: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter driving license number";
                    }
                    return null;
                  },
                  title: "DL Number",
                  hintStyle: Styles.txtG7Colors50016,
                  titleStyle: Styles.txtG6ColorW40014,
                ),
                Dimens.boxHeight16,

                // DL Issue Date
                CustomTextFormField(
                  hintText: "Select DL Issue Date",
                  isBorder: true,
                  isTitle: true,
                  readOnly: true,
                  textEditingController: controller.registerDlIssueController,
                  title: "DL Issue Date",
                  suffixIcon: IconButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        controller.registerDlIssueController.text =
                            picked.toIso8601String().split('T').first;
                        controller.update();
                      }
                    },
                    icon: Icon(Icons.calendar_month_outlined, color: ColorsValue.txtBlackColor),
                  ),
                  isCompulsory: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Select driving license issue date";
                    }
                    return null;
                  },
                ),
                Dimens.boxHeight16,

                // DL Validity Date
                CustomTextFormField(
                  hintText: "Select DL Expiry Date",
                  isBorder: true,
                  isTitle: true,
                  readOnly: true,
                  textEditingController: controller.registerDlExpiryController,
                  title: "DL Validity",
                  suffixIcon: IconButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2050),
                      );
                      if (picked != null) {
                        controller.registerDlExpiryController.text =
                            picked.toIso8601String().split('T').first;
                        controller.update();
                      }
                    },
                    icon: Icon(Icons.calendar_month_outlined, color: ColorsValue.txtBlackColor),
                  ),
                  isCompulsory: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Select driving license validity date";
                    }
                    return null;
                  },
                ),
                Dimens.boxHeight16,

                // State Selection
                DroupDownButtonWigeat<String>(
                  hintText: "Select State",
                  isTitle: true,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                  items: controller.stateList,
                  value: controller.selectedRegisterState,
                  onChanged: (newValue) {
                    controller.selectedRegisterState = newValue ?? "";
                    controller.update();
                  },
                  textStyle: Styles.txtBlackColorW50016,
                  isCompulsory: true,
                  title: "State",
                  hintStyle: Styles.txtG7Colors50016,
                  titleStyle: Styles.txtG6ColorW40014,
                  isBorder: true,
                ),
                Dimens.boxHeight16,

                // City Selection
                DroupDownButtonWigeat<String>(
                  hintText: "Select City",
                  isTitle: true,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                  items: controller.registerCityList,
                  value: controller.selectedRegisterCity,
                  onChanged: (newValue) {
                    controller.selectedRegisterCity = newValue ?? "";
                    controller.update();
                  },
                  textStyle: Styles.txtBlackColorW50016,
                  isCompulsory: true,
                  title: "City",
                  hintStyle: Styles.txtG7Colors50016,
                  titleStyle: Styles.txtG6ColorW40014,
                  isBorder: true,
                ),
                Dimens.boxHeight16,

                // Address (optional)
                CustomTextFormField(
                  style: Styles.txtBlackColorW50016,
                  hintText: "Enter Address",
                  isBorder: true,
                  isTitle: true,
                  textEditingController: controller.registerAddressController,
                  title: "Address",
                  hintStyle: Styles.txtG7Colors50016,
                  titleStyle: Styles.txtG6ColorW40014,
                ),
                Dimens.boxHeight20,

                // Languages Known Multi-select ChoiceChips
                Text("Language Known *", style: Styles.txtG6ColorW40014),
                const SizedBox(height: 8),
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
                      selectedColor: ColorsValue.appColor,
                      onSelected: (_) {
                        controller.toggleLanguage(id);
                      },
                    );
                  }).toList(),
                ),
                Dimens.boxHeight20,

                // Vehicle types operated ChoiceChips
                Text("Select Types of Vehicles Driver Can Operate *", style: Styles.txtG6ColorW40014),
                const SizedBox(height: 8),
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
                      selectedColor: ColorsValue.appColor,
                      onSelected: (_) {
                        controller.toggleVehicle(id);
                      },
                    );
                  }).toList(),
                ),
                Dimens.boxHeight36,

              ],
            ),
          ),
        );
      },
    );
  }
}
