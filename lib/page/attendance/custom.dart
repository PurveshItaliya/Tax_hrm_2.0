// ignore_for_file: unnecessary_null_comparison, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/attendance/allemployeattendance.dart';
import 'package:tax_hrm/models/attendance/attendanceBlog.dart';
import 'package:tax_hrm/provider/adminattendance.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class CustomDialog extends StatefulWidget {
  final String title;
  final AttendenceLog? setDatas;
  final String mainattendancecguid,mainattedanceid;
  final bool insertmood;

  const CustomDialog(this.setDatas,this.mainattendancecguid,this.mainattedanceid, this.title, this.insertmood, {super.key});

  @override
  _CustomDialogState createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  late AdminAttenDanceServices adminAttendanceProvider;

  @override
  void initState() {
    super.initState();
    adminAttendanceProvider = Provider.of<AdminAttenDanceServices>(context, listen: false);
    if(widget.setDatas!.time != null){
      adminAttendanceProvider.setDialogIntimeDateTime(DateTime.parse(widget.setDatas!.time.toString()));
    }
    adminAttendanceProvider.setDialogNotes(widget.setDatas!.remarks ?? '');
  }

  Future<void>  setTimesWithDate(BuildContext context,{String? titleText,bool? inTimeSet, }) async {
    if(inTimeSet  == true){
      if (adminAttendanceProvider.dialogIntimeDateTime != null) {
        final TimeOfDay? pickedTime = await showTimePicker(
         helpText: titleText,
          context: context,
          initialTime: TimeOfDay.now(),
        );
    
        if (pickedTime != null) {
        adminAttendanceProvider.setDialogIntimeDateTime(DateTime(
            adminAttendanceProvider.dialogIntimeDateTime.year,
            adminAttendanceProvider.dialogIntimeDateTime.month,
            adminAttendanceProvider.dialogIntimeDateTime.day,
            pickedTime.hour,
            pickedTime.minute,
          ));
        }
      }
    }else{
      if (adminAttendanceProvider.dialogOuttimeDateTime != null) {
        final TimeOfDay? pickedTime = await showTimePicker(
         helpText: titleText,
          context: context,
          initialTime: TimeOfDay.now(),
        );
    
        if (pickedTime != null) {
          adminAttendanceProvider.setDialogOuttimeDateTime(DateTime(
            adminAttendanceProvider.dialogOuttimeDateTime.year,
            adminAttendanceProvider.dialogOuttimeDateTime.month,
            adminAttendanceProvider.dialogOuttimeDateTime.day,
            pickedTime.hour,
            pickedTime.minute,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AlertDialog(
      backgroundColor: ColorConst.white,
      title:  Text(widget.title,style: TextStyle(fontSize: size.height * 0.025,fontWeight: FontWeight.bold),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Selected Time:',style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.018,fontWeight: FontWeight.bold),),

             TextButton(onPressed: ()async{
                final TimeOfDay initialTime = TimeOfDay(hour: adminAttendanceProvider.dialogIntimeDateTime.hour, minute: adminAttendanceProvider.dialogIntimeDateTime.minute);

                final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: initialTime,builder: (context, child) {
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
                      colorScheme: ColorScheme.light(primary: ColorConst.themeColor, onPrimary: ColorConst.white, onSurface: Colors.black),
                    ),
                    child: child!,
                  );
                },);

                if(pickedTime != null){
                  adminAttendanceProvider.setDialogIntimeDateTime(DateTime(adminAttendanceProvider.dialogIntimeDateTime.year, adminAttendanceProvider.dialogIntimeDateTime.month, adminAttendanceProvider.dialogIntimeDateTime.day, pickedTime.hour, pickedTime.minute));
              }
            }, child: Text(DateFormat.jm().format(DateTime.parse(adminAttendanceProvider.dialogIntimeDateTime.toString())),style: TextStyle(color: ColorConst.themeColor,fontSize: MediaQuery.of(context).size.height *0.017),))
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: adminAttendanceProvider.dialogNotesController,
            decoration:  const InputDecoration(
              hintText: 'Write notes here...',
              border: OutlineInputBorder(borderSide:  BorderSide(color: Colors.teal)),
               focusedBorder: OutlineInputBorder(borderSide:  BorderSide(color: Colors.teal)),
            ),
            onChanged: (value) {
              adminAttendanceProvider.setDialogNotes(value);
            },
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConst.themeColor,
          ),
          onPressed: (){
            Navigator.pop(context);
          }, child: Text(cancelString,style: TextStyle(color: ColorConst.white),),),
        
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConst.themeColor,
          ),
          onPressed: (){
            Provider.of<AdminAttenDanceServices>(context,listen: false).updateLogsData(setattendanceGuid: widget.mainattendancecguid,
              setattendanceTime: adminAttendanceProvider.dialogIntimeDateTime.toString(),
              setattendancedate: DateTime(adminAttendanceProvider.dialogIntimeDateTime.year,adminAttendanceProvider.dialogIntimeDateTime.month,adminAttendanceProvider.dialogIntimeDateTime.day).toString(),
              setattendanceid: widget.mainattedanceid,
              setempids: widget.setDatas!.empId,
              setlogCjuid: widget.setDatas!.cguid,
              setlogStatus: widget.setDatas!.status,
              setlogid: widget.setDatas!.logId,
              setremarks: adminAttendanceProvider.dialogNotesController.text,context: context);
          }, child: Text(saveString,style: TextStyle(color: ColorConst.white),))
      ],
    );
  }
}


///------Admin Add Punch -----------------------\\

class AddPunchFromAdmin extends StatefulWidget {
  final AllEmployeAttendance selectedEmp;
  final String selectedDate;
  const AddPunchFromAdmin(this.selectedEmp, this.selectedDate, {super.key});

