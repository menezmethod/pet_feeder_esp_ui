import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class CustomDropDown<T> extends StatefulWidget {
  const CustomDropDown(this.items, this.value, this.onChange, {super.key});
  final List<DropdownMenuItem<T>> items;
  final dynamic value;
  final Function onChange;
  @override
  State<CustomDropDown<T>> createState() => _CustomDropDownState<T>();
}

class _CustomDropDownState<T> extends State<CustomDropDown<T>> {
  @override
  Widget build(BuildContext context) {
    var value = widget.value;
    return Material(
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<T>(
          alignment: Alignment.centerLeft,
          value: value,
          onChanged: (value) {
            widget.onChange(value);
          },
          items: [...widget.items],
        ),
      ),
    );
  }
}
