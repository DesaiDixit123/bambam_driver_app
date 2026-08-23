import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class VehicalMiterScreen extends StatelessWidget {
  const VehicalMiterScreen({super.key});

  Future<Position?> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Utility.showMessage(
        'Location services are disabled. Please enable them to continue.',
        MessageType.error,
        null,
        'OK',
      );
      return null;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Utility.showMessage(
          'Location permission denied. Please grant location access.',
          MessageType.error,
          null,
          'OK',
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Utility.showMessage(
        'Location permissions are permanently denied. Enable them in settings.',
        MessageType.error,
        null,
        'OK',
      );
      return null;
    }

    // If permissions are granted, get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isStartTrip = Get.arguments ?? false;

    return GetBuilder<TripController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Trip Tracking",
          ),
          backgroundColor: ColorsValue.appBg,
          bottomNavigationBar: Padding(
            padding: Dimens.edgeInsets20_30_20_30,
            child: CustomButton(
              onPressed: () async {
                if (controller.kMController.text.isEmpty) {
                  Utility.showMessage('Enter KM', MessageType.error, null, 'OK');
                  return;
                }

                // Validate vendor id
                final vendorId = controller.latestVendorRequestId.isNotEmpty
                    ? controller.latestVendorRequestId
                    : (controller.tripDetails?['_id']?.toString() ?? '');

                if (vendorId.isEmpty) {
                  Utility.showMessage('Trip id not available', MessageType.error, null, 'OK');
                  return;
                }

                // 🔹 Get user’s current GPS location
                Utility.showLoader(); // Optional: show loader while fetching location
                final position = await _determinePosition(context);
                Utility.closeLoader(); // Hide loader after location obtained

                if (position == null) {
                  Utility.showMessage('Unable to get current location', MessageType.error, null, 'OK');
                  return;
                }

                final lat = position.latitude;
                final lon = position.longitude;

                if (isStartTrip) {
                  await controller.startTrip(
                    vendorRequestId: vendorId,
                    startKm: controller.kMController.text.trim(),
                    lat: lat,
                    lon: lon,
                  );
                } else {
                  await controller.endTrip(
                    vendorRequestId: vendorId,
                    endKm: controller.kMController.text.trim(),
                    lat: lat,
                    lon: lon,
                  );
                }
              },
              text: "Continue",
              textStyle: controller.kMController.text.isNotEmpty
                  ? Styles.txtBlackColorW50016
                  : Styles.txtG7Colors50016,
              backgroundColor: controller.kMController.text.isNotEmpty
                  ? ColorsValue.appColor
                  : ColorsValue.bulycolorsCB,
            ),
          ),
          body: Form(
            key: controller.stratTripKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: Dimens.edgeInsets20,
              physics: const BouncingScrollPhysics(),
              children: [
                Dimens.boxHeight20,
                Text(
                  "Click Vehicle Meter Photo",
                  style: Styles.txtBlackColorBold32.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight4,
                Text(
                  isStartTrip
                      ? "Please click km meter photo to continue"
                      : "End Trip Click Vehicle Meter Photo",
                  style: Styles.txtG5ColorsW40014,
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight60,
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                  child: Container(
                    height: Dimens.twoHundredTwentyTwo,
                    width: Get.width,
                    decoration: const BoxDecoration(),
                    child: controller.vehicleMeterImage != null
                        ? Image.file(
                            controller.vehicleMeterImage!,
                            fit: BoxFit.cover,
                          )
                        : SvgPicture.asset(AssetConstants.miter_imge),
                  ),
                ),
                Dimens.boxHeight32,
                CustomButton(
                  onPressed: () => controller.capturePhoto(),
                  text: controller.vehicleMeterImage != null
                      ? "Re-Capture Again"
                      : "Capture Photo",
                  textStyle: Styles.txtBlackColorW50016,
                  isBorder: true,
                  backgroundColor: ColorsValue.appBg,
                  leading: SvgPicture.asset(AssetConstants.Camera),
                ),
                Dimens.boxHeight24,
                controller.vehicleMeterImage != null
                    ? CustomTextFormField(
                        style: Styles.txtBlackColorW50016,
                        hintText: "Enter KM".tr,
                        isBorder: true,
                        textEditingController: controller.kMController,
                        onChanged: (vaule) => controller.update(),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return "Enter KM";
                          return null;
                        },
                        hintStyle: Styles.txtG7Colors50016,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );
  }
}
