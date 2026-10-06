import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tax_hrm/api/visit_api.dart';
import 'package:tax_hrm/controllers/visit_controller.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/visit/create_visit_screen.dart';
import 'package:tax_hrm/page/visit/visit_camera_screen.dart';
import 'package:tax_hrm/page/visit/visit_details_screen.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class VisitScreen extends StatefulWidget {
  const VisitScreen({super.key});

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isFirstLoad = true;
  List<dynamic> _visits = [];
  final VisitApis _visitApis = VisitApis();
  final VisitController _visitController = Get.put(VisitController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchVisits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchVisits() async {
    developer.log('--- Triggering Visit List Refresh ---', name: 'VisitScreen');
    setState(() { _isLoading = true; });
    try {
      String companyId = selectedcurentcompany?.companyId.toString() ?? '1092';
      String empId = curentUser != null ? (curentUser['Id'] ?? curentUser['id'] ?? '0').toString() : '0';
      String role = curentUser != null ? (curentUser['Role'] ?? curentUser['role'] ?? '') : '';

      String assignTo = (role == 'Admin') ? '0' : empId;

      var response = await _visitApis.getVisitList(companyId, '', assignTo);
      if (mounted) {
        setState(() {
          _visits = response;
          if (_isFirstLoad) {
            _isFirstLoad = false;
            bool hasInProgress = _visits.any((v) {
              String status = (v['VisitStatus']?.toString() ?? '').toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
              return status == 'inprogress' || status == 'started' || status == 'start' || status == 'ongoing';
            });
            if (hasInProgress) {
              _tabController.index = 1;
            }
          }
        });
      }
    } catch (e) {
      showtoastmessage('Failed to refresh visit list');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _startVisit(Map<String, dynamic> visit) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const VisitCameraScreen()),
    );
    if (result == null || !mounted) return;

    File? capturedFile = result['file'] as File?;
    String latitude = result['latitude']?.toString() ?? '';
    String longitude = result['longitude']?.toString() ?? '';

    if (capturedFile == null) {
      showtoastmessage('No image captured. Visit not started.');
      return;
    }

    _visitController.capturedImage.value = capturedFile;
    _visitController.currentLatitude.value = latitude;
    _visitController.currentLongitude.value = longitude;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    await _visitController.startVisit(context, visit);
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    _fetchVisits();
  }

  Future<void> _completeVisit(Map<String, dynamic> visit) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Mark as Complete'),
        content: const Text('Are you sure you want to mark this visit as complete?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    ) ?? false;
    if (!confirm) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    await _visitController.completeVisit(context, visit);
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    _fetchVisits();
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty || rawDate == 'null') return 'N/A';
    try {
      DateTime parsed = DateTime.parse(rawDate);
      return DateFormat('dd MMM, hh:mm a').format(parsed);
    } catch (_) {
      return rawDate.substring(0, 10);
    }
  }

  Widget _buildVisitList(List<dynamic> list, String tabType) {
    return RefreshIndicator(
      onRefresh: _fetchVisits,
      color: ColorConst.themeColor,
      child: list.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 70, color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('No $tabType Visits', style: TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.8), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                var visit = list[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      if (visit['VisitUkeyId'] != null) {
                        final deleted = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisitDetailsScreen(
                              visitUkeyId: visit['VisitUkeyId'].toString(),
                              companyId: visit['CompanyId'].toString(),
                            ),
                          ),
                        );
                        if (deleted == true) _fetchVisits();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  visit['VisitName'] ?? 'Unknown',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.2, color: Theme.of(context).textTheme.bodyLarge?.color),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (visit['VisitTime'] != null) ...[
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_month_rounded, size: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(visit['VisitTime']),
                                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.business_rounded, size: 14, color: ColorConst.themeColor),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            visit['PartyName'] ?? 'No Party Assigned',
                                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade700, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Dynamic Address Logic
                                    ...(() {
                                      String clean(dynamic val) {
                                        if (val == null) return '';
                                        String s = val.toString().trim();
                                        if (s.toLowerCase() == 'null') return '';
                                        return s;
                                      }
                                      List<String> parts = [];
                                      String a1 = clean(visit['Add1']);
                                      if (a1.isNotEmpty) parts.add(a1);
                                      String a2 = clean(visit['Add2']);
                                      if (a2.isNotEmpty) parts.add(a2);
                                      
                                      String address = parts.join(', ');
                                      if (address.isEmpty) address = clean(visit['PartyAddress']);
                                      if (address.isEmpty) return <Widget>[const SizedBox.shrink()];
                                      
                                      return [
                                        const SizedBox(height: 6),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 1.0),
                                              child: Icon(Icons.location_on_rounded, size: 14, color: ColorConst.themeColor),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                address,
                                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 11),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ];
                                    })(),
                                  ],
                                ),
                              ),
                              if (tabType == 'Pending')
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: _actionButton(
                                    label: 'Start Visit',
                                    icon: Icons.play_arrow_rounded,
                                    color: ColorConst.themeColor,
                                    onTap: () => _startVisit(visit),
                                  ),
                                )
                              else if (tabType == 'In Progress')
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: _actionButton(
                                    label: 'Complete',
                                    icon: Icons.check_circle_rounded,
                                    color: ColorConst.themeColor,
                                    onTap: () => _completeVisit(visit),
                                  ),
                                ),
                            ],
                          )

                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(0, 30),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    safeAreaBgAndTextColor(context, safeAreaBgColor: ColorConst.themeColor);

    List<dynamic> pendingVisits = _visits.where((v) {
      String status = (v['VisitStatus']?.toString() ?? 'Pending').toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
      return status == 'pending' || status == '' || status == '0';
    }).toList();

    List<dynamic> inProgressVisits = _visits.where((v) {
      String status = (v['VisitStatus']?.toString() ?? '').toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
      return status == 'inprogress' || status == 'started' || status == 'start' || status == 'ongoing';
    }).toList();

    List<dynamic> completedVisits = _visits.where((v) {
      String status = (v['VisitStatus']?.toString() ?? '').toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
      return status == 'complete' || status == 'completed';
    }).toList();

    return Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      appBar: AppBar(
        title: const Text('Visits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: ColorConst.themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _fetchVisits),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: ColorConst.themeColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVisitList(pendingVisits, 'Pending'),
                _buildVisitList(inProgressVisits, 'In Progress'),
                _buildVisitList(completedVisits, 'Completed'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateVisitScreen()),
          );
          if (result == true) _fetchVisits();
        },
        backgroundColor: ColorConst.themeColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
