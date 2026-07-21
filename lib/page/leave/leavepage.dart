// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/leavetype/getuserList.dart';
import 'package:tax_hrm/page/leave/leave_page_design.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/leaveProviders.dart';
import 'package:tax_hrm/provider/leave_user_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class LeaveViewPage extends StatefulWidget {
  const LeaveViewPage({super.key});

  @override
  State<LeaveViewPage> createState() => _LeaveViewPageState();
}

class _LeaveViewPageState extends State<LeaveViewPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLeaveData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final leaveMastServices = Provider.of<LeaveMastServices>(context);
    Provider.of<LanguageProvider>(context);
    return Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        appBar: showBottomAppBar(leaveString, size, centerTitles: false),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: size.height * 0.10),
          child: iconWithTextBtnDesign(
            size,
            applyNewLeaveString,
            isIcon: false,
            onTap: () {
              leaveMastServices.resetLeaveForm();
              leaveMastServices.leaveHandleSubmit(context,false, leaveData: null);
            },
            isgradient: true,
            isImage: false,
          ),
        ),
        body: leaveMastServices.islodering
            ? buildShimmerContent(size)
            : Column(
                children: [
                  buildStatisticsCard(size,Provider.of<LeaveUserProvider>(context)),
                  heightSpacer(size.height*0.01),
                  _buildTabBar(size, leaveMastServices),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRefreshableLeaveList(
                          size,
                          leaveMastServices,
                          leaveMastServices.filteredUpcomingLeaves,
                          isUpcoming: true,
                        ),
                        _buildRefreshableLeaveList(
                          size,
                          leaveMastServices,
                          leaveMastServices.filteredPastLeaves,
                          isUpcoming: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      );
  }

  Future<void> _refreshLeaveData() async {
    final leaveMastServices = Provider.of<LeaveMastServices>(context, listen: false);
    final leaveUserServices = Provider.of<LeaveUserProvider>(context, listen: false);
    await leaveMastServices.getUserLeaveLists();
    await leaveUserServices.loadPaidLeaveSummary();
  }

  Widget _buildRefreshableLeaveList(
    Size size,
    LeaveMastServices leaveMastServices,
    List<LeaveListData> leaves, {
    required bool isUpcoming,
  }) {
    return RefreshIndicator(
      color: ColorConst.themeColor,
      onRefresh: _refreshLeaveData,
      child: leaves.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: size.height * 0.55,
                  child: leaveMastServices.buildLeaveList(size, leaves, isUpcoming: isUpcoming),
                ),
              ],
            )
          : leaveMastServices.buildLeaveList(size, leaves, isUpcoming: isUpcoming),
    );
  }
  
  Widget _buildTabBar(Size size, LeaveMastServices leaveMastServices) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.02),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: ColorConst.themeColor,
            unselectedLabelColor: ColorConst.bottomIconColor,
            indicatorColor: ColorConst.themeColor,
            indicatorWeight: 3.0, 
            indicatorSize: TabBarIndicatorSize.label, 
            labelStyle: TextStyle(fontFamily: fontInterSemiBoldString, fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontFamily: fontInterRegularString, fontWeight: FontWeight.w400, fontSize: 14),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upcoming, size: 18),
                    SizedBox(width: 8),
                    Text(upcomingString),
                    if (leaveMastServices.filteredUpcomingLeaves.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                        child: Text('${leaveMastServices.filteredUpcomingLeaves.length}', style: TextStyle(color: ColorConst.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 18),
                    SizedBox(width: 8),
                    Text(pastString),
                    if (leaveMastServices.filteredPastLeaves.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
                        child: Text('${leaveMastServices.filteredPastLeaves.length}', style: TextStyle(color: ColorConst.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
