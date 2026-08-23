// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bam_bam_driver/app/theme/colors_value.dart';
import 'package:bam_bam_driver/app/theme/dimens.dart';
import 'package:bam_bam_driver/app/theme/styles.dart';

class CustomTextFormField extends StatelessWidget {
  CustomTextFormField({
    super.key,
    this.isTitle = false,
    this.isCompulsory = false,
    this.title,
    this.heightBtn,
    this.widthBtn,
    this.titleStyle,
    this.style,
    this.textEditingController,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.obscureText,
    this.readOnly,
    this.textAlign,
    this.filled,
    this.fillColor,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.hintStyle,
    this.errorStyle,
    this.focusNode,
    this.radius,
    this.onTap,

    this.preIocns,
    this.isBorder = false,
  });

  bool isTitle;
  bool isCompulsory;
  String? title;
  double? widthBtn;
  double? heightBtn;
  TextStyle? titleStyle;
  TextStyle? style;
  TextEditingController? textEditingController;
  TextInputType? keyboardType;
  TextInputAction? textInputAction;
  List<TextInputFormatter>? inputFormatters;
  String? Function(String?)? validator;
  void Function(String)? onChanged;
  VoidCallback? onTap;
  int? maxLength;
  int? maxLines;
  int? minLines;
  bool? obscureText = false;
  bool? readOnly = false;
  TextAlign? textAlign;
  bool? filled;
  bool? preIocns;
  Color? fillColor;
  Widget? prefixIcon;
  Widget? suffixIcon;
  String? hintText;
  TextStyle? hintStyle;
  TextStyle? errorStyle;
  FocusNode? focusNode;
  double? radius;
  bool? isBorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isTitle) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title ?? "", style: titleStyle),
              if (isCompulsory) ...[
                Text(
                  " *",
                  style: Styles.blackColorW50016.copyWith(color: Colors.red),
                ),
              ],
            ],
          ),
          Dimens.boxHeight5,
        ],
        SizedBox(
          height: heightBtn,
          width: widthBtn,

          child: TextFormField(
            onTap: onTap ?? () {},
            style: style,
            focusNode: focusNode,
            controller: textEditingController,
            cursorColor: filled ?? false
                ? ColorsValue.blackColor
                : ColorsValue.borderColors,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            maxLines: maxLines,
            minLines: minLines,
            obscureText: obscureText ?? false,
            readOnly: readOnly ?? false,
            textAlign: textAlign ?? TextAlign.start,
            validator: validator,
            onChanged: onChanged,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              contentPadding: Dimens.edgeInsets20_10_20_10,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius ?? Dimens.twelve),
                borderSide: isBorder ?? false
                    ? BorderSide(
                        width: Dimens.one * 0.8,
                        color: ColorsValue.borderColors,
                      )
                    : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius ?? Dimens.twelve),
                borderSide: isBorder ?? false
                    ? BorderSide(
                        width: Dimens.one * 0.8,
                        color: ColorsValue.borderColors,
                      )
                    : BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius ?? Dimens.twelve),
                borderSide: isBorder ?? false
                    ? BorderSide(
                        width: Dimens.one * 0.8,
                        color: ColorsValue.borderColors,
                      )
                    : BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius ?? Dimens.twelve),
                borderSide: isBorder ?? false
                    ? BorderSide(
                        width: Dimens.one * 0.8,
                        color: ColorsValue.borderColors,
                      )
                    : BorderSide.none,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius ?? Dimens.twelve),
                borderSide: isBorder ?? false
                    ? BorderSide(
                        width: Dimens.one * 0.8,
                        color: ColorsValue.borderColors,
                      )
                    : BorderSide.none,
              ),
              filled: filled,
              fillColor: fillColor,
              prefixIcon: preIocns ?? false
                  ? SizedBox(
                      height: Dimens.ten,
                      child: Padding(
                        padding: Dimens.edgeInsets10,
                        child: prefixIcon,
                      ),
                    )
                  : null,
              suffixIcon: suffixIcon,
              hintText: hintText,
              hintStyle: hintStyle,
              errorStyle: errorStyle,
            ),
          ),
        ),
      ],
    );
  }
}
