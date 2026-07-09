// ignore_for_file: curly_braces_in_flow_control_structures

// Shimmer Widgets
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/leavetype/getuserList.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/leave_user_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/customedropdownfiled.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/spacer.dart';

Widget _buildShimmerStatisticsCard(Size size) {
  return Shimmer(
    child: Container(
      margin: EdgeInsets.all(size.width * 0.03),
      padding: EdgeInsets.all(size.height * 0.015),
      width: size.width,
      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (index) => Column(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
            SizedBox(height: 8),
            Container(width: 50, height: 16, color: Colors.grey.shade400),
            SizedBox(height: 4),
            Container(width: 40, height: 12, color: Colors.grey.shade400),
          ],
        )),
      ),
    ),
  );
}

Widget _buildShimmerLeaveItem(Size size) {
  return Shimmer(
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.03),
      padding: EdgeInsets.all(size.width * 0.03),
      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: size.width * 0.5, height: 16, color: Colors.grey.shade400),
                    SizedBox(height: 8),
                    Container(width: size.width * 0.4, height: 12, color: Colors.grey.shade400),
                  ],
                ),
              ),
              Container(width: size.width * 0.28, height: 30, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(22))),
            ],
          ),
          SizedBox(height: 12),
          Container(width: size.width * 0.6, height: 12, color: Colors.grey.shade400),
          SizedBox(height: 8),
          Row(
            children: [
              Container(width: 60, height: 30, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(20))),
              SizedBox(width: 8),
              Container(width: 60, height: 30, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(20))),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildShimmerTabBar(Size size) {
  return Shimmer(
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.02),
      height: size.height * 0.05,
      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(14)),
    ),
  );
}

Widget buildShimmerContent(Size size) {
  return Column(
    children: [
      _buildShimmerStatisticsCard(size),
      SizedBox(height: size.height * 0.02),
      _buildShimmerTabBar(size),
      SizedBox(height: size.height * 0.02),
      Expanded(
        child: ListView.separated(
          itemCount: 5,
          separatorBuilder: (context, index) => heightSpacer(size.height * 0.01),
          itemBuilder: (context, index) => _buildShimmerLeaveItem(size),
        ),
      ),
    ],
  );
}

Widget buildStatisticsCard(
  Size size,
  LeaveUserProvider leaveUserServices,
) {
  return Container(
    margin: EdgeInsets.only(left: size.width * 0.03, right: size.width * 0.03, top: size.height * 0.02),
    padding: EdgeInsets.all(size.height * 0.015),
    width: size.width,
    decoration: BoxDecoration(color: ColorConst.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: ColorConst.grey, spreadRadius: 0.1, blurRadius: 0.1)]),
    child: Column(
      children: [
        leaveCommanBoxDesign(size,leaveString,balanceString),
        heightSpacer(size.height*0.01),
        leaveCommanBoxDesign(size,paidLeaveString,leaveUserServices.showTotalGainPaidLeaves,fontSize: 15.0,titletextColors: ColorConst.leaveHeadingColor,subtitletextColors: ColorConst.leaveSubHeadingColor),
        heightSpacer(size.height*0.04),
        leaveCommanBoxDesign(size,leaveUsedString,leaveUserServices.showPaidLeaves,fontSize: 15.0,titletextColors: ColorConst.leaveHeadingColor,subtitletextColors: ColorConst.leaveHeadingColor),
      ],
    )
  );
}
  
class StatusStyle {
  final String text;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  
  StatusStyle({
    required this.text,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
  });
}

String getLeaveStatusText(LeaveListData leave) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final fromDate = DateTime.tryParse(leave.fromDate.toString()) ?? DateTime.now();
  final toDate = DateTime.tryParse(leave.toDate.toString()) ?? DateTime.now();
  
  if (leave.approveStatus == 'A') {
    if (fromDate.isAfter(today)) return approvedString;
    else if (fromDate.isAtSameMomentAs(today)) return todayString;
    else if (toDate.isAfter(today) && fromDate.isBefore(today)) return ongoingString;
    else if (toDate.isBefore(today)) return completedString;
  }
  switch (leave.approveStatus) {
    case 'A': return approvedString;
    case 'R': return rejectedString;
    case 'P': return pendingString;
    default: return pendingString;
  }
}

// Build Leave Type Dropdown
Widget buildLeaveTypeDropdown(Size size, LeaveUserProvider provider) {
  if (provider.leaveTypeList.isEmpty) {
    return buildShimmerDropdown(size);
  }
  
  return commonDropDownField(
    size: size,
    onChanged: (value) => provider.selectLeaveType(value),
    listName: provider.leaveTypeList.map((e) => e.leaveTypeFName ?? '').toList(),
    selectedValue: provider.selectedLeaveTypeName,
    hintextString: selectLeaveTypeString,
  );
}

// Build Leave Status Dropdown
Widget buildLeaveStatusDropdown(Size size, LeaveUserProvider provider) {
  if (provider.leaveStatusList.isEmpty) {
    return buildShimmerDropdown(size);
  }
  
  return commonDropDownField(
    size: size,
    onChanged: (value) => provider.selectLeaveStatus(value),
    listName: provider.leaveStatusList.map((e) => e.values).toList(),
    selectedValue: provider.selectedLeaveStatusName,
    hintextString: selectLeaveStatusString,
  );
}


// Build Date Field
Widget buildDateField({
  required TextEditingController controller,
  required String hintText,
  required VoidCallback onPressed,
  required String? Function(String?) validator,
}) {
  return CommonTextField(
    controller: controller,
    readOnly: true,
    hintText: hintText,
    suffixIcon: IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.calendar_today_outlined, color: ColorConst.passwordColor),
    ),
    validator: validator,
  );
}

