import 'package:flutter/material.dart';

class MonthYearPickerProvider extends ChangeNotifier {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  void setSelectedMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  void decrementYear() {
    _selectedYear--;
    notifyListeners();
  }

  void incrementYear() {
    _selectedYear++;
    notifyListeners();
  }

  void resetToDefaults({int? year, int? month}) {
    _selectedYear = year ?? DateTime.now().year;
    _selectedMonth = month ?? DateTime.now().month;
    notifyListeners();
  }
}
