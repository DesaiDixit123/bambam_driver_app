// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:bam_bam_driver/app/app.dart';
// ignore_for_file: must_be_immutable

class CustomButton extends StatelessWidget {
  CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.leading,
    this.textStyle,
    this.heightBtn,
    this.widthBtn,
    this.radius,
    this.backgroundColor,
    this.isBorder,
    this.bordercolors,
    this.isColor,
    this.isboxsedo,
  });

  void Function()? onPressed;
  String? text;
  Widget? leading;
  TextStyle? textStyle;
  double? radius;
  double? widthBtn;
  double? heightBtn;
  Color? backgroundColor;
  Color? bordercolors;
  bool? isBorder;
  bool? isColor;
  bool? isboxsedo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: heightBtn ?? Dimens.fourtyFive,
        width: widthBtn ?? double.maxFinite,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(radius ?? Dimens.twelve),
          border: isBorder ?? false
              ? Border.all(
                  width: Dimens.one,
                  color: bordercolors ?? ColorsValue.borderColors,
                )
              : Border.all(
                  width: Dimens.zero,
                  color: bordercolors ?? ColorsValue.borderColors,
                ),
          boxShadow: isboxsedo == true
              ? [
                  BoxShadow(
                    color: const Color(0x99F4F5FA),
                    offset: const Offset(0, -3),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            // spacing: Dimens.ten,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(child: leading),
              leading != null ? Dimens.boxWidth10 : Dimens.boxWidth0,
              Text(text ?? "", style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
