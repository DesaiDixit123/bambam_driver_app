import 'dart:io';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:bam_bam_driver/app/widgets/droup_down_widgets.dart' show DroupDownButtonWigeat;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return "Personal Information";
      case 1:
        return "Driving License & Skills";
      case 2:
        return "Identity Documents (KYC)";
      case 3:
        return "Bank Details";
      case 4:
        return "Vehicle & Statutory Details";
      case 5:
        return "Vehicle Images";
      default:
        return "";
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return "Enter your basic contact details and current location.";
      case 1:
        return "Driving license verification, languages and operated vehicles.";
      case 2:
        return "Upload Aadhaar and PAN documents for verification.";
      case 3:
        return "Enter bank details for withdrawing ride earnings.";
      case 4:
        return "Vehicle specifications, sourcing, fuel type, and statutory documents.";
      case 5:
        return "Upload photos of your vehicle from all required angles.";
      default:
        return "";
    }
  }

  Widget _buildUploadBox({
    required String title,
    required String? imagePath,
    required VoidCallback onTap,
    required IconData icon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: Styles.txtG6ColorW40014),
            if (isRequired)
              const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 140,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: const Color(0xFFFF5C00), size: 30),
                      ),
                      const SizedBox(height: 8),
                      Text("Upload Document / Photo", style: Styles.txtG7Colors50016),
                      const SizedBox(height: 3),
                      Text("PDF, PNG, JPG accepted", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationField({
    required String title,
    required String hintText,
    required TextEditingController textController,
    required VoidCallback onVerify,
    required bool isVerified,
    required bool isVerifying,
    bool isCompulsory = true,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.characters,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: Styles.txtG6ColorW40014),
            if (isCompulsory)
              const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: textController,
                readOnly: readOnly,
                keyboardType: keyboardType,
                textCapitalization: textCapitalization,
                inputFormatters: inputFormatters,
                style: Styles.txtBlackColorW50016,
                validator: validator,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: Styles.txtG7Colors50016,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isVerified ? Colors.green.shade400 : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isVerified ? Colors.green.shade400 : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isVerified ? Colors.green.shade600 : ColorsValue.appColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isVerified ? Colors.green.shade600 : ColorsValue.appColor,
                  foregroundColor: isVerified ? Colors.white : Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: isVerifying ? null : onVerify,
                child: isVerifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVerified ? Icons.check_circle_rounded : Icons.verified_user_outlined,
                            size: 16,
                            color: isVerified ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isVerified ? "Verified" : "Verify",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isVerified ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String title,
    required String hintText,
    required TextEditingController textController,
    bool isCompulsory = true,
    bool isEditable = true,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final bool canEdit = isEditable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: Styles.txtG6ColorW40014),
            if (isCompulsory)
              const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: textController,
          readOnly: true,
          style: Styles.txtBlackColorW50016,
          onTap: canEdit
              ? () async {
                  final now = DateTime.now();
                  final currentText = textController.text.trim();
                  DateTime? parsedCurrent = parseDateHelper(currentText);

                  DateTime minDate = firstDate ?? DateTime(1950);
                  DateTime maxDate = lastDate ?? DateTime(2050);
                  DateTime startFrom = initialDate ?? parsedCurrent ?? now;
                  if (startFrom.isBefore(minDate)) startFrom = minDate;
                  if (startFrom.isAfter(maxDate)) startFrom = maxDate;

                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startFrom,
                    firstDate: minDate,
                    lastDate: maxDate,
                  );
                  if (picked != null) {
                    textController.text = formatDateToDdMmYyyy(picked);
                  }
                }
              : null,
          validator: isCompulsory
              ? (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please select $title";
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: Styles.txtG7Colors50016,
            filled: true,
            fillColor: canEdit ? Colors.white : Colors.grey.shade100,
            suffixIcon: Icon(
              Icons.calendar_month_outlined,
              color: canEdit ? Colors.black87 : Colors.grey.shade400,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorsValue.appColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchableBottomSheet({
    required BuildContext context,
    required String title,
    required List<dynamic> Function() listProvider,
    required TextEditingController searchController,
    required Function(dynamic) onSelect,
    required bool isMultiSelect,
    required bool Function(dynamic item) isSelected,
    required String Function(dynamic item) displayName,
    bool Function()? isLoadingProvider,
    VoidCallback? onDone,
  }) {
    searchController.clear();
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),
                // Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search...",
                      hintStyle: Styles.txtG7Colors50016,
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchController.clear();
                                setSheetState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ColorsValue.appColor, width: 1.5),
                      ),
                    ),
                    onChanged: (_) {
                      setSheetState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // List
                Expanded(
                  child: Builder(
                    builder: (ctx) {
                      if (isLoadingProvider != null && isLoadingProvider()) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: ColorsValue.appColor),
                          ),
                        );
                      }
                      final list = listProvider();
                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            "No results found",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (ctx, index) {
                          final item = list[index];
                          final name = displayName(item);
                          final selected = isSelected(item);
                          return ListTile(
                            title: Text(
                              name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                color: selected ? Colors.black : Colors.black87,
                              ),
                            ),
                            trailing: selected
                                ? Icon(Icons.check_circle, color: ColorsValue.appColor)
                                : (isMultiSelect
                                    ? Icon(Icons.circle_outlined, color: Colors.grey.shade400)
                                    : null),
                            onTap: () {
                              onSelect(item);
                              if (isMultiSelect) {
                                setSheetState(() {});
                              } else {
                                Get.back();
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                if (isMultiSelect)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsValue.appColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (onDone != null) onDone();
                        Get.back();
                      },
                      child: const Text(
                        "Done",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildRadioToggle({
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Styles.txtG6ColorW40014),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = opt == value;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => onChanged(opt),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? ColorsValue.appColor.withValues(alpha: 0.15) : Colors.white,
                      border: Border.all(
                        color: isSelected ? ColorsValue.appColor : Colors.grey.shade300,
                        width: isSelected ? 1.8 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.black : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      initState: (state) {
        final controller = Get.find<AuthController>();
        controller.fetchRegisterMasters();
      },
      builder: (controller) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            controller.goToPreviousStep();
          },
          child: Scaffold(
            backgroundColor: ColorsValue.appBg,
            appBar: AppBarWidget(
              onTapBack: () {
                controller.goToPreviousStep();
              },
              title: "Driver Registration",
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: (controller.isRegistering || controller.isCheckingMobile)
                    ? const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Row(
                        children: [
                          if (controller.currentRegisterStep > 0) ...[
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                                onPressed: controller.goToPreviousStep,
                                child: const Text(
                                  "Back",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorsValue.appColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                controller.goToNextStep();
                              },
                              child: Text(
                                controller.currentRegisterStep == 5
                                    ? "Submit Registration"
                                    : "Continue",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            body: Form(
              key: controller.registerKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 40),
                children: [
                  // Step Indicator Header
                  Row(
                    children: List.generate(6, (index) {
                      final isActive = index <= controller.currentRegisterStep;
                      return Expanded(
                        child: Container(
                          height: 5,
                          margin: EdgeInsets.only(right: index == 5 ? 0 : 6),
                          decoration: BoxDecoration(
                            color: isActive ? ColorsValue.appColor : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Step Name & Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorsValue.appColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Step ${controller.currentRegisterStep + 1} of 6",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStepTitle(controller.currentRegisterStep),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStepDescription(controller.currentRegisterStep),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // ----------------------------------------------------
                  // STEP 0: PERSONAL INFORMATION & LOCATION
                  // ----------------------------------------------------
                  if (controller.currentRegisterStep == 0) ...[
                    // Driver Photo
                    _buildUploadBox(
                      title: "Driver Profile Photo",
                      imagePath: controller.driverPhotoPath,
                      onTap: controller.pickDriverPhoto,
                      icon: Icons.person_add_alt_1_rounded,
                      isRequired: true,
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().length != 10) {
                          return "Enter valid 10-digit mobile number";
                        }
                        if (controller.mobileAlreadyExistsError != null) {
                          return controller.mobileAlreadyExistsError;
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
                          final now = DateTime.now();
                          DateTime initDate = now.subtract(const Duration(days: 365 * 18));
                          final currentDob = controller.registerDobController.text.trim();
                          if (currentDob.isNotEmpty) {
                            final parsed = parseDateHelper(currentDob);
                            if (parsed != null && parsed.isBefore(now)) {
                              initDate = parsed;
                            }
                          }
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: initDate,
                            firstDate: DateTime(1950),
                            lastDate: now,
                          );
                          if (picked != null) {
                            controller.registerDobController.text = formatDateToDdMmYyyy(picked);
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
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 15, color: Colors.orange.shade800),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            "Note: Please select the exact Date of Birth as mentioned on your Driving License.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF555555),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight20,

                    // Address Mode (GPS vs Manual)
                    Text("Address & Location *", style: Styles.txtG6ColorW40014),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              controller.setAddressSelectionType("current_location");
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: controller.addressSelectionType == "current_location"
                                    ? ColorsValue.appColor.withValues(alpha: 0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: controller.addressSelectionType == "current_location"
                                      ? ColorsValue.appColor
                                      : Colors.grey.shade300,
                                  width: controller.addressSelectionType == "current_location" ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.my_location_rounded,
                                    size: 16,
                                    color: controller.addressSelectionType == "current_location"
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Use Current Location",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: controller.addressSelectionType == "current_location"
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              controller.setAddressSelectionType("manual");
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: controller.addressSelectionType == "manual"
                                    ? ColorsValue.appColor.withValues(alpha: 0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: controller.addressSelectionType == "manual"
                                      ? ColorsValue.appColor
                                      : Colors.grey.shade300,
                                  width: controller.addressSelectionType == "manual" ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_location_alt_rounded,
                                    size: 16,
                                    color: controller.addressSelectionType == "manual"
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Enter Manually",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: controller.addressSelectionType == "manual"
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight14,

                    if (controller.addressSelectionType == "current_location") ...[
                      InkWell(
                        onTap: controller.isFetchingLocation ? null : controller.detectCurrentLocation,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ColorsValue.appColor, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (controller.isFetchingLocation)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Icon(Icons.gps_fixed_rounded, color: ColorsValue.appColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                controller.isFetchingLocation
                                    ? "Detecting Location..."
                                    : "Tap to Auto-Detect Location (GPS)",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Dimens.boxHeight12,

                      if (controller.registerAddressController.text.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "GPS Location Captured",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.registerAddressController.text,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                              ),
                            ],
                          ),
                        ),
                        Dimens.boxHeight12,
                      ],
                    ] else ...[
                      CustomTextFormField(
                        style: Styles.txtBlackColorW50016,
                        hintText: "Flat/House No., Building, Street",
                        isBorder: true,
                        isTitle: true,
                        textEditingController: controller.registerAddressController,
                        isCompulsory: true,
                        validator: (value) {
                          if (controller.addressSelectionType == "manual" &&
                              (value == null || value.trim().length < 5)) {
                            return "Please enter street address";
                          }
                          return null;
                        },
                        title: "Street Address",
                        hintStyle: Styles.txtG7Colors50016,
                        titleStyle: Styles.txtG6ColorW40014,
                      ),
                      Dimens.boxHeight14,

                      CustomTextFormField(
                        style: Styles.txtBlackColorW50016,
                        hintText: "Enter 6-digit Pincode",
                        isBorder: true,
                        isTitle: true,
                        textEditingController: controller.registerPinCodeController,
                        keyboardType: TextInputType.number,
                        isCompulsory: true,
                        validator: (value) {
                          if (controller.addressSelectionType == "manual" &&
                              (value == null || !RegExp(r'^[0-9]{6}$').hasMatch(value.trim()))) {
                            return "Enter valid 6-digit pincode";
                          }
                          return null;
                        },
                        title: "Pincode",
                        hintStyle: Styles.txtG7Colors50016,
                        titleStyle: Styles.txtG6ColorW40014,
                      ),
                      Dimens.boxHeight14,
                    ],

                    // State Selector (Searchable Bottom Sheet with All Indian States)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("State", style: Styles.txtG6ColorW40014),
                            const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () {
                            if (controller.statesList.isEmpty && !controller.isStatesLoading) {
                              controller.fetchStates();
                            }
                            _showSearchableBottomSheet(
                              context: context,
                              title: "Select State",
                              searchController: controller.stateSearchController,
                              listProvider: () => controller.filteredStates,
                              isLoadingProvider: () => controller.isStatesLoading,
                              isMultiSelect: false,
                              isSelected: (item) => controller.selectedRegisterState == item['name'],
                              displayName: (item) => item['name'] ?? '',
                              onSelect: (item) {
                                controller.onStateChanged(item['name'] ?? '', stateCode: item['code']);
                              },
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    controller.selectedRegisterState?.isNotEmpty == true
                                        ? controller.selectedRegisterState!
                                        : "Select State",
                                    style: controller.selectedRegisterState?.isNotEmpty == true
                                        ? Styles.txtBlackColorW50016
                                        : Styles.txtG7Colors50016,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.black87),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight16,

                    // City Selector (Searchable Bottom Sheet with Cities of selected State)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("City", style: Styles.txtG6ColorW40014),
                            const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () {
                            if (controller.selectedRegisterState == null || controller.selectedRegisterState!.isEmpty) {
                              Utility.showMessage("Please select State first", MessageType.error, null, "OK");
                              return;
                            }
                            if (controller.citiesList.isEmpty && !controller.isCitiesLoading) {
                              final found = controller.statesList.firstWhere(
                                (s) => (s['name'] ?? '').toLowerCase() == controller.selectedRegisterState!.toLowerCase(),
                                orElse: () => {'name': controller.selectedRegisterState!, 'code': ''},
                              );
                              if ((found['code'] ?? '').isNotEmpty) {
                                controller.fetchCitiesForState(found['code']!);
                              }
                            }
                            _showSearchableBottomSheet(
                              context: context,
                              title: "Select City (${controller.selectedRegisterState})",
                              searchController: controller.citySearchController,
                              listProvider: () => controller.filteredCities,
                              isLoadingProvider: () => controller.isCitiesLoading,
                              isMultiSelect: false,
                              isSelected: (item) => controller.selectedRegisterCity == item,
                              displayName: (item) => item.toString(),
                              onSelect: (item) {
                                controller.selectedRegisterCity = item.toString();
                                controller.update();
                              },
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    controller.selectedRegisterCity?.isNotEmpty == true
                                        ? controller.selectedRegisterCity!
                                        : "Select City",
                                    style: controller.selectedRegisterCity?.isNotEmpty == true
                                        ? Styles.txtBlackColorW50016
                                        : Styles.txtG7Colors50016,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.black87),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ----------------------------------------------------
                  // STEP 1: DRIVING LICENSE & SKILLS
                  // ----------------------------------------------------
                  if (controller.currentRegisterStep == 1) ...[
                    _buildUploadBox(
                      title: "Driving License Image",
                      imagePath: controller.dlPhotoPath,
                      onTap: controller.pickDlPhoto,
                      icon: Icons.badge_outlined,
                      isRequired: true,
                    ),
                    Dimens.boxHeight20,

                    _buildVerificationField(
                      title: "Driving License Number",
                      hintText: "e.g. GJ0120200012345",
                      textController: controller.registerDlNumberController,
                      isVerified: controller.isDlVerified,
                      isVerifying: controller.isDlVerifying,
                      onVerify: controller.verifyDL,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(16),
                      ],
                      onChanged: (val) {
                        if (controller.isDlVerified) {
                          controller.isDlVerified = false;
                          controller.update();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter driving license number";
                        }
                        return null;
                      },
                    ),
                    Dimens.boxHeight16,

                    _buildDatePickerField(
                      context: context,
                      title: "DL Issue Date",
                      hintText: "Select Issue Date",
                      textController: controller.registerDlIssueController,
                      isEditable: !controller.isDlVerified,
                      lastDate: DateTime.now(),
                    ),
                    Dimens.boxHeight16,

                    Builder(
                      builder: (ctx) {
                        DateTime expiryFirst = DateTime.now();
                        final issueText = controller.registerDlIssueController.text.trim();
                        if (issueText.isNotEmpty) {
                          final parsed = parseDateHelper(issueText);
                          if (parsed != null && parsed.isAfter(expiryFirst)) {
                            expiryFirst = parsed;
                          }
                        }
                        return _buildDatePickerField(
                          context: ctx,
                          title: "DL Validity / Expiry Date",
                          hintText: "Select Expiry Date",
                          textController: controller.registerDlExpiryController,
                          isEditable: !controller.isDlVerified,
                          initialDate: expiryFirst.add(const Duration(days: 365)),
                          firstDate: expiryFirst,
                        );
                      },
                    ),
                    Dimens.boxHeight20,

                    // Languages Known Selector (Searchable Multi-Select)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Languages Known", style: Styles.txtG6ColorW40014),
                            const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _showSearchableBottomSheet(
                            context: context,
                            title: "Select Languages Known",
                            searchController: controller.languageSearchController,
                            listProvider: () => controller.filteredLanguages,
                            isMultiSelect: true,
                            isSelected: (item) => controller.selectedLanguageIds.contains(item['id']),
                            displayName: (item) => item['name'] ?? '',
                            onSelect: (item) {
                              controller.toggleLanguage(item['id']!);
                            },
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    controller.selectedLanguageIds.isNotEmpty
                                        ? controller.selectedLanguageNamesText
                                        : "Select Languages Known",
                                    style: controller.selectedLanguageIds.isNotEmpty
                                        ? Styles.txtBlackColorW50016
                                        : Styles.txtG7Colors50016,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.black87),
                              ],
                            ),
                          ),
                        ),
                        if (controller.selectedLanguageIds.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: controller.languagesList
                                .where((l) => controller.selectedLanguageIds.contains(l['id']))
                                .map((lang) {
                              return Chip(
                                label: Text(lang['name'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                backgroundColor: ColorsValue.appColor.withValues(alpha: 0.2),
                                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.black54),
                                onDeleted: () => controller.toggleLanguage(lang['id']!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                    Dimens.boxHeight20,

                    // Vehicles Driver Can Operate (Searchable Multi-Select)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Vehicle Driver Can Operate", style: Styles.txtG6ColorW40014),
                            const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _showSearchableBottomSheet(
                            context: context,
                            title: "Select Vehicle Driver Can Operate",
                            searchController: controller.vehicleSearchController,
                            listProvider: () => controller.filteredVehicles,
                            isMultiSelect: false,
                            isSelected: (item) => controller.selectedVehicleIds.contains(item['id']),
                            displayName: (item) => item['name'] ?? '',
                            onSelect: (item) {
                              controller.selectVehicle(item['id']!);
                            },
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    controller.selectedVehicleIds.isNotEmpty
                                        ? controller.selectedVehicleNamesText
                                        : "Select Vehicle Driver Can Operate",
                                    style: controller.selectedVehicleIds.isNotEmpty
                                        ? Styles.txtBlackColorW50016
                                        : Styles.txtG7Colors50016,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.black87),
                              ],
                            ),
                          ),
                        ),
                        if (controller.selectedVehicleIds.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: controller.vehiclesList
                                .where((v) => controller.selectedVehicleIds.contains(v['id']))
                                .map((veh) {
                              return Chip(
                                label: Text(veh['name'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                backgroundColor: ColorsValue.appColor.withValues(alpha: 0.2),
                                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.black54),
                                onDeleted: () => controller.toggleVehicle(veh['id']!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ],

                  // ----------------------------------------------------
                  // STEP 2: IDENTITY DOCUMENTS (KYC)
                  // ----------------------------------------------------
                  if (controller.currentRegisterStep == 2) ...[
                    _buildVerificationField(
                      title: "Aadhaar Card Number",
                      hintText: "Enter 12-digit Aadhaar Number",
                      textController: controller.registerAadharController,
                      isVerified: controller.isAadhaarVerified,
                      isVerifying: controller.isAadhaarVerifying,
                      keyboardType: TextInputType.number,
                      onVerify: controller.verifyAadhaar,
                      onChanged: (val) {
                        if (controller.isAadhaarVerified) {
                          controller.isAadhaarVerified = false;
                          controller.update();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().length != 12) {
                          return "Aadhaar number must be 12 digits";
                        }
                        return null;
                      },
                    ),
                    Dimens.boxHeight16,

                    Row(
                      children: [
                        Expanded(
                          child: _buildUploadBox(
                            title: "Aadhaar Front Photo",
                            imagePath: controller.aadharPhotoPath,
                            onTap: controller.pickAadharPhoto,
                            icon: Icons.credit_card_rounded,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildUploadBox(
                            title: "Aadhaar Back Photo",
                            imagePath: controller.aadharBackPhotoPath,
                            onTap: controller.pickAadharBackPhoto,
                            icon: Icons.credit_card_outlined,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight24,

                    _buildVerificationField(
                      title: "PAN Card Number",
                      hintText: "e.g. ABCDE1234F",
                      textController: controller.registerPanController,
                      isVerified: controller.isPanVerified,
                      isVerifying: controller.isPanVerifying,
                      onVerify: controller.verifyPAN,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (val) {
                        if (controller.isPanVerified) {
                          controller.isPanVerified = false;
                          controller.update();
                        }
                      },
                      validator: (value) {
                        if (value == null || !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.trim().toUpperCase())) {
                          return "Enter valid PAN format (e.g. ABCDE1234F)";
                        }
                        return null;
                      },
                    ),
                    Dimens.boxHeight16,

                    _buildUploadBox(
                      title: "PAN Card Photo",
                      imagePath: controller.panPhotoPath,
                      onTap: controller.pickPanPhoto,
                      icon: Icons.assignment_ind_outlined,
                      isRequired: true,
                    ),
                    Dimens.boxHeight24,

                    // --- GST (Optional) ---
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "GST Details (Optional)",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),

                    _buildVerificationField(
                      title: "GST Number",
                      hintText: "e.g. 24AAAAA0000A1Z5 (Optional)",
                      textController: controller.registerGstNumberController,
                      isVerified: controller.isGstVerified,
                      isVerifying: controller.isGstVerifying,
                      onVerify: controller.verifyGST,
                      isCompulsory: false,
                      onChanged: (val) {
                        if (controller.isGstVerified) {
                          controller.isGstVerified = false;
                          controller.update();
                        }
                      },
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty && value.trim().length != 15) {
                          return "GST number must be 15 characters";
                        }
                        return null;
                      },
                    ),
                    Dimens.boxHeight16,

                    _buildUploadBox(
                      title: "GST Registration Certificate (Optional)",
                      imagePath: controller.gstCertificatePhotoPath,
                      onTap: controller.pickGstCertificate,
                      icon: Icons.receipt_long_outlined,
                    ),
                    Dimens.boxHeight24,

                    // --- Address Proof ---
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Address Proof (Optional)",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Address Proof Type (Optional)", style: Styles.txtG6ColorW40014),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: const ['Light Bill', 'Rent Agreement', 'Phone Bill'].contains(controller.selectedAddressProofType)
                                  ? controller.selectedAddressProofType
                                  : 'Light Bill',
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'Light Bill', child: Text('Light Bill')),
                                DropdownMenuItem(value: 'Rent Agreement', child: Text('Rent Agreement')),
                                DropdownMenuItem(value: 'Phone Bill', child: Text('Phone Bill')),
                              ],
                              onChanged: (val) {
                                controller.selectedAddressProofType = val ?? 'Light Bill';
                                controller.update();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight16,

                    if (controller.selectedAddressProofType == 'Light Bill' ||
                        controller.selectedAddressProofType == 'Phone Bill') ...[
                      CustomTextFormField(
                        style: Styles.txtBlackColorW50016,
                        hintText: controller.selectedAddressProofType == 'Light Bill'
                            ? "Enter Light Bill Number"
                            : "Enter Phone Bill Number",
                        isBorder: true,
                        isTitle: true,
                        textEditingController: controller.addressProofNumberController,
                        title: controller.selectedAddressProofType == 'Light Bill'
                            ? "Light Bill Number (Optional)"
                            : "Phone Bill Number (Optional)",
                        hintStyle: Styles.txtG7Colors50016,
                        titleStyle: Styles.txtG6ColorW40014,
                        isCompulsory: false,
                        validator: null,
                      ),
                      Dimens.boxHeight16,

                      _buildUploadBox(
                        title: controller.selectedAddressProofType == 'Light Bill'
                            ? "Light Bill Document (Optional)"
                            : "Phone Bill Document (Optional)",
                        imagePath: controller.addressProofDocumentPath,
                        onTap: controller.pickAddressProofDocument,
                        icon: Icons.receipt_outlined,
                        isRequired: false,
                      ),
                    ] else ...[
                      // Rent Agreement
                      _buildUploadBox(
                        title: "Rent Agreement Document (Optional)",
                        imagePath: controller.addressProofDocumentPath,
                        onTap: controller.pickAddressProofDocument,
                        icon: Icons.home_outlined,
                        isRequired: false,
                      ),
                    ],
                    Dimens.boxHeight24,

                    // --- Police Criminal Certificate (PCC) ---
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Police Criminal Certificate (PCC)",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),

                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "Enter Police Criminal Certificate (PCC) Number",
                      isBorder: true,
                      isTitle: true,
                      textEditingController: controller.pccNumberController,
                      title: "Police Criminal Certificate (PCC) Number",
                      hintStyle: Styles.txtG7Colors50016,
                      titleStyle: Styles.txtG6ColorW40014,
                      isCompulsory: false,
                      validator: null,
                    ),
                    Dimens.boxHeight16,

                    _buildUploadBox(
                      title: "Upload Police Criminal Certificate (PCC)",
                      imagePath: controller.pccCertificatePath,
                      onTap: controller.pickPccCertificate,
                      icon: Icons.verified_user_outlined,
                      isRequired: false,
                    ),
                    Dimens.boxHeight24,

                    // --- Visiting Card (Optional) ---
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildUploadBox(
                      title: "Visiting Card (Optional)",
                      imagePath: controller.visitingCardPhotoPath,
                      onTap: controller.pickVisitingCard,
                      icon: Icons.contact_page_outlined,
                    ),
                  ],

                  // ----------------------------------------------------
                  // STEP 3: BANK DETAILS
                  // ----------------------------------------------------
                  if (controller.currentRegisterStep == 3) ...[
                    _buildVerificationField(
                      title: "IFSC Code",
                      hintText: "e.g. HDFC0001234",
                      textController: controller.registerIfscController,
                      isVerified: controller.isBankVerified,
                      isVerifying: controller.isBankVerifying,
                      onVerify: controller.verifyIFSC,
                      onChanged: (val) {
                        if (controller.isBankVerified) {
                          controller.isBankVerified = false;
                          controller.update();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return "Enter valid IFSC code";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Tip: Tap 'Verify' to automatically fetch Bank Name & Branch",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Dimens.boxHeight16,

                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "Enter Bank Name",
                      isBorder: true,
                      isTitle: true,
                      readOnly: controller.isBankVerified,
                      filled: true,
                      fillColor: controller.isBankVerified ? Colors.grey.shade100 : Colors.white,
                      textEditingController: controller.registerBankNameController,
                      title: "Bank Name",
                      hintStyle: Styles.txtG7Colors50016,
                      titleStyle: Styles.txtG6ColorW40014,
                      isCompulsory: true,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Bank name is required";
                        return null;
                      },
                    ),
                    Dimens.boxHeight16,

                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "Enter Branch Name",
                      isBorder: true,
                      isTitle: true,
                      readOnly: controller.isBankVerified,
                      filled: true,
                      fillColor: controller.isBankVerified ? Colors.grey.shade100 : Colors.white,
                      textEditingController: controller.registerBranchNameController,
                      title: "Branch Name",
                      hintStyle: Styles.txtG7Colors50016,
                      titleStyle: Styles.txtG6ColorW40014,
                    ),
                    Dimens.boxHeight16,

                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "Enter Account Number",
                      isBorder: true,
                      isTitle: true,
                      textEditingController: controller.registerAccountNumberController,
                      keyboardType: TextInputType.number,
                      title: "Bank Account Number",
                      hintStyle: Styles.txtG7Colors50016,
                      titleStyle: Styles.txtG6ColorW40014,
                      isCompulsory: true,
                      validator: (val) {
                        if (val == null || val.trim().length < 8) return "Enter valid account number";
                        return null;
                      },
                    ),
                    Dimens.boxHeight16,

                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "Enter Account Holder Name",
                      isBorder: true,
                      isTitle: true,
                      textEditingController: controller.registerAccountHolderController,
                      title: "Account Holder Name",
                      hintStyle: Styles.txtG7Colors50016,
                      titleStyle: Styles.txtG6ColorW40014,
                    ),
                    Dimens.boxHeight16,

                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "e.g. driver@upi (Optional)",
                      isBorder: true,
                      isTitle: true,
                      textEditingController: controller.registerUpiController,
                      title: "UPI ID (Optional)",
                      hintStyle: Styles.txtG7Colors50016,
                      titleStyle: Styles.txtG6ColorW40014,
                    ),
                    Dimens.boxHeight20,

                    _buildUploadBox(
                      title: "Bank Passbook / Cheque Photo",
                      imagePath: controller.passbookPhotoPath,
                      onTap: controller.pickPassbookPhoto,
                      icon: Icons.account_balance_outlined,
                      isRequired: true,
                    ),
                  ],

                  // ----------------------------------------------------
                  // STEP 4: VEHICLE INFORMATION & STATUTORY DOCUMENTS
                  // ----------------------------------------------------
                  if (controller.currentRegisterStep == 4) ...[
                    // RC Number field with Verify Button (First field of Step 4)
                    _buildVerificationField(
                      title: "RC Number",
                      hintText: "e.g. GJ01ABCD1234",
                      textController: controller.registerRcNumberController,
                      isVerified: controller.isRcVerified,
                      isVerifying: controller.isRcVerifying,
                      onVerify: controller.verifyRC,
                      isCompulsory: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(13),
                      ],
                      onChanged: (val) {
                        if (controller.isRcVerified) {
                          controller.isRcVerified = false;
                        }
                        controller.registerVehicleNumberController.text = val;
                        controller.update();
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter RC number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Tip: Tap 'Verify' to automatically fetch Vehicle Brand, Model Year & Document Expiry Dates",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Dimens.boxHeight16,

                    // Brand Name (Auto-populated from RC, disabled once verified)
                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "e.g. Maruti Suzuki, Hyundai, Tata",
                      isBorder: true,
                      isTitle: true,
                      readOnly: controller.isRcVerified,
                      filled: true,
                      fillColor: controller.isRcVerified ? Colors.grey.shade100 : Colors.white,
                      textEditingController: controller.registerVehicleMakeController,
                      title: "Vehicle Brand / Make *",
                      hintStyle: Styles.txtG7Colors50016,
                      titleStyle: Styles.txtG6ColorW40014,
                      isCompulsory: true,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Please enter vehicle brand/make";
                        return null;
                      },
                    ),
                    Dimens.boxHeight14,

                    // Dynamic Vehicle Type Dropdown
                    if (controller.vehiclesList.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Vehicle Type", style: Styles.txtG6ColorW40014),
                              const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.vehiclesList.any((item) => item['id'] == controller.selectedVehicleType)
                                    ? controller.selectedVehicleType
                                    : null,
                                isExpanded: true,
                                hint: Text("Auto-detected from RC", style: Styles.txtG7Colors50016),
                                items: controller.vehiclesList.map((item) {
                                  return DropdownMenuItem<String>(
                                    value: item['id'],
                                    child: Text(item['name'] ?? '', style: Styles.txtBlackColorW50016),
                                  );
                                }).toList(),
                                onChanged: null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Dimens.boxHeight14,
                    ],

                    // Vehicle Number (Auto-synced with RC Number, disabled once verified)
                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "e.g. GJ01AB1234",
                      isBorder: true,
                      isTitle: true,
                      readOnly: controller.isRcVerified,
                      filled: true,
                      fillColor: controller.isRcVerified ? Colors.grey.shade100 : Colors.white,
                      textEditingController: controller.registerVehicleNumberController,
                      title: "Vehicle Registration Number *",
                      hintStyle: Styles.txtG7Colors50016,
                      titleStyle: Styles.txtG6ColorW40014,
                      isCompulsory: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(13),
                      ],
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Please enter vehicle registration number";
                        return null;
                      },
                    ),
                    Dimens.boxHeight16,

                    // Dynamic Fuel Type Dropdown
                    if (controller.fuelTypesList.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Fuel Type", style: Styles.txtG6ColorW40014),
                              const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.fuelTypesList.any((item) => item['id'] == controller.selectedFuelType)
                                    ? controller.selectedFuelType
                                    : null,
                                isExpanded: true,
                                hint: Text("Select Fuel Type", style: Styles.txtG7Colors50016),
                                items: controller.fuelTypesList.map((item) {
                                  return DropdownMenuItem<String>(
                                    value: item['id'],
                                    child: Text(item['name'] ?? '', style: Styles.txtBlackColorW50016),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  controller.selectedFuelType = val;
                                  controller.update();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Dimens.boxHeight16,
                    ],

                    // Make Year (Auto-populated from RC, disabled once verified)
                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "e.g. 2023",
                      isBorder: true,
                      isTitle: true,
                      readOnly: controller.isRcVerified,
                      filled: true,
                      fillColor: controller.isRcVerified ? Colors.grey.shade100 : Colors.white,
                      textEditingController: controller.registerVehicleMakeYearController,
                      keyboardType: TextInputType.number,
                      title: "Make Year",
                      hintStyle: Styles.txtG7Colors50016,
                      titleStyle: Styles.txtG6ColorW40014,
                    ),
                    Dimens.boxHeight20,

                    // Sourcing (Owner vs Rented)
                    _buildRadioToggle(
                      title: "Vehicle Sourcing *",
                      value: controller.selectedSourcing,
                      options: const ["Owner Vehicle", "Rented Vehicle"],
                      onChanged: (val) {
                        controller.selectedSourcing = val;
                        controller.update();
                      },
                    ),
                    Dimens.boxHeight16,

                    if (controller.selectedSourcing == "Rented Vehicle") ...[
                      // 1. Download BamBam Rented Vehicle Agreement Button
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF5C00).withValues(alpha: 0.35), width: 1.2),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: controller.isDownloadingAgreement
                              ? null
                              : controller.downloadBambamRentAgreement,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5C00),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: controller.isDownloadingAgreement
                                      ? const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.file_download_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Download BamBam Car Rent Agreement",
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Download official agreement format (PDF / JPG)",
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Color(0xFFFF5C00),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2. Upload Your Car Rent Agreement Box
                      _buildUploadBox(
                        title: "Upload Your Car Rent Agreement",
                        imagePath: controller.rentedVehicleAgreementPath,
                        onTap: controller.pickRentedVehicleAgreement,
                        icon: Icons.handshake_outlined,
                        isRequired: false,
                      ),
                      const SizedBox(height: 8),

                      // 3. Informational Note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Color(0xFFFF5C00),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: "Note: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Please download the official BamBam Car Rent Agreement from above, fill it up completely, sign it with the vehicle owner, and upload the signed agreement copy here.",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Dimens.boxHeight20,
                    ],

                    // Vehicle Features Toggles
                    _buildRadioToggle(
                      title: "Pet Friendly *",
                      value: controller.petFriendly,
                      options: const ["Yes", "No"],
                      onChanged: (val) {
                        controller.petFriendly = val;
                        controller.update();
                      },
                    ),
                    Dimens.boxHeight16,

                    _buildRadioToggle(
                      title: "Luggage Carrier Available *",
                      value: controller.luggageCarrier,
                      options: const ["Yes", "No"],
                      onChanged: (val) {
                        controller.luggageCarrier = val;
                        controller.update();
                      },
                    ),
                    Dimens.boxHeight16,

                    _buildRadioToggle(
                      title: "Working Rear Seat Belts *",
                      value: controller.rearSeatBelts,
                      options: const ["Yes", "No"],
                      onChanged: (val) {
                        controller.rearSeatBelts = val;
                        controller.update();
                      },
                    ),
                    Dimens.boxHeight20,

                    // Permit Type
                    DroupDownButtonWigeat<String>(
                      hintText: "Select Permit Type",
                      isTitle: true,
                      borderRadius: BorderRadius.circular(Dimens.twelve),
                      items: const [
                        "State Permit",
                        "All India Permit",
                        "Special Permit",
                        "Local City Permit"
                      ],
                      value: controller.permitType,
                      onChanged: (newValue) {
                        controller.permitType = newValue ?? "State Permit";
                        controller.update();
                      },
                      textStyle: Styles.txtBlackColorW50016,
                      isCompulsory: true,
                      title: "Permit Type",
                      hintStyle: Styles.txtG7Colors50016,
                      titleStyle: Styles.txtG6ColorW40014,
                      isBorder: true,
                    ),
                    Dimens.boxHeight20,

                    // Statutory Documents & Validity Dates
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Statutory Documents & Expiry",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),

                    _buildUploadBox(
                      title: "RC Document Photo",
                      imagePath: controller.rcPhotoPath,
                      onTap: controller.pickRcPhoto,
                      icon: Icons.directions_car_filled_outlined,
                      isRequired: true,
                    ),
                    Dimens.boxHeight16,

                    _buildDatePickerField(
                      context: context,
                      title: "Insurance Expiry Date",
                      hintText: "Select Insurance Expiry",
                      textController: controller.registerInsuranceExpiryController,
                      isCompulsory: false,
                      isEditable: !controller.isRcVerified,
                      firstDate: DateTime.now(),
                    ),
                    Dimens.boxHeight12,

                    _buildUploadBox(
                      title: "Insurance Policy Document",
                      imagePath: controller.insuranceDocumentPath,
                      onTap: controller.pickInsuranceDocument,
                      icon: Icons.health_and_safety_outlined,
                    ),
                    Dimens.boxHeight16,

                    _buildDatePickerField(
                      context: context,
                      title: "Fitness Expiry Date",
                      hintText: "Select Fitness Expiry",
                      textController: controller.registerFitnessExpiryController,
                      isCompulsory: false,
                      isEditable: !controller.isRcVerified,
                      firstDate: DateTime.now(),
                    ),
                    Dimens.boxHeight12,

                    _buildUploadBox(
                      title: "Fitness Certificate Document",
                      imagePath: controller.fitnessDocumentPath,
                      onTap: controller.pickFitnessDocument,
                      icon: Icons.fact_check_outlined,
                    ),
                    Dimens.boxHeight16,

                    _buildDatePickerField(
                      context: context,
                      title: "Permit Expiry Date",
                      hintText: "Select Permit Expiry",
                      textController: controller.registerPermitExpiryController,
                      isCompulsory: false,
                      isEditable: true,
                      firstDate: DateTime.now(),
                    ),
                    Dimens.boxHeight12,

                    _buildUploadBox(
                      title: "Permit Document",
                      imagePath: controller.permitDocumentPath,
                      onTap: controller.pickPermitDocument,
                      icon: Icons.assignment_outlined,
                    ),
                    Dimens.boxHeight16,

                    _buildUploadBox(
                      title: "PUC (Pollution Under Control) Document",
                      imagePath: controller.pucDocumentPath,
                      onTap: controller.pickPucDocument,
                      icon: Icons.cloud_done_outlined,
                    ),
                  ],

                  // ----------------------------------------------------
                  // STEP 5: VEHICLE IMAGES
                  // ----------------------------------------------------
                  if (controller.currentRegisterStep == 5) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildUploadBox(
                            title: "Vehicle Front Photo",
                            imagePath: controller.vehicleFrontPhotoPath,
                            onTap: controller.pickVehicleFrontPhoto,
                            icon: Icons.camera_alt_outlined,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildUploadBox(
                            title: "Vehicle Back Photo",
                            imagePath: controller.vehicleBackPhotoPath,
                            onTap: controller.pickVehicleBackPhoto,
                            icon: Icons.camera_alt_outlined,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight16,

                    Row(
                      children: [
                        Expanded(
                          child: _buildUploadBox(
                            title: "Vehicle Left Side",
                            imagePath: controller.vehicleLeftPhotoPath,
                            onTap: controller.pickVehicleLeftPhoto,
                            icon: Icons.directions_car_outlined,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildUploadBox(
                            title: "Vehicle Right Side",
                            imagePath: controller.vehicleRightPhotoPath,
                            onTap: controller.pickVehicleRightPhoto,
                            icon: Icons.directions_car_outlined,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight16,

                    Row(
                      children: [
                        Expanded(
                          child: _buildUploadBox(
                            title: "Interior View",
                            imagePath: controller.vehicleInteriorPhotoPath,
                            onTap: controller.pickVehicleInteriorPhoto,
                            icon: Icons.airline_seat_recline_extra_outlined,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildUploadBox(
                            title: "Number Plate Photo",
                            imagePath: controller.vehicleNumberPlatePhotoPath,
                            onTap: controller.pickVehicleNumberPlatePhoto,
                            icon: Icons.subtitles_outlined,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight16,

                    _buildUploadBox(
                      title: "Dicky / Trunk Photo",
                      imagePath: controller.vehicleDickyPhotoPath,
                      onTap: controller.pickVehicleDickyPhoto,
                      icon: Icons.luggage_outlined,
                    ),

                    if (controller.luggageCarrier == "Yes") ...[
                      Dimens.boxHeight16,
                      _buildUploadBox(
                        title: "Roof Luggage Carrier Photo",
                        imagePath: controller.vehicleCarrierPhotoPath,
                        onTap: controller.pickVehicleCarrierPhoto,
                        icon: Icons.roofing_outlined,
                        isRequired: true,
                      ),
                    ],

                    Dimens.boxHeight24,
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.amber.shade900),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Please ensure all photos and document scans are clearly visible. Once submitted, your profile and vehicle will be reviewed and verified by the BamBam Admin team.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.brown.shade900,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Dimens.boxHeight20,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
