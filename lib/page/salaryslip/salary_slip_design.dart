// ignore_for_file: unused_element, strict_top_level_inference

// NEW: Working Hours Card Widget
  import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:tax_hrm/provider/salaryStructures.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';

Widget buildWorkingHoursCard(Size size, SalaryStructureProvider provider) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
    padding: EdgeInsets.all(size.width * 0.04),
    decoration: BoxDecoration(
      color: ColorConst.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: ColorConst.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 5,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 4,
              height: size.height * 0.025,
              decoration: BoxDecoration(
                color: ColorConst.themeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            widthSpacer(size.width * 0.03),
            Text(
              'Working Hours',
              style: TextStyle(
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.w700,
                fontFamily: fontInterBoldString,
                color: ColorConst.black,
              ),
            ),
          ],
        ),
        
        heightSpacer(size.height * 0.02),
        
        // Hours Grid
        Row(
          children: [
            _buildHourCard(
              size,
              title: 'Total Hours',
              value: provider.totalWorkingHours > 0 ? provider.formattedTotalWorkingHours : '0.00',
              icon: Icons.access_time,
              color: const Color(0xFF1A73E8),
            ),
            widthSpacer(size.width * 0.03),
            _buildHourCard(
              size,
              title: 'Break Hours',
              value: provider.formattedTotalBreakHours,
              icon: Icons.free_breakfast,
              color: const Color(0xFFF28C18),
            ),
          ],
        ),
        
        heightSpacer(size.height * 0.015),
        
        Row(
          children: [
            _buildHourCard(
              size,
              title: 'Net Hours',
              value: provider.formattedNetWorkingHours,
              icon: Icons.work,
              color: const Color(0xFF15A04E),
            ),
            widthSpacer(size.width * 0.03),
            _buildHourCard(
              size,
              title: 'Remaining Hours',
              value: provider.formattedRemainingHours,
              icon: Icons.schedule,
              color: const Color(0xFF9C27B0),
            ),
          ],
        ),
        
        heightSpacer(size.height * 0.015),
        
        // Overtime Section
        if (provider.overtimeHours > 0)
          Container(
            padding: EdgeInsets.all(size.width * 0.03),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, size: size.width * 0.045, color: const Color(0xFF1A73E8)),
                    widthSpacer(size.width * 0.02),
                    Text(
                      'Overtime Hours',
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        fontWeight: FontWeight.w600,
                        fontFamily: fontInterSemiBoldString,
                        color: const Color(0xFF1A73E8),
                      ),
                    ),
                  ],
                ),
                Text(
                  provider.formattedOvertimeHours,
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w700,
                    fontFamily: fontInterBoldString,
                    color: const Color(0xFF1A73E8),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

  // NEW: Individual Hour Card Widget
Widget _buildHourCard(Size size, {
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.03,
        vertical: size.height * 0.012,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: size.width * 0.045, color: color),
          widthSpacer(size.width * 0.025),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.w700,
                    fontFamily: fontInterBoldString,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: size.width * 0.025,
                    fontWeight: FontWeight.w500,
                    fontFamily: fontInterMediumString,
                    color: ColorConst.grey,
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


Widget paySlipTextDesign({size, title, value, color}) {
  return Padding(
    padding: EdgeInsets.all(size.width * 0.015),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.w600, fontFamily: fontInterSemiBoldString, color: color ?? ColorConst.black)),
        Text(value, style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.w600, fontFamily: fontInterSemiBoldString, color: color ?? ColorConst.black)),
      ],
    ),
  );
}


// ==================== SHIMMER CONTENT ====================
Widget buildShimmerSalaryContent(Size size) {
  return SingleChildScrollView(
    child: Column(
      children: [
        // Header Shimmer
        _buildShimmerHeader(size),
        
        // Working Hours Card Shimmer
        _buildShimmerWorkingHoursCard(size),
        
        // Salary Details Container Shimmer
        _buildShimmerSalaryContainer(size),
      ],
    ),
  );
}

