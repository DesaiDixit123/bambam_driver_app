import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/app.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (context) {
        return Container(
          color: ColorsValue.appBg,
          child: Center(
            child: Image.asset(
              "assets/icon/icon.png",
              height: Dimens.twoHundred,
            ),
          ),
        );
      },
    );
  }
}