// Build Leave Duration Display
Widget buildLeaveDurationDisplay(Size size, String leaveDays) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        leaveDurationString,
        style: TextStyle(color: ColorConst.leaveTextColor, fontSize: 15, fontFamily: fontInterMediumString),
      ),
      heightSpacer(size.height * 0.004),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Text(
          "$leaveDays Day${double.parse(leaveDays) > 1 ? 's' : ''}",
          style: TextStyle(color: Colors.blue.shade800, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: fontInterSemiBoldString),
        ),
      ),
    ],
  );
}

// Build Eligible Info
Widget buildEligibleInfo(Size size, LeaveUserProvider provider) {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.orange.shade100.withOpacity(0.5)]),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
            SizedBox(width: 8),
            Text(
              leaveEligibilityString,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem(gainString, provider.showGainCounting, Colors.green),
            _buildInfoItem(usedString, provider.showUsedCounting, Colors.red),
            _buildInfoItem(eligibleString, provider.showEligibleCounting, Colors.blue),
          ],
        ),
      ],
    ),
  );
}

Widget _buildInfoItem(String title, String value, Color color) {
  return Column(
    children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
    ],
  );
}

// Build Shimmer Button
Widget buildShimmerButton(Size size) {
  return Shimmer(
    child: Container(
      width: size.width * 0.5,
      height: size.height * 0.055,
      decoration: BoxDecoration(
        color: ColorConst.white,
        borderRadius: BorderRadius.circular(30),
      ),
    ),
  );
}

// Build Shimmer Body
Widget buildShimmerBody(Size size) {
  return SingleChildScrollView(
    padding: EdgeInsets.all(size.width * 0.03),
    child: Column(
      children: [
        // Shimmer for Chips
        _buildShimmerChips(size),
        heightSpacer(size.height * 0.02),
        
        // Shimmer for Date Fields
        _buildShimmerTextField(size),
        heightSpacer(size.height * 0.02),
        
        _buildShimmerTextField(size),
        heightSpacer(size.height * 0.02),
        
        // Shimmer for Dropdown
        buildShimmerDropdown(size),
        heightSpacer(size.height * 0.02),
        
        // Shimmer for Reason Field
        _buildShimmerTextField(size, lines: 3),
        heightSpacer(size.height * 0.02),
        
        // Shimmer for Duration Display
        _buildShimmerDurationCard(size),
      ],
    ),
  );
}

// Shimmer for Chips
Widget _buildShimmerChips(Size size) {
  return Shimmer(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(3, (index) => Container(
          margin: EdgeInsets.only(right: 8),
          width: size.width * 0.25,
          height: size.height * 0.04,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(30),
          ),
        )),
      ),
    ),
  );
}

// Shimmer for Text Field
Widget _buildShimmerTextField(Size size, {int lines = 1}) {
  return Shimmer(
    child: Container(
      width: size.width,
      height: size.height * 0.06,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

// Shimmer for Dropdown
Widget buildShimmerDropdown(Size size) {
  return Shimmer(
    child: Container(
      width: size.width,
      height: size.height * 0.06,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
    ),
  );
}

// Shimmer for Duration Card
Widget _buildShimmerDurationCard(Size size) {
  return Shimmer(
    child: Container(
      width: size.width,
      height: size.height * 0.08,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

// Build Leave Type Chips
Widget buildLeaveTypeChips(Size size, LeaveUserProvider provider) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(provider.leaveType.length, (index) {
        final bool isSelected = provider.selectedIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => provider.leaveTypeButtonFunction(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? ColorConst.themeColor : ColorConst.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: ColorConst.themeColor, width: 1.2),
              ),
              child: Text(
                provider.leaveType[index],
                style: TextStyle(
                  color: isSelected ? ColorConst.white : ColorConst.themeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

// Employee Dropdown Widget
Widget buildEmployeeDropdown(Size size, LeaveUserProvider leaveProvider, EmployeMastServices empProvider) {
  return CustomDropdown<Employeelists>.searchRequest(
    decoration: CustomDropdownDecoration(
      expandedBorder: Border.all(color: ColorConst.textBorder),
      closedBorder: Border.all(color: ColorConst.textBorder),
      closedBorderRadius: BorderRadius.circular(4.0),
      expandedBorderRadius: BorderRadius.circular(4.0),
      closedFillColor: ColorConst.transparent,
      expandedFillColor: ColorConst.white,
    ),
    initialItem: leaveProvider.selectedEmployee,
    hintText: selectEmployeeString,
    futureRequest: empProvider.getFilterEmployeeList,
    items: empProvider.emplists,
    listItemBuilder: (context, item, isSelected, onItemSelect) {
      return Text(
        "${item.firstName.toString()} ${item.lastName.toString()}",
        style: const TextStyle(
          fontFamily: fontInterMediumString,
          fontSize: 14,
        ),
      );
    },
    headerBuilder: (context, selectedItem, enabled) {
      return Text(
        leaveProvider.selectedEmployee == null
            ? selectEmployeeString
            : "${leaveProvider.selectedEmployee!.firstName.toString()} ${leaveProvider.selectedEmployee!.lastName.toString()}",
        style: TextStyle(
          color: leaveProvider.selectedEmployee == null ? ColorConst.hintextColor : ColorConst.black,
          fontFamily: fontInterMediumString,
          fontSize: 14,
        ),
      );
    },
    onChanged: (value) {
      leaveProvider.selectEmployee(value);
    },
  );
}

