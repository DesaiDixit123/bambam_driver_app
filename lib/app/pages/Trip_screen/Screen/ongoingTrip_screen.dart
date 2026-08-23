import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OngoingtripScreen extends StatelessWidget {
  const OngoingtripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "dssf",
          ),
        );
      },
    );
  }
}
