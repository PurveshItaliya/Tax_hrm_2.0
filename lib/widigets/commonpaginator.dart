// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:number_paginator/number_paginator.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

class CommonPagination extends StatefulWidget {
  int initialPage;
  int numberPages;
  dynamic Function(int)? onPageChange;
  CommonPagination(
    this.initialPage,
    this.numberPages,
    this.onPageChange, {
    super.key,
  });

  @override
  State<CommonPagination> createState() => _CommonPaginationState();
}

class _CommonPaginationState extends State<CommonPagination> {
  final NumberPaginatorController controller = NumberPaginatorController();
  @override
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.05,
      child: NumberPaginator(
        key: ValueKey(widget.initialPage),
        controller: controller,
        initialPage: widget.initialPage,
        numberPages: widget.numberPages,
        onPageChange: widget.onPageChange,
        child: Row(
          children: [
            PrevButton(child: Icon(Icons.chevron_left,color: ColorConst.greyColor,size: 30,),),
            Expanded(
              child: NumberContent(
                buttonBuilder: (context, index, isSelected) {
                  return GestureDetector(
                    onTap: () {
                      controller.navigateToPage(index); // Update page
                      if (widget.onPageChange != null) {
                        widget.onPageChange!(index); // Call external function
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: controller.currentPage == index
                            ? ColorConst.themeColor
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: controller.currentPage == index
                              ? ColorConst.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            NextButton(child: Icon(Icons.chevron_right,color: ColorConst.greyColor,size: 30,),),
          ],
        ),
      ),
    );
  }
}