Widget _buildShimmerHeader(Size size) {
  return Shimmer(
    // baseColor: Colors.grey.shade300,
    // highlightColor: Colors.grey.shade100,
    child: Container(
      padding: EdgeInsets.all(size.width * 0.02),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        boxShadow: [
          BoxShadow(color: ColorConst.grey, spreadRadius: 1.1, blurRadius: 0.8),
        ],
      ),
      child: Column(
        children: [
          // Month Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: size.width * 0.08, height: size.width * 0.05, color: ColorConst.white),
              Container(width: size.width * 0.3, height: size.width * 0.045, color: ColorConst.white),
              Container(width: size.width * 0.08, height: size.width * 0.05, color: ColorConst.white),
            ],
          ),
          
          // Donut Chart and Legend
          Padding(
            padding: EdgeInsets.symmetric(vertical: size.height * 0.05),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Donut Chart Placeholder
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                  child: Container(
                    width: size.width * 0.25,
                    height: size.width * 0.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorConst.white,
                    ),
                  ),
                ),
                
                // Legend Placeholder
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: size.width * 0.4, height: size.height * 0.025, color: ColorConst.white),
                    SizedBox(height: size.height * 0.025),
                    // Earning Row
                    Row(
                      children: [
                        Container(width: size.width * 0.035, height: size.width * 0.035, decoration: BoxDecoration(shape: BoxShape.circle, color: ColorConst.white)),
                        SizedBox(width: size.width * 0.03),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: size.width * 0.2, height: size.height * 0.02, color: ColorConst.white),
                            SizedBox(height: size.height * 0.005),
                            Container(width: size.width * 0.15, height: size.height * 0.015, color: ColorConst.white),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.015),
                    // Deduction Row
                    Row(
                      children: [
                        Container(width: size.width * 0.035, height: size.width * 0.035, decoration: BoxDecoration(shape: BoxShape.circle, color: ColorConst.white)),
                        SizedBox(width: size.width * 0.03),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: size.width * 0.2, height: size.height * 0.02, color: ColorConst.white),
                            SizedBox(height: size.height * 0.005),
                            Container(width: size.width * 0.15, height: size.height * 0.015, color: ColorConst.white),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildShimmerWorkingHoursCard(Size size) {
  return Shimmer(
    // baseColor: Colors.grey.shade300,
    // highlightColor: Colors.grey.shade100,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: ColorConst.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: ColorConst.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(width: 4, height: size.height * 0.025, color: ColorConst.white),
              SizedBox(width: size.width * 0.03),
              Container(width: size.width * 0.3, height: size.height * 0.025, color: ColorConst.white),
            ],
          ),
          SizedBox(height: size.height * 0.02),
          
          // Row 1
          Row(
            children: [
              Expanded(
                child: Container(
                  height: size.height * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: ColorConst.white,
                  ),
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Container(
                  height: size.height * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: ColorConst.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.012),
          
          // Row 2
          Row(
            children: [
              Expanded(
                child: Container(
                  height: size.height * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: ColorConst.white,
                  ),
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Container(
                  height: size.height * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: ColorConst.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildShimmerSalaryContainer(Size size) {
  return Shimmer(
    child: Container(
      margin: EdgeInsets.all(size.width * 0.04),
      padding: EdgeInsets.only(bottom: size.height * 0.005),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
      ),
      child: Column(
        children: [
          // Basic Salary Shimmer
          _buildShimmerSalaryRow(size),
          // PF Shimmer
          _buildShimmerSalaryRow(size),
          // ESIC Shimmer
          _buildShimmerSalaryRow(size),
          // Conveyance Shimmer
          _buildShimmerSalaryRow(size),
          // HRA Shimmer
          _buildShimmerSalaryRow(size),
          // Divider
          Container(height: 1, color: ColorConst.white),
          SizedBox(height: size.height * 0.01),
          // Payout Amount Shimmer
          _buildShimmerSalaryRow(size),
        ],
      ),
    ),
  );
}

Widget _buildShimmerSalaryRow(Size size) {
  return Padding(
    padding: EdgeInsets.all(size.width * 0.015),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(width: size.width * 0.35, height: size.height * 0.02, color: ColorConst.white),
        Container(width: size.width * 0.25, height: size.height * 0.02, color: ColorConst.white),
      ],
    ),
  );
}
