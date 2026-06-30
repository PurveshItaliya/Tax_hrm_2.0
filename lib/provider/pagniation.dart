// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';

class AppPaginationProvider extends ChangeNotifier {
  int setSelectedPaginationPage = 0;
  int setTotalPaginationPage = 1;
  int setTotalShowDataLength = 10;

  int startIndextoShow = 0;
  int endIndexShow = 10;

  int _currentPage = 0;

  int get currentPage => _currentPage;

  Future countPaginationPage(List setSelectedList, int setValues) async {
    setTotalPaginationPage = (setSelectedList.length / setTotalShowDataLength).ceil();

    if (setValues == 0) {
      setSelectedPaginationPage = 0;
      startIndextoShow = 0;
    } else {
      setSelectedPaginationPage = setValues;
      startIndextoShow = setSelectedPaginationPage * setTotalShowDataLength;
    }
    endIndexShow = startIndextoShow + setTotalShowDataLength;
    Future.microtask(() {
      notifyListeners();
    });
  }

  Future countPaginationUpdate(List setSelectedList,int setValues,int updateDataNumber,) async {
    setTotalShowDataLength = updateDataNumber;
    setTotalPaginationPage = (setSelectedList.length / setTotalShowDataLength).ceil();
    setSelectedPaginationPage = 0;

    if (setValues == 0) {
      startIndextoShow = 0;
    } else {
      startIndextoShow = setSelectedPaginationPage * setTotalShowDataLength;
    }
    endIndexShow = startIndextoShow + setTotalShowDataLength;

    Future.microtask(() {
      notifyListeners();
    });
  }
}
