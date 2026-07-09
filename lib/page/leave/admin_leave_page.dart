// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/leave/admin_leave_design_pages/approve_design_page.dart';
import 'package:tax_hrm/page/leave/admin_leave_design_pages/pending_design_page.dart';
import 'package:tax_hrm/page/leave/admin_leave_design_pages/reject_design_page.dart';
import 'package:tax_hrm/provider/admin_leave_provider.dart';
import 'package:tax_hrm/provider/leaveProviders.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/page/leave/leave_page_design.dart';

class AdminLeavePage extends StatefulWidget {
  const AdminLeavePage({super.key});

  @override
  State<AdminLeavePage> createState() => _AdminLeavePageState();
}

class _AdminLeavePageState extends State<AdminLeavePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminLeaveProvider = Provider.of<AdminLeaveProvider>(context, listen: false);
      adminLeaveProvider.initializeData();
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
    final leaveAdminProvider = Provider.of<AdminLeaveProvider>(context);
    return Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        appBar: showBottomAppBar(
          adminLeavePage,
          size,
          centerTitles: false,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: leaveAdminProvider.islodering ? SizedBox() : iconWithTextBtnDesign(size,applyNewLeaveString,isIcon: false,onTap: () {
          LeaveMastServices().resetLeaveForm();
          LeaveMastServices().leaveHandleSubmit(context,false, leaveData: null);
        },isgradient: true,isImage: false,),
        body: leaveAdminProvider.islodering ? buildShimmerContent(size) : Column(
            children: [
              /// TAB BAR
              Container(
                color: ColorConst.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.green,
                  labelColor: ColorConst.black,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(pendingString),
                          if(leaveAdminProvider.pendingLeaves.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                leaveAdminProvider.pendingLeaves.length.toString(),
                                style: TextStyle(color: Colors.white,fontSize: 11,fontWeight: FontWeight.bold,),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(approveString),
                          if(leaveAdminProvider.approvedLeaves.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${leaveAdminProvider.approvedLeaves.length}',
                                style: TextStyle(color: Colors.white,fontSize: 11,fontWeight: FontWeight.bold,),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(rejectString),
                          if(leaveAdminProvider.rejectedLeaves.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${leaveAdminProvider.rejectedLeaves.length}',
                                style: TextStyle(color: Colors.white,fontSize: 11,fontWeight: FontWeight.bold,),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// TAB VIEW
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                  /// Pending Tab
                  RefreshIndicator(
                    color: ColorConst.themeColor,
                    onRefresh: () => leaveAdminProvider.initializeData(),
                    child: leaveAdminProvider.pendingLeaves.isEmpty ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: size.height * 0.65,
                          child: noDataFoundsDesign(size, noDataFoundsString,nodataFoundsImagString),
                        ),
                      ],
                    ) : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 70),
                    itemCount: leaveAdminProvider.pendingLeaves.length,
                    itemBuilder: (context, index) {
                      return  Padding(
                        padding: const EdgeInsets.only(left: 10,right: 10,top: 5),
                        child: LeaveRequestCard(
                          name: "${leaveAdminProvider.pendingLeaves[index].firstName} ${leaveAdminProvider.pendingLeaves[index].lastName}",
                          reason: leaveAdminProvider.pendingLeaves[index].remarks ?? "N/A",
                          date: "${dateFormatdate(DateTime.parse(leaveAdminProvider.pendingLeaves[index].fromDate.toString()))} to ${dateFormatdate(DateTime.parse(leaveAdminProvider.pendingLeaves[index].toDate.toString()))}",
                          status: "Pending".toUpperCase(),
                          onEdit: () {
                            LeaveMastServices().resetLeaveForm();
                            LeaveMastServices().leaveHandleSubmit(context,true, leaveData: leaveAdminProvider.pendingLeaves[index]);
                          },
                          onDelete: () {
                            showDeleteDialog(context,size,yesOntap: () {
                              Navigator.pop(context);
                              LeaveMastServices().deleteleave(leaveAdminProvider.pendingLeaves[index].cguid.toString(),context,).then((value) async {
                                await leaveAdminProvider.initializeData();
                              });
                            },noOnTap: (){Navigator.pop(context);});
                          },
                          onReject: () {
                            leaveAdminProvider.rejectLeaveRequest(
                              context,
                              leaveAdminProvider.pendingLeaves[index],
                            );
                          },
                          onApprove: () {
                            leaveAdminProvider.approveLeaveRequest(
                              context,
                              leaveAdminProvider.pendingLeaves[index],
                            );
                          },
                        ),
                      );
                    },
                  ),
                  ),
                  
                  /// Approve Tab
                  RefreshIndicator(
                    color: ColorConst.themeColor,
                    onRefresh: () => leaveAdminProvider.initializeData(),
                    child: leaveAdminProvider.approvedLeaves.isEmpty ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: size.height * 0.65,
                          child: noDataFoundsDesign(size, noDataFoundsString,nodataFoundsImagString),
                        ),
                      ],
                    ) : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 70),
                    itemCount: leaveAdminProvider.approvedLeaves.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 10,right: 10,top: 5),
                        child: LeaveApproveCard(
                          name: "${leaveAdminProvider.approvedLeaves[index].firstName} ${leaveAdminProvider.approvedLeaves[index].lastName}",
                          reason: leaveAdminProvider.approvedLeaves[index].remarks ?? "N/A",
                          date: "${dateFormatdate(DateTime.parse(leaveAdminProvider.approvedLeaves[index].fromDate.toString()))} to ${dateFormatdate(DateTime.parse(leaveAdminProvider.approvedLeaves[index].toDate.toString()))}",
                          status: "Approved".toUpperCase(),
                          onEdit: () {
                            LeaveMastServices().resetLeaveForm();
                            LeaveMastServices().leaveHandleSubmit(context,true, leaveData: leaveAdminProvider.approvedLeaves[index]);
                          },
                          onDelete: () {
                            showDeleteDialog(context,size,yesOntap: () {
                              Navigator.pop(context);
                              LeaveMastServices().deleteleave(leaveAdminProvider.approvedLeaves[index].cguid.toString(),context,).then((value) async {
                                await leaveAdminProvider.initializeData();
                              });
                            },noOnTap: (){Navigator.pop(context);});
                          }, leaveTypeColor: ColorConst.addNoteImageColors, duration: '', leaveType: leaveAdminProvider.approvedLeaves[index].leaveTypeFName.toString(),
                        ),
                      );
                    },
                  ),
                  ),
                  
                  /// Reject Tab
                  RefreshIndicator(
                    color: ColorConst.themeColor,
                    onRefresh: () => leaveAdminProvider.initializeData(),
                    child: leaveAdminProvider.rejectedLeaves.isEmpty ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: size.height * 0.65,
                          child: noDataFoundsDesign(size, noDataFoundsString,nodataFoundsImagString),
                        ),
                      ],
                    ) : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 70),
                    itemCount: leaveAdminProvider.rejectedLeaves.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 10,right: 10,top: 5),
                        child: LeaveRejectCard(
                          name: "${leaveAdminProvider.rejectedLeaves[index].firstName} ${leaveAdminProvider.rejectedLeaves[index].lastName}",
                          reason: leaveAdminProvider.rejectedLeaves[index].remarks ?? "N/A",
                          date: "${dateFormatdate(DateTime.parse(leaveAdminProvider.rejectedLeaves[index].fromDate.toString()))} to ${dateFormatdate(DateTime.parse(leaveAdminProvider.rejectedLeaves[index].toDate.toString()))}",
                          status: "Rejected".toUpperCase(),
                          onEdit: () {
                            LeaveMastServices().resetLeaveForm();
                            LeaveMastServices().leaveHandleSubmit(context,true, leaveData: leaveAdminProvider.rejectedLeaves[index]);
                          },
                          onDelete: () {
                            showDeleteDialog(context,size,yesOntap: () {
                              Navigator.pop(context);
                              LeaveMastServices().deleteleave(leaveAdminProvider.rejectedLeaves[index].cguid.toString(),context,).then((value) async {
                                await leaveAdminProvider.initializeData();
                              });
                            },noOnTap: (){Navigator.pop(context);});
                          },
                        ),
                      );
                    },
                  ),
                  ),
                  ],
                ),
              ),
              
            ],
        ),
      );
  }

  Color getLeaveTypeColor(String leaveType) {
    final type = leaveType.toLowerCase();
    if (type.contains('paid')) return Colors.green;
    if (type.contains('unpaid')) return Colors.orange;
    if (type.contains('casual')) return Colors.blue;
    if (type.contains('sick')) return Colors.purple;
    if (type.contains('annual')) return Colors.teal;
    return Colors.grey;
  }
}
