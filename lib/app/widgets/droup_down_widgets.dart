import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart'; // Import your style file if needed

class DroupDownButtonWigeat<T> extends StatelessWidget {
  final String hintText;
  final List<T> items;
  final T? value;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final bool isTitle;
  final bool? isBorder;
  final String? title;
  final TextStyle? titleStyle;
  final bool isCompulsory;
  final Widget? customIcon;
  final String Function(T)? itemLabelBuilder;
  final EdgeInsetsGeometry? contentPadding;

  const DroupDownButtonWigeat({
    super.key,
    required this.hintText,
    required this.items,
    required this.value,
    this.contentPadding,
    required this.onChanged,
    this.validator,
    this.isBorder,
    this.customIcon,
    this.itemLabelBuilder,
    this.hintStyle,
    this.textStyle,
    this.fillColor,
    this.borderRadius,
    this.isTitle = false,
    this.title,
    this.titleStyle,
    this.isCompulsory = false,
  });

  OutlineInputBorder _buildBorder() {
    return OutlineInputBorder(
      borderRadius: borderRadius ?? BorderRadius.circular(Dimens.six),
      borderSide: isBorder ?? false
          ? BorderSide(width: Dimens.one * 0.8, color: ColorsValue.borderColors)
          : BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTitle) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title ?? '', style: titleStyle),
              if (isCompulsory) Text(' *', style: Styles.redColor50014),
            ],
          ),
          Dimens.boxHeight5,
        ],
        DropdownButtonFormField<T>(
          value: (value != null && items.contains(value)) ? value : (items.isNotEmpty ? items.first : null),
          style: textStyle,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor ?? Colors.white,
            hintText: hintText,
            hintStyle: hintStyle ?? Styles.txtBlackColorW50016,
            contentPadding: contentPadding ?? Dimens.edgeInsets12_14_12_14,
            border: _buildBorder(),
            enabledBorder: _buildBorder(),
            focusedBorder: _buildBorder(),
            errorBorder: _buildBorder(),
            focusedErrorBorder: _buildBorder(),
          ),
          icon: customIcon ?? Icon(Icons.keyboard_arrow_down),
          items: items
              .map(
                (T item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabelBuilder != null
                        ? itemLabelBuilder!(item)
                        : item.toString(),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          disabledHint: Checkbox(value: true, onChanged: (value) {}),
        ),
      ],
    );
  }
}
