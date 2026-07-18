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
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/selfie_punch_provider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';

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
  final ScrollController _scrollController = ScrollController();



  // GlobalKey to track dialog
  final GlobalKey _dialogKey = GlobalKey();

  // Add this inside _HomeScreenState class
  @override
  void initState() {
    super.initState();
    _homeProvider = Provider.of<HomeProvider>(context, listen: false);
    _initHome();
  }

  Future<void> _initHome() async {
    // Await company/menu setup so selectedcurentcompany is ready before attendance fetch
    await _homeProvider.homeLoadDatas(context);
    if (!mounted) return;

    if (curentUser['Role'] != 'Admin') {
      _homeProvider.startWorkingHoursTimer(context);
      // Periodic attendance refresh every 60 seconds for non-admin users
      _startUserAttendanceRefreshTimer();
    }

    // Load admin attendance on init
    if (curentUser['Role'] == 'Admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AdminAttenDanceServices>(context, listen: false)
            .toDayDateAttendance(DateTime.now());
      });
      _startAutoRefreshTimer();
    }
  }

  Timer? _autoRefreshTimer;
  Timer? _userAttendanceRefreshTimer;

  void _startAutoRefreshTimer() {
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      final attendanceService = Provider.of<AdminAttenDanceServices>(context, listen: false);
      if (mounted) {
        attendanceService.toDayDateAttendance(DateTime.now(), isBackground: true);
      }
    });
  }

  void _startUserAttendanceRefreshTimer() {
    _userAttendanceRefreshTimer = Timer.periodic(Duration(seconds: 60), (timer) {
      if (mounted && curentUser['Role'] != 'Admin') {
        final selfiePunchProvider = Provider.of<SelfiePunchProvider>(context, listen: false);
        selfiePunchProvider.checkLastPunch(curentUser['Id'], context).then((_) {
          _homeProvider.refreshWorkingHours(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _homeProvider.stopWorkingHoursTimer();
    _isDialogShowing = false;
    _isCalculating = false;
    _autoRefreshTimer?.cancel();
    _userAttendanceRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final homeProvider = Provider.of<HomeProvider>(context);
    Provider.of<LanguageProvider>(context);
    safeAreaBgAndTextColor(context);
    return Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        appBar: _buildAppBar(size, homeProvider),
        body: refreshIndicatorDesign(
          onRefreshOntap: () async {
            _homeProvider.homeLoadDatas(context, forceRefresh: true);
            if (curentUser['Role'] == 'Admin') {
              Provider.of<AdminAttenDanceServices>(context, listen: false).toDayDateAttendance(DateTime.now());
            }
          },
          widgetDesign: Scrollbar(
            controller: _scrollController,
            thickness: 6,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  if(curentUser['Role'] != 'Admin') ...[
                    buildDateHeader(size),
                  ] else ...[
                    buildAttendanceBoard(size, mounted,
                      onAllPressed:(){
                        homeProvider.changeSelectBottomBar(1);
                      },
                    )
                  ],
                  _buildGridMenu(size, homeProvider),
                  const LeaderboardWidget(),
                ],
              ),
            ),
          ),
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
    homeProvider.homepageMenuGet(context);
    final menuList = homeProvider.homeGridOptionList;
    
    return Column(
      children: [
        // Grid Menu
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.03,
            vertical: size.width * 0.02,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: menuList.length + 1,
          itemBuilder: (context, index) {
            if (index == menuList.length) {
              if(curentUser['Role'] == 'Admin') {
                return _ScrollDownButton(size: size, controller: _scrollController);
              } else {
                return null;
              }
            }
            return _buildMenuItem(size, homeProvider, menuList[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem(Size size, HomeProvider homeProvider, dynamic menuItem, int index) {
    final List<Color> creativeColors = [
      const Color(0xff1864EC), // Theme Blue
      const Color(0xff10B981), // Emerald Green
      const Color(0xffF59E0B), // Amber Yellow
      const Color(0xffEF4444), // Red
      const Color(0xff8B5CF6), // Purple
      const Color(0xffEC4899), // Pink
      const Color(0xff06B6D4), // Cyan
      const Color(0xffF97316), // Orange
      const Color(0xff14B8A6), // Teal
      const Color(0xff6366F1), // Indigo
    ];
    
    final Color itemColor = menuItem.color ?? creativeColors[index % creativeColors.length];

    return GestureDetector(
      onTap: () {
        homeProvider.homeMenuiHandleSubmit(context, menuItem);
      },
      child: Container(
        padding: EdgeInsets.all(size.width * 0.02),
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorConst.isDark 
                ? Colors.white.withOpacity(0.06) 
                : Colors.black.withOpacity(0.04),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(  
              color: ColorConst.isDark 
                  ? Colors.black.withOpacity(0.2) 
                  : Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.width * 0.02),
              decoration: BoxDecoration(
                color: itemColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: menuItem.image.isEmpty
                  ? Icon(
                      Icons.notifications_active_outlined,
                      color: itemColor,
                      size: size.width * 0.055,
                    )
                  : Image.asset(
                      menuItem.image,
                      color: itemColor,
                      height: size.width * 0.055,
                      width: size.width * 0.055,
                    ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                menuItem.title,
                style: TextStyle(
                  color: ColorConst.black,
                  fontFamily: fontInterSemiBoldString,
                  fontWeight: FontWeight.w600,
                  fontSize: size.width * 0.025,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

class _ScrollDownButton extends StatefulWidget {
  final Size size;
  final ScrollController controller;
  const _ScrollDownButton({required this.size, required this.controller});

  @override
  State<_ScrollDownButton> createState() => _ScrollDownButtonState();
}

class _ScrollDownButtonState extends State<_ScrollDownButton> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.controller.animateTo(
          widget.controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: EdgeInsets.all(widget.size.width * 0.02),
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorConst.themeColor.withOpacity(0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConst.themeColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation.value),
                  child: child,
                );
              },
              child: Container(
                padding: EdgeInsets.all(widget.size.width * 0.02),
                decoration: BoxDecoration(
                  color: ColorConst.themeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: ColorConst.themeColor,
                  size: widget.size.width * 0.055,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                leaderboardString,
                style: TextStyle(
                  color: ColorConst.themeColor,
                  fontFamily: fontInterSemiBoldString,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.size.width * 0.025,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
