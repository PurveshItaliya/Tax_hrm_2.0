// ignore_for_file: void_checks, use_build_context_synchronously, empty_catches, strict_top_level_inference, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/attendance/customdialog.dart';
import 'package:tax_hrm/page/home/home_design_screen.dart';
import 'package:tax_hrm/page/home/leaderborder.dart';
import 'package:tax_hrm/provider/adminattendance.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Flag to prevent multiple dialog opens
  bool _isDialogShowing = false;
  bool _isCalculating = false;
  late final HomeProvider _homeProvider;
  
  // Flag for expandable grid menu (Admin only)
  bool _isGridExpanded = false;

  // Add this at the top of your _HomeScreenState class
  void useEffect(Function callback, List<dynamic> dependencies) {
    bool isFirstRun = true;
    
    void effect() {
      final dispose = callback();
      isFirstRun = false;
      return dispose;
    }
    
    if (isFirstRun) {
      effect();
    }
  }
  
  // GlobalKey to track dialog
  final GlobalKey _dialogKey = GlobalKey();

  // Add this inside _HomeScreenState class
  @override
  void initState() {
    super.initState();
    _homeProvider = Provider.of<HomeProvider>(context, listen: false);
    _homeProvider.homeLoadDatas(context);
    if(curentUser['Role'] != 'Admin'){
      _homeProvider.startWorkingHoursTimer(context);
    }
    
    // Start auto refresh timer for admin attendance board
    if (curentUser['Role'] == 'Admin') {
      _startAutoRefreshTimer();
    }
  }

  Timer? _autoRefreshTimer;

  void _startAutoRefreshTimer() {
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      final attendanceService = Provider.of<AdminAttenDanceServices>(context, listen: false);
      if (mounted) {
        attendanceService.toDayDateAttendance(DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _homeProvider.stopWorkingHoursTimer();
    _isDialogShowing = false;
    _isCalculating = false;
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final homeProvider = Provider.of<HomeProvider>(context);
    safeAreaBgAndTextColor(context);
    return Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        appBar: _buildAppBar(size, homeProvider),
        body: Column(
          children: [
            if(curentUser['Role'] != 'Admin') ...[
              buildDateHeader(size),
            ] else ...[
              buildAttendanceBoard(size, useEffect, mounted,
                onAllPressed:(){
                  lastBottomIndex = 1;
                  selectedIndex = 1;
                  fabSelected = false;
                  homeProvider.notifyListeners();
                },
              )
            ],
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildGridMenu(size, homeProvider),
                    // if(curentUser['Role'] == 'Admin') ...{
                      LeaderboardWidget(),
                    // }
                  ],
                ),
              ),
            )
          ],
        ),
      );
  }

  PreferredSizeWidget _buildAppBar(Size size, HomeProvider homeProvider) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ColorConst.white,
      toolbarHeight: size.height * 0.08,
      title: GestureDetector(
        onTap: curentUser['Role'] == 'Admin' 
            ? () { homeProvider.companyHandleSubmit(context, size: size); } 
            : null,
        child: Row(
          children: [
            Expanded(
              child: Container(
                width: size.width * 0.72,
                padding: EdgeInsets.all(size.width * 0.01),
                decoration: BoxDecoration(border: Border.all(color: ColorConst.grey, width: 2),borderRadius: BorderRadius.circular(20),),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(size.width * 0.02),
                      decoration: BoxDecoration(shape: BoxShape.circle,color: ColorConst.greyOpicityColor,),
                      child: SvgPicture.asset(companyImageString),
                    ),
                    widthSpacer(size.width * 0.015),
                    Expanded(
                      child: Text(
                        selectedcurentcompany == null ? "" : selectedcurentcompany!.companyName.toString(),
                        style: TextStyle(color: ColorConst.black,fontFamily: fontInterSemiBoldString,fontWeight: FontWeight.w600,fontSize: size.width * 0.030,),
                      ),
                    ),
                    if (curentUser['Role'] == 'Admin') ...[
                      widthSpacer(size.width * 0.015),
                      Icon(
                        Icons.arrow_drop_down_outlined,
                        color: Colors.grey,
                        size: size.width * 0.09,
                      ),
                    ]
                  ],
                ),
              ),
            ),
            if(curentUser['Role'] != 'Admin') ...[
              widthSpacer(size.width * 0.015),
              GestureDetector(
                onTap: () => _showStatisticsDialog(size, homeProvider),
                child: _isCalculating
                    ? SizedBox(
                        width: size.width * 0.09,
                        height: size.width * 0.09,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorConst.themeColor,
                        ),
                      )
                    : Icon(
                        Icons.bar_chart_outlined,
                        color: Colors.grey,
                        size: size.width * 0.09,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridMenu(Size size, HomeProvider homeProvider) {
    final bool isAdmin = curentUser['Role'] == 'Admin';
    final menuList = homeProvider.homeGridOptionList;
    
    // For Admin: Show only 6 items when not expanded, show all when expanded
    // For non-Admin: Show all items
    final int initialVisibleCount = 5;
    final int visibleCount = _isGridExpanded ? menuList.length : initialVisibleCount;
    
    // Create display list with menu items
    List<dynamic> displayList = [];
    if (isAdmin) {
      displayList = menuList.take(visibleCount).toList();
    } else {
      displayList = menuList;
    }
    
    final bool showViewMore = isAdmin && menuList.length > initialVisibleCount && !_isGridExpanded;
    final bool showShowLess = isAdmin && _isGridExpanded;
    
    return Column(
      children: [
        // Grid Menu
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(size.width * 0.02),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 1.2,
          ),
          itemCount: displayList.length + (showViewMore || showShowLess ? 1 : 0),
          itemBuilder: (context, index) {
            // If this is the last item and we need to show toggle button
            if ((showViewMore || showShowLess) && index == displayList.length) {
              return _buildToggleCard(size, showViewMore);
            }
            return _buildMenuItem(size, homeProvider, displayList[index]);
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem(Size size, HomeProvider homeProvider, dynamic menuItem) {
    return GestureDetector(
      onTap: () {
        homeProvider.homeMenuiHandleSubmit(context, menuItem);
      },
      child: Container(
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: ColorConst.grey,
              spreadRadius: 0.1,
              blurRadius: 0.1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset(
              menuItem.image,
              color: menuItem.color,
              height: size.width * 0.07,
              width: size.width * 0.07,
            ),
            Text(
              menuItem.title,
              style: TextStyle(
                color: ColorConst.black,
                fontFamily: fontInterSemiBoldString,
                fontWeight: FontWeight.w600,
                fontSize: 10.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard(Size size, bool showViewMore) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isGridExpanded = !_isGridExpanded;
        });
      },
      child: Container(
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ColorConst.themeColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConst.themeColor.withOpacity(0.1),
              spreadRadius: 0.1,
              blurRadius: 0.1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showViewMore ? Icons.expand_more : Icons.expand_less,
                  size: size.width * 0.08,
                  color: ColorConst.themeColor,
                ),
                if (showViewMore) ...[
                  SizedBox(height: size.height * 0.004),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.03,
                      vertical: size.height * 0.003,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_homeProvider.homeGridOptionList.length - 6} more',
                      style: TextStyle(
                        fontSize: size.width * 0.022,
                        fontWeight: FontWeight.bold,
                        color: ColorConst.themeColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: size.height * 0.008),
            Text(
              showViewMore ? 'View More' : 'Show Less',
              style: TextStyle(
                fontSize: size.width * 0.032,
                fontWeight: FontWeight.w600,
                color: ColorConst.themeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show Statistics Dialog - Prevents multiple opens
  Future<void> _showStatisticsDialog(Size size, HomeProvider homeProvider) async {
    // Check if dialog is already showing
    if (_isDialogShowing || _isCalculating) {
      return;
    }
    
    // Check if widget is still mounted
    if (!mounted) {
      return;
    }
    
    // Set calculating flag to true
    setState(() {
      _isCalculating = true;
    });

    try {
      // Calculate statistics
      await homeProvider.calculateTime(context);
      
      // Check again after calculation
      if (!mounted || _isDialogShowing) {
        setState(() {
          _isCalculating = false;
        });
        return;
      }
      
      // Set dialog showing flag
      _isDialogShowing = true;
      
      // Show dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => WillPopScope(
          onWillPop: () async {
            // Reset flag when dialog is closed via back button
            _isDialogShowing = false;
            return true;
          },
          child: CustomDialogView(
            key: _dialogKey,
            image: 'assets/images/Statistics.gif',
            title: "Statistics",
            monthStatus: Text(
              homeProvider.getStatisticsText(),
              style: customeHeadingTextsize(size, size.height * 0.020),
            ),
            breakStatus: homeProvider.getTodayBreakTime(context),
            paidLeaveHours: homeProvider.paidLeaveHours,
            holidayCount: homeProvider.holidayHoursCount,
            totalBreak: homeProvider.totalBreakHours,
          ),
        ),
      );
      
      // Reset dialog showing flag after dialog is closed
      _isDialogShowing = false;
      
    } catch (e) {
      _isDialogShowing = false;
    } finally {
      // Reset calculating flag
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }
    }
  }
}
