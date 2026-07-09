class DayExcelStatus {
  final int day;
  final String status; // 'P', 'A', 'FL', 'HL', 'H', 'WO', '-'
  final String? inTime;
  final String? outTime;
  final String? remarks;

  DayExcelStatus({
    required this.day,
    required this.status,
    this.inTime,
    this.outTime,
    this.remarks,
  });
}

class EmployeeMonthlyExcelData {
  final int empId;
  final String empCode;
  final String fullName;
  final String departmentName;
  final String designation;
  final bool isActive;
  final Map<int, DayExcelStatus> dailyStatuses; // day (1..31) -> DayExcelStatus

  double totalPresent = 0.0;
  int totalAbsent = 0;
  double totalFullLeave = 0.0;
  int totalHalfLeave = 0;
  int totalHoliday = 0;
  int totalWeekend = 0;
  int totalWorkingDays = 0;
  double attendancePercentage = 0.0;

  EmployeeMonthlyExcelData({
    required this.empId,
    required this.empCode,
    required this.fullName,
    required this.departmentName,
    required this.designation,
    this.isActive = true,
    Map<int, DayExcelStatus>? dailyStatuses,
  }) : dailyStatuses = dailyStatuses ?? {};

  void calculateSummary(int daysInMonth, DateTime targetMonth) {
    totalPresent = 0.0;
    totalAbsent = 0;
    totalFullLeave = 0.0;
    totalHalfLeave = 0;
    totalHoliday = 0;
    totalWeekend = 0;
    totalWorkingDays = 0;

    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    for (int day = 1; day <= daysInMonth; day++) {
      final cell = dailyStatuses[day];
      final status = cell?.status ?? '-';
      final dateOnly = DateTime(targetMonth.year, targetMonth.month, day);

      if (dateOnly.isAfter(todayOnly)) {
        continue;
      }

      if (status == 'P') {
        totalPresent += 1.0;
        totalWorkingDays++;
      } else if (status == 'HL') {
        totalPresent += 0.5;
        totalHalfLeave += 1;
        totalWorkingDays++;
      } else if (status == 'A') {
        totalAbsent++;
        totalWorkingDays++;
      } else if (status == 'FL') {
        totalFullLeave += 1.0;
        totalWorkingDays++;
      } else if (status == 'H') {
        totalHoliday++;
      } else if (status == 'WO') {
        totalWeekend++;
      }
    }

    if (totalWorkingDays > 0) {
      attendancePercentage = (totalPresent / totalWorkingDays) * 100.0;
      if (attendancePercentage > 100.0) attendancePercentage = 100.0;
    } else {
      attendancePercentage = 0.0;
    }
  }
}