  @override
  State<AddPunchFromAdmin> createState() => _AddPunchFromAdminState();
}

class _AddPunchFromAdminState extends State<AddPunchFromAdmin> {
  late AdminAttenDanceServices adminAttendanceProvider;

  @override
  void initState() {
    super.initState();
    adminAttendanceProvider = Provider.of<AdminAttenDanceServices>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Gradient
            Container(
              padding: EdgeInsets.all(size.width * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorConst.themeColor, ColorConst.themeColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(size.width * 0.025),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: size.width * 0.06,
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Punch',
                          style: TextStyle(
                            fontSize: size.height * 0.024,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: fontInterBoldString,
                          ),
                        ),
                        SizedBox(height: size.height * 0.003),
                        Text(
                          '${widget.selectedEmp.firstName} ${widget.selectedEmp.lastName}',
                          style: TextStyle(
                            fontSize: size.height * 0.014,
                            color: Colors.white70,
                            fontFamily: fontInterRegularString,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(size.width * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: size.width * 0.045,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(size.width * 0.05),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time Picker Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ColorConst.themeColor.withOpacity(0.05), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: ColorConst.themeColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
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

                          if (pickedTime != null) {
                            setState(() {
                              adminAttendanceProvider.setDialogIntimeDateTime(DateTime(
                                adminAttendanceProvider.dialogIntimeDateTime.year,
                                adminAttendanceProvider.dialogIntimeDateTime.month,
                                adminAttendanceProvider.dialogIntimeDateTime.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              ));
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(size.width * 0.04),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(size.width * 0.025),
                                decoration: BoxDecoration(
                                  color: ColorConst.themeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.access_time_filled,
                                  color: ColorConst.themeColor,
                                  size: size.width * 0.055,
                                ),
                              ),
                              SizedBox(width: size.width * 0.04),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected Time',
                                      style: TextStyle(
                                        fontSize: size.height * 0.014,
                                        color: Colors.grey.shade600,
                                        fontFamily: fontInterMediumString,
                                      ),
                                    ),
                                    SizedBox(height: size.height * 0.005),
                                    Text(
                                      DateFormat.jm().format(
                                        DateTime.parse(adminAttendanceProvider.dialogIntimeDateTime.toString())
                                      ),
                                      style: TextStyle(
                                        fontSize: size.height * 0.02,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConst.themeColor,
                                        fontFamily: fontInterBoldString,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(size.width * 0.02),
                                decoration: BoxDecoration(
                                  color: ColorConst.themeColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: ColorConst.themeColor,
                                  size: size.width * 0.04,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.02),
                  
                  // Notes TextField
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: adminAttendanceProvider.dialogNotesController,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: size.height * 0.016,
                        fontFamily: fontInterRegularString,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write notes here...',
                        hintStyle: TextStyle(
                          fontSize: size.height * 0.014,
                          color: Colors.grey.shade400,
                          fontFamily: fontInterRegularString,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(size.width * 0.04),
                        prefixIcon: Icon(
                          Icons.note_add_rounded,
                          color: ColorConst.themeColor.withOpacity(0.6),
                          size: size.width * 0.055,
                        ),
                      ),
                      onChanged: (value) {
                        adminAttendanceProvider.setDialogNotes(value);
                      },
                    ),
                  ),
                  
                  // Employee Info Card
                  SizedBox(height: size.height * 0.015),
                  Container(
                    padding: EdgeInsets.all(size.width * 0.03),
                    decoration: BoxDecoration(
                      color: ColorConst.themeColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorConst.themeColor.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ColorConst.themeColor,
                          size: size.width * 0.045,
                        ),
                        SizedBox(width: size.width * 0.03),
                        Expanded(
                          child: Text(
                            'Punch will be recorded for ${DateFormat('dd MMMM yyyy').format(DateTime.parse(widget.selectedDate))}',
                            style: TextStyle(
                              fontSize: size.height * 0.013,
                              color: Colors.grey.shade700,
                              fontFamily: fontInterRegularString,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Container(
              padding: EdgeInsets.fromLTRB(size.width * 0.05, 0, size.width * 0.05, size.width * 0.05),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ColorConst.themeColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: size.height * 0.016),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: ColorConst.themeColor,
                          fontSize: size.height * 0.016,
                          fontWeight: FontWeight.w600,
                          fontFamily: fontInterSemiBoldString,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConst.themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: size.height * 0.016),
                        elevation: 2,
                      ),
                      onPressed: () {
                        final DateTime selectedDate = DateTime.parse(widget.selectedDate.toString());
                        final String attendanceDateOnly = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                        ).toString();
                        final String attendanceDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          adminAttendanceProvider.dialogIntimeDateTime.hour,
                          adminAttendanceProvider.dialogIntimeDateTime.minute,
                          adminAttendanceProvider.dialogIntimeDateTime.second,
                        ).toString();

                        Provider.of<AdminAttenDanceServices>(context, listen: false).addEmpattendance(
                          usedRemarks: adminAttendanceProvider.dialogNotesController.text,
                          setEmployeId: widget.selectedEmp.empId,
                          attendanceDateEmp: attendanceDateOnly,
                          attendanceTime: attendanceDateTime,
                        ).then((value) {
                          showtoastmessage('Punch recorded successfully');
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Provider.of<AdminAttenDanceServices>(context, listen: false)
                              .toDayDateAttendance(widget.selectedEmp.attendenceDate);
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: size.width * 0.05,
                          ),
                          SizedBox(width: size.width * 0.02),
                          Text(
                            'Add Punch',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.height * 0.016,
                              fontWeight: FontWeight.w600,
                              fontFamily: fontInterSemiBoldString,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}