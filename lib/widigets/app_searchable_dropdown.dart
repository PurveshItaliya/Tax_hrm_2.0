// ignore_for_file: prefer_function_declarations_over_variables

import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

class AppSearchableDropdown<T> extends StatelessWidget {
  final Key? dropdownKey;
  final T? initialItem;
  final String hintText;
  final String searchHintText;
  final String noResultFoundText;
  final Future<List<T>> Function(String)? futureRequest;
  final List<T>? items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final String Function(T) itemAsString;
  final Widget Function(BuildContext, T, bool)? headerBuilder;
  final bool maxlines;

  const AppSearchableDropdown({
    super.key,
    this.dropdownKey,
    this.initialItem,
    required this.hintText,
    this.searchHintText = 'Search...',
    this.noResultFoundText = 'No results found',
    this.futureRequest,
    this.items,
    required this.onChanged,
    this.validator,
    required this.itemAsString,
    this.headerBuilder,
    this.maxlines = true,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = CustomDropdownDecoration(
      closedFillColor: ColorConst.white,
      expandedFillColor: ColorConst.white,
      closedBorder: Border.all(color: ColorConst.textBorder, width: 1.3),
      expandedBorder: Border.all(color: ColorConst.themeColor, width: 1.3),
      closedBorderRadius: BorderRadius.circular(12),
      expandedBorderRadius: BorderRadius.circular(12),
      closedErrorBorder: Border.all(color: ColorConst.red, width: 1.3),
      closedErrorBorderRadius: BorderRadius.circular(12),
      closedSuffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: ColorConst.hintextColor, size: 22),
      expandedSuffixIcon: Icon(Icons.keyboard_arrow_up_rounded, color: ColorConst.themeColor, size: 22),
      // closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // expandedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // itemsListPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // listItemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      searchFieldDecoration: SearchFieldDecoration(
        fillColor: ColorConst.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorConst.textBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorConst.themeColor, width: 1.3),
        ),
        prefixIcon: Icon(Icons.search, color: ColorConst.hintextColor, size: 20),
        hintStyle: TextStyle(color: ColorConst.hintextColor, fontSize: 14),
      ),
    );

    final listItemBuilder = (BuildContext context, T item, bool isSelected, void Function() onItemSelect) {
      final text = itemAsString(item);
      return Container(
        decoration: BoxDecoration(
          color: isSelected ? ColorConst.themeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? ColorConst.themeColor : ColorConst.black,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle_rounded,
                color: ColorConst.themeColor,
                size: 18,
              ),
            ],
          ],
        ),
      );
    };

    final defaultHeaderBuilder = (BuildContext context, T? selectedItem, bool enabled) {
      if (selectedItem == null) {
        return Text(
          hintText,
          style: TextStyle(
            fontSize: 14,
            color: ColorConst.hintextColor,
          ),
        );
      }
      final text = itemAsString(selectedItem);
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ColorConst.black,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    };

    if (futureRequest != null) {
      return CustomDropdown<T>.searchRequest(
        key: dropdownKey,
        initialItem: initialItem,
        hintText: hintText,
        searchHintText: searchHintText,
        noResultFoundText: noResultFoundText,
        futureRequest: futureRequest!,
        onChanged: (value) {
          FocusManager.instance.primaryFocus?.unfocus();
          onChanged(value);
        },
        validator: validator,
        decoration: decoration,
        listItemBuilder: listItemBuilder,
        headerBuilder: headerBuilder ?? (context, selectedItem, enabled) => defaultHeaderBuilder(context, selectedItem, enabled),
      );
    } else {
      return CustomDropdown<T>.search(
        key: dropdownKey,
        initialItem: initialItem,
        hintText: hintText,
        searchHintText: searchHintText,
        noResultFoundText: noResultFoundText,
        items: items ?? [],
        onChanged: (value) {
          FocusManager.instance.primaryFocus?.unfocus();
          onChanged(value);
        },
        validator: validator,
        decoration: decoration,
        listItemBuilder: listItemBuilder,
        headerBuilder: headerBuilder ?? (context, selectedItem, enabled) => defaultHeaderBuilder(context, selectedItem, enabled),
      );
    }
  }
}
