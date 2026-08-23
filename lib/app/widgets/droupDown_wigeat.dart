import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';

class DroupDownChecklist<T> extends StatelessWidget {
  final String hintText;
  final List<T> items;
  final List<T> selectedItems;
  final void Function(List<T>) onChanged;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final bool isTitle;
  final String? title;
  final TextStyle? titleStyle;
  final bool isCompulsory;
  final Widget? customIcon;

  const DroupDownChecklist({
    super.key,
    required this.hintText,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    this.hintStyle,
    this.textStyle,
    this.fillColor,
    this.borderRadius,
    this.isTitle = false,
    this.title,
    this.titleStyle,
    this.isCompulsory = false,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    String displayText = selectedItems.isEmpty
        ? hintText
        : selectedItems.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTitle) ...[
          Row(
            children: [
              Text(title ?? '', style: titleStyle),
              if (isCompulsory) Text(' *', style: Styles.redColor50014),
            ],
          ),
          Dimens.boxHeight5,
        ],
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                List<T> tempSelected = List.from(selectedItems);
                return AlertDialog(
                  title: Text("Select Options"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: items.map((item) {
                        return CheckboxListTile(
                          title: Text(item.toString()),
                          value: tempSelected.contains(item),
                          onChanged: (bool? checked) {
                            if (checked == true) {
                              tempSelected.add(item);
                            } else {
                              tempSelected.remove(item);
                            }
                            // force rebuild
                            (context as Element).markNeedsBuild();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onChanged(tempSelected);
                      },
                      child: Text("Done"),
                    ),
                  ],
                );
              },
            );
          },
          child: Container(
            padding: Dimens.edgeInsets12_14_12_14,
            decoration: BoxDecoration(
              color: fillColor ?? Colors.white,
              borderRadius: borderRadius ?? BorderRadius.circular(Dimens.six),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: selectedItems.isEmpty
                        ? hintStyle ?? Styles.txtBlackColorW50016
                        : textStyle ?? Styles.txtBlackColorW50016,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                customIcon ?? Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
