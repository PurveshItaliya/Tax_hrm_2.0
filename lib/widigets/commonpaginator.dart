// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    if (widget.numberPages <= 1) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.chevron_left_rounded, 
            color: widget.initialPage > 0 ? ColorConst.themeColor : Colors.grey.shade400, 
            size: 26,
          ),
          onPressed: widget.initialPage > 0
              ? () => widget.onPageChange?.call(widget.initialPage - 1)
              : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.numberPages, (index) {
                final isSelected = index == widget.initialPage;
                return GestureDetector(
                  onTap: () => widget.onPageChange?.call(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? ColorConst.themeColor : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? ColorConst.themeColor : Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isSelected ? ColorConst.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.chevron_right_rounded, 
            color: widget.initialPage < widget.numberPages - 1 ? ColorConst.themeColor : Colors.grey.shade400, 
            size: 26,
          ),
          onPressed: widget.initialPage < widget.numberPages - 1
              ? () => widget.onPageChange?.call(widget.initialPage + 1)
              : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}