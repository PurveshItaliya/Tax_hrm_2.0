// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

// Show Number Of Data
showNumberOfData(context, size, List usedListFilters) {
  return showMenu(
    context: context,
    color: ColorConst.white,
    constraints: BoxConstraints(minWidth: size.width * 0.2),
    position: RelativeRect.fromLTRB(size.width * 0.09, size.height * 0.1, 0, 0),
    items: [
      PopupMenuItem(
        value: 1,
        onTap: () { Provider.of<AppPaginationProvider>(context,listen: false,).countPaginationUpdate(usedListFilters, 0, 10); },
        child: Text("10", style: normalHeadingText(size)),
      ),
      PopupMenuItem(
        value: 2,
        onTap: () { Provider.of<AppPaginationProvider>(context,listen: false,).countPaginationUpdate(usedListFilters, 0, 20); },
        child: Text("20", style: normalHeadingText(size)),
      ),
      PopupMenuItem(
        value: 3,
        onTap: () { Provider.of<AppPaginationProvider>(context,listen: false,).countPaginationUpdate(usedListFilters, 0, 50); },
        child: Text("50", style: normalHeadingText(size)),
      ),
      PopupMenuItem(
        value: 4,
        onTap: () { Provider.of<AppPaginationProvider>(context,listen: false,).countPaginationUpdate(usedListFilters, 0, 100); },
        child: Text("100", style: normalHeadingText(size)),
      ),
    ],
  );
}
