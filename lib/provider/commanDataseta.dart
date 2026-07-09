// ignore_for_file: unnecessary_null_comparison, file_names

import 'package:flutter/material.dart';
import 'package:tax_hrm/page/salaryslip/month_picker_package.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';
import 'package:tax_hrm/provider/language_provider.dart';

class CommandWidigetsProvider extends ChangeNotifier {
  DateTime setPickerDate = DateTime.now();
  DateTime setPickerStartDate = DateTime(1800);
  DateTime setPickerLastDate = DateTime(2200);
  Future<void> pickDate(BuildContext context,Size size,DateTime setDate,DateTime? pickerStartDate,DateTime? pickerLastDate,Function ontapSetDate) async {
    final picked = await showDatePicker(
      context: context,
      locale: Locale(LanguageProvider.currentLanguageCode),
      initialDate: setDate,
      firstDate: pickerStartDate ?? setPickerStartDate,
      lastDate: pickerLastDate ?? setPickerLastDate,
      initialDatePickerMode: DatePickerMode.day,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            cardColor: Colors.yellowAccent,
            highlightColor: ColorConst.black,
            colorScheme: ColorScheme.dark(
              onBackground: ColorConst.black,
              onPrimaryContainer: Colors.amber,
              primary: ColorConst.themeColor,
              onPrimary: ColorConst.black,
              surface: ColorConst.white,
              onSurface: ColorConst.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ColorConst.themeColor,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setDate = picked;
      ontapSetDate(setDate);
      notifyListeners();
    }
  }


  Future<void> selectMonthYear(BuildContext context, DateTime currentMonth, Function(DateTime) onMonthSelected) async {
    final setDates = await SimpleMonthYearPicker.showMonthYearPickerDialog(
        selectionColor: ColorConst.themeColor,
       selectedYears: currentMonth.year,setCurentMonts: currentMonth.month,
        context: context,
        titleTextStyle: const TextStyle(),
        monthTextStyle: const TextStyle(),
        yearTextStyle: const TextStyle(),
        disableFuture:true,
    );
    if (setDates != null) {
      final DateTime selectedMonth = DateTime(setDates.year, setDates.month);
      final DateTime now = DateTime(DateTime.now().year, DateTime.now().month);
      if (selectedMonth.isAfter(now)) return;
      onMonthSelected(selectedMonth);
    }
    notifyListeners();
  }
}

Future<TimeOfDay?> openTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) async {
  final TimeOfDay? pickedTimers =  await showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: ColorConst.white,

            hourMinuteColor: ColorConst.themeColor.withOpacity(0.15),
            hourMinuteTextColor: ColorConst.themeColor,

            dialHandColor: ColorConst.themeColor,
            dialBackgroundColor: ColorConst.themeColor.withOpacity(0.08),

            entryModeIconColor: ColorConst.themeColor,
            dayPeriodColor: ColorConst.themeColor.withOpacity(0.15),
            dayPeriodTextColor: ColorConst.themeColor,

            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: ColorConst.themeColor,
            ),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),
          colorScheme: ColorScheme.light(
            primary: ColorConst.themeColor,
            onPrimary: ColorConst.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );
  return pickedTimers;
}

Future<Duration?> showHmsTimeDialog(
  BuildContext context, {
  int initialHour = 0,
  int initialMinute = 0,
  int initialSecond = 0,
}) {
  int hour = initialHour;
  int minute = initialMinute;
  int second = initialSecond;

  return showDialog<Duration>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            contentPadding: EdgeInsets.only(left: 30,right: 30),
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(selectTimersString,style: TextStyle(fontSize: 15,fontFamily: fontInterBoldString,fontWeight: FontWeight.w300),),
            ),
            backgroundColor: ColorConst.white,
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timeDropdown(
                  label: "HH",
                  value: hour,
                  max: 23,
                  onChanged: (v) => setState(() => hour = v),
                ),
                _timeDropdown(
                  label: "MM",
                  value: minute,
                  max: 59,
                  onChanged: (v) => setState(() => minute = v),
                ),
                _timeDropdown(
                  label: "SS",
                  value: second,
                  max: 59,
                  onChanged: (v) => setState(() => second = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(cancelString),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context,Duration(hours: hour,minutes: minute,seconds: second,),),
                child: Text(okString),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _timeDropdown({
  required String label,
  required int value,
  required int max,
  required ValueChanged<int> onChanged,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: TextStyle(fontWeight: FontWeight.bold,fontFamily: fontInterBoldString)),
      heightSpacer(6),
      SizedBox(
        width: 70,
        height: 160,
        child: ListView.builder(
          itemCount: max + 1,
          padding: EdgeInsets.zero,
          itemBuilder: (context, i) {
            final isSelected = value == i;
            return GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorConst.themeColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  i.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? ColorConst.themeColor
                        : ColorConst.grey,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
