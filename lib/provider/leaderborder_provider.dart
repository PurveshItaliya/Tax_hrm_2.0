// leaderborder_provider.dart
// ignore_for_file: curly_braces_in_flow_control_structures, strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/models/top_hrm_model.dart';

class LeaderborderProvider extends ChangeNotifier {
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Selected month for leaderboard
  DateTime _selectedMonth = DateTime.now();
  DateTime get selectedMonth => _selectedMonth;
  
  // Leaderboard data
  List<HrmTopListReport>? _hrmTopRecords;
  List<HrmTopListReport>? get setHrmTopRecord => _hrmTopRecords;
  
  // Categorized winners
  final List<WinnerModels> _firstPlace = [];
  final List<WinnerModels> _secondPlace = [];
  final List<WinnerModels> _thirdPlace = [];
  final List<WinnerModels> _others = [];
  
  List<WinnerModels> get firstPlace => _firstPlace;
  List<WinnerModels> get secondPlace => _secondPlace;
  List<WinnerModels> get thirdPlace => _thirdPlace;
  List<WinnerModels> get others => _others;
  
  // All records for detail page
  List<HrmTopListReport> _allRecords = [];
  List<HrmTopListReport> get allRecords => _allRecords;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Get month name for display
  String getLeaderboardMonthName() {
    return DateFormat('MMMM yyyy', LanguageProvider.currentLanguageCode).format(_selectedMonth);
  }

  // Navigate to previous month
  Future<void> previousLeaderboardMonth() async {
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    await getTopLeaderboard(month: newMonth.month, year: newMonth.year);
  }

  // Navigate to next month
  Future<void> nextLeaderboardMonth() async {
    if (_selectedMonth.year == DateTime.now().year && 
        _selectedMonth.month == DateTime.now().month) {
      return;
    }
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    await getTopLeaderboard(month: newMonth.month, year: newMonth.year);
  }

  void processExistingData(List<HrmTopListReport> records, DateTime month) {
    _hrmTopRecords = records;
    _selectedMonth = month;
    _allRecords = List.from(records);
    _processData();
    notifyListeners();
  }

  // Get Top Leaderboard Data from API
  Future<void> getTopLeaderboard({int? month, int? year}) async {
    try {
      setLoading(true);
      
      final selectedMonthVal = month ?? _selectedMonth.month;
      final selectedYearVal = year ?? _selectedMonth.year;
      
      final monthStr = selectedMonthVal.toString().padLeft(2, '0');
      final yearStr = selectedYearVal.toString();
      
      final response = await AttendanceApis().getCompanyDataList(monthStr, yearStr);
      
      if (response != null && response is List) {
        _hrmTopRecords = response.map((item) {
          if (item is HrmTopListReport) {
            return item;
          }
          return HrmTopListReport.fromJson(item);
        }).toList();
        
        _selectedMonth = DateTime(selectedYearVal, selectedMonthVal);
        _processData();
      } else {
        _hrmTopRecords = [];
        _allRecords = [];
        _clearWinners();
      }
      
      notifyListeners();
    } catch (e) {
      _hrmTopRecords = [];
      _allRecords = [];
      _clearWinners();
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  // Process data into categorized winners
  void _processData() {
    if (_hrmTopRecords == null || _hrmTopRecords!.isEmpty) {
      _clearWinners();
      _allRecords = [];
      return;
    }

    _allRecords = List.from(_hrmTopRecords!);
    _firstPlace.clear();
    _secondPlace.clear();
    _thirdPlace.clear();
    _others.clear();

    final sorted = List<HrmTopListReport>.from(_hrmTopRecords!)
      ..sort((a, b) => (b.netWorkingMinutes ?? 0).compareTo(a.netWorkingMinutes ?? 0));

    Map<String, List<HrmTopListReport>> grouped = {};
    for (var r in sorted) {
      final key = r.netWorkingHours ?? '0h 0m';
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final uniqueHours = grouped.keys.toList()
      ..sort((a, b) => _toMinutes(b).compareTo(_toMinutes(a)));

    int currentRank = 1;
    for (var hours in uniqueHours) {
      final employees = grouped[hours]!;
      for (var emp in employees) {
        final winner = WinnerModels(
          name: _formatName(emp.empName ?? ''),
          rank: currentRank,
          hours: emp.netWorkingHours ?? '0h 0m',
          totalDays: emp.totalDays ?? 0,
          totalBreakHours: emp.totalBreakHours ?? '0h 0m',
          netWorkingMinutes: emp.netWorkingMinutes ?? 0,
          officeHours: emp.totalOfficeHours ?? '0h 0m',
        );
        
        if (currentRank == 1) _firstPlace.add(winner);
        else if (currentRank == 2) _secondPlace.add(winner);
        else if (currentRank == 3) _thirdPlace.add(winner);
        else _others.add(winner);
      }
      currentRank += employees.length;
    }
  }

  void _clearWinners() {
    _firstPlace.clear();
    _secondPlace.clear();
    _thirdPlace.clear();
    _others.clear();
  }

  int _toMinutes(String s) {
    if (s.isEmpty) return 0;
    int total = 0;
    final reg = RegExp(r'(\d+)h\s*(\d*)m?');
    for (final m in reg.allMatches(s)) {
      total += int.parse(m.group(1)!) * 60;
      if (m.group(2) != null && m.group(2)!.isNotEmpty) {
        total += int.parse(m.group(2)!);
      }
    }
    return total;
  }

  String _formatName(String name) => name
      .toLowerCase()
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
      .join(' ');

  // Convert to WinnerModel for podium display
  List<WinnerModels> convertToWinnerModels(List<HrmTopListReport>? records, int rank) {
    if (records == null) return [];
    
    final List<WinnerModels> winners = [];
    for (var emp in records) {
      final netMinutes = emp.netWorkingMinutes ?? 0;
      final empRank = _calculateRank(netMinutes);
      
      if (empRank == rank) {
        winners.add(WinnerModels(
          name: _formatName(emp.empName ?? ''),
          rank: rank,
          hours: emp.netWorkingHours ?? '0h 0m',
          totalDays: emp.totalDays ?? 0,
          totalBreakHours: emp.totalBreakHours ?? '0h 0m',
          netWorkingMinutes: netMinutes,
          officeHours: emp.totalOfficeHours ?? '0h 0m',
        ));
      }
    }
    return winners;
  }

  int _calculateRank(int netWorkingMinutes) {
    if (netWorkingMinutes >= 210) return 1;
    else if (netWorkingMinutes >= 200 && netWorkingMinutes <= 209) return 2;
    else if (netWorkingMinutes >= 160 && netWorkingMinutes <= 199) return 3;
    else return 4;
  }

  // Refresh data for current month
  Future<void> refreshLeaderboard() async {
    await getTopLeaderboard(
      month: _selectedMonth.month,
      year: _selectedMonth.year,
    );
  }

  // Get counts for podium
  int getFirstPlaceCount() => _firstPlace.length;
  int getSecondPlaceCount() => _secondPlace.length;
  int getThirdPlaceCount() => _thirdPlace.length;
}

// Winner Model
class WinnerModels {
  final String name;
  final int rank;
  final String hours;
  final int totalDays;
  final String totalBreakHours;
  final int netWorkingMinutes;
  final String officeHours;

  WinnerModels({
    required this.name,
    required this.rank,
    this.hours = '',
    this.totalDays = 0,
    this.totalBreakHours = '0h 0m',
    this.netWorkingMinutes = 0,
    this.officeHours = '0h 0m',
  });

  String get initials {
    if (name.isEmpty || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}