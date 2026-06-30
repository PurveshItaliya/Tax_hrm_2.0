import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';

class WhatsNewPage extends StatefulWidget {
  const WhatsNewPage({super.key});

  @override
  State<WhatsNewPage> createState() => _WhatsNewPageState();
}

class _WhatsNewPageState extends State<WhatsNewPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedVersion = 'All';

  late List<String> versions;
  late List<ReleaseNoteItem> releaseNotes;

  @override
  void initState() {
    super.initState();
    
    String version101 = Platform.isAndroid ? 'v1.0.1' : 'v1.0.0';
    String versionName101 = Platform.isAndroid ? 'Bug Fixes & Improvements' : 'Initial Release';
    
    String version102 = Platform.isAndroid ? 'v1.0.2' : 'v1.0.0';
    String versionName102 = Platform.isAndroid ? 'Force Update & Enhancements' : 'Initial Release';
    
    versions = Platform.isAndroid ? ['All', 'v1.0.2', 'v1.0.1', 'v1.0.0'] : ['All', 'v1.0.0'];
    _selectedVersion = 'All';

    releaseNotes = [
      // Version 1.0.0 - Initial Release
      ReleaseNoteItem(
        id: 1,
        title: 'Employee Management',
        description: 'Add, update, and manage employee records with centralized information.',
        version: 'v1.0.0',
        versionName: 'Initial Release',
        date: 'June 05, 2026',
        category: 'Admin Panel',
        icon: Icons.people,
        bgColor: const Color(0xFF4CAF50),
        features: [
          'Add, update, and manage employee records',
          'Maintain centralized employee information',
          'View employee profiles and attendance history',
        ],
      ),
      ReleaseNoteItem(
        id: 2,
        title: 'Real-Time Employee Tracking',
        description: 'Monitor employee punch-in and punch-out activities in real time.',
        version: 'v1.0.0',
        versionName: 'Initial Release',
        date: 'June 05, 2026',
        category: 'Admin Panel',
        icon: Icons.location_on,
        bgColor: const Color(0xFF2196F3),
        features: [
          'Monitor punch-in and punch-out activities',
          'Track employee working status',
          'Live workforce visibility from admin dashboard',
        ],
      ),
      ReleaseNoteItem(
        id: 3,
        title: 'Attendance Monitoring',
        description: 'View daily, weekly, and monthly attendance reports.',
        version: 'v1.0.0',
        versionName: 'Initial Release',
        date: 'June 05, 2026',
        category: 'Admin Panel',
        icon: Icons.calendar_today,
        bgColor: const Color(0xFF9C27B0),
        features: [
          'Daily, weekly, and monthly attendance reports',
          'Track late arrivals and early departures',
          'Generate attendance summaries for payroll',
        ],
      ),
      ReleaseNoteItem(
        id: 4,
        title: 'Leave Management',
        description: 'Review employee leave requests and maintain complete history.',
        version: 'v1.0.0',
        versionName: 'Initial Release',
        date: 'June 05, 2026',
        category: 'Admin Panel',
        icon: Icons.beach_access,
        bgColor: const Color(0xFFFF9800),
        features: [
          'Review employee leave requests',
          'Approve or reject leave applications',
          'Maintain complete leave history and balances',
        ],
      ),
      ReleaseNoteItem(
        id: 5,
        title: 'Mobile Attendance Punching',
        description: 'Easy Punch In and Punch Out directly from mobile devices.',
        version: 'v1.0.0',
        versionName: 'Initial Release',
        date: 'June 05, 2026',
        category: 'Employee App',
        icon: Icons.fingerprint,
        bgColor: const Color(0xFFE91E63),
        features: [
          'Easy Punch In and Punch Out',
          'Accurate timestamp tracking',
          'User-friendly attendance process',
        ],
      ),
      ReleaseNoteItem(
        id: 6,
        title: 'Leave Application Module',
        description: 'Submit leave requests directly from mobile app.',
        version: 'v1.0.0',
        versionName: 'Initial Release',
        date: 'June 05, 2026',
        category: 'Employee App',
        icon: Icons.event_note,
        bgColor: const Color(0xFF795548),
        features: [
          'Submit leave requests from mobile',
          'Real-time approval status tracking',
          'View leave history and balance',
        ],
      ),
      // --- New Features Added ---
      ReleaseNoteItem(
        id: 7,
        title: 'Shift Reminders',
        description: 'Shift-based Punch In/Punch Out reminders with notifications 15 minutes before shift start and end times.',
        version: version101,
        versionName: versionName101,
        date: Platform.isAndroid ? 'June 15, 2026' : 'June 05, 2026',
        category: 'Both',
        icon: Icons.notifications_active,
        bgColor: const Color(0xFFF44336), // Red
        features: [
          'Shift-based Punch In/Punch Out reminders',
          'Notifications 15 minutes before shift',
        ],
      ),
      ReleaseNoteItem(
        id: 8,
        title: 'Location Tracking',
        description: 'Employee location tracking on the map based on shift timings, including timeline-wise location history.',
        version: version101,
        versionName: versionName101,
        date: Platform.isAndroid ? 'June 15, 2026' : 'June 05, 2026',
        category: 'Admin Panel',
        icon: Icons.map,
        bgColor: const Color(0xFF009688), // Teal
        features: [
          'Location tracking based on shift timings',
          'Timeline-wise location history on map',
        ],
      ),
      ReleaseNoteItem(
        id: 9,
        title: 'Admin Mode Switch',
        description: 'Admin Mode switch button for authorized users to directly move between Employee Mode and Admin Mode.',
        version: version101,
        versionName: versionName101,
        date: Platform.isAndroid ? 'June 15, 2026' : 'June 05, 2026',
        category: 'Both',
        icon: Icons.admin_panel_settings,
        bgColor: const Color(0xFF673AB7), // Deep Purple
        features: [
          'Admin Mode switch button',
          'Seamlessly toggle Employee/Admin modes',
        ],
      ),
      // --- v1.0.2 New Features Added ---
      ReleaseNoteItem(
        id: 10,
        title: 'App Updates & UI Changes',
        description: 'Mandatory app update system, new app icon, and theme color changes.',
        version: version102,
        versionName: versionName102,
        date: Platform.isAndroid ? 'June 24, 2026' : 'June 05, 2026',
        category: 'Both',
        icon: Icons.system_update,
        bgColor: const Color(0xFFE91E63), // Pink
        features: [
          'Mandatory app update system with force update dialog',
          'App icon change and app theme colors change',
          'Improved overall performance, stability, and reliability',
        ],
      ),
      ReleaseNoteItem(
        id: 11,
        title: 'Location & Tracking Enhancements',
        description: 'Comprehensive employee location tracking and admin configurations.',
        version: version102,
        versionName: versionName102,
        date: Platform.isAndroid ? 'June 24, 2026' : 'June 05, 2026',
        category: 'Admin Panel',
        icon: Icons.location_history,
        bgColor: const Color(0xFF4CAF50), // Green
        features: [
          'Admin settings for location tracking & radius',
          'Location tracking from Punch In to Punch Out (background & closed states)',
          'Movement path tracking with map view',
          'Improved background location permission handling & validation',
        ],
      ),
      ReleaseNoteItem(
        id: 12,
        title: 'Payroll & Bug Fixes',
        description: 'Resolved issues related to payroll, payslips, and punch reminders.',
        version: version102,
        versionName: versionName102,
        date: Platform.isAndroid ? 'June 24, 2026' : 'June 05, 2026',
        category: 'Employee App',
        icon: Icons.bug_report,
        bgColor: const Color(0xFFFF9800), // Orange
        features: [
          'Fixed Payroll Summary upload, delete, and incorrect data display',
          'Resolved Payslip screen data display issue',
          'Fixed Punch In/Out reminder timing and notifications',
        ],
      ),
    ];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeAreaBgAndTextColor(context);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<ReleaseNoteItem> get _filteredReleaseNotes {
    if (_selectedVersion == 'All') {
      return releaseNotes;
    }
    return releaseNotes.where((item) => item.version == _selectedVersion).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    
    if (checkInterNetConnection.connectionType == 0) {
      return const NoInternetViewPage();
    }
    
    return Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        appBar: showCustomeAppBar(
          whatsNewString,
          size,
          titleColors: ColorConst.appbarTextColor,
          iconsOntap: () {
            backScreen(context);
          },
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVersionSelector(size),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_filteredReleaseNotes.isNotEmpty)
                        ..._buildGroupedReleaseNotes(size),
                      if (_filteredReleaseNotes.isEmpty)
                        _buildNoDataWidget(size),
                      _buildFooter(size),
                      SizedBox(height: size.height * 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildVersionSelector(Size size) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.005),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: versions.map((version) {
            final isSelected = _selectedVersion == version;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.01,
                vertical: size.height * 0.005,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVersion = version;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.05,
                    vertical: size.height * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorConst.themeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: ColorConst.themeColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    version,
                    style: TextStyle(
                      fontSize: size.width * 0.032,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedReleaseNotes(Size size) {
    final Map<String, List<ReleaseNoteItem>> grouped = {};
    
    for (var item in _filteredReleaseNotes) {
      final key = '${item.version} - ${item.versionName}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }

    final List<Widget> widgets = [];
    
    grouped.forEach((versionKey, items) {
      final versionInfo = items.first;
      
      widgets.add(_buildVersionHeader(size, versionInfo.version, versionInfo.versionName, versionInfo.date));
      
      // Admin Panel Items
      final adminItems = items.where((item) => item.category == 'Admin Panel').toList();
      if (adminItems.isNotEmpty) {
        widgets.add(_buildSectionTitle(size, 'Admin Panel Features'));
        widgets.addAll(adminItems.map((item) => _buildReleaseNoteCard(size, item)).toList());
      }
      
      // Employee App Items
      final employeeItems = items.where((item) => item.category == 'Employee App').toList();
      if (employeeItems.isNotEmpty) {
        widgets.add(_buildSectionTitle(size, 'Employee App Features'));
        widgets.addAll(employeeItems.map((item) => _buildReleaseNoteCard(size, item)).toList());
      }
      
      // Both Category Items
      final bothItems = items.where((item) => item.category == 'Both').toList();
      if (bothItems.isNotEmpty) {
        widgets.add(_buildSectionTitle(size, 'General Updates'));
        widgets.addAll(bothItems.map((item) => _buildReleaseNoteCard(size, item)).toList());
      }
      
      widgets.add(SizedBox(height: size.height * 0.01));
    });
    
    return widgets;
  }

  Widget _buildVersionHeader(Size size, String version, String versionName, String date) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.012),
      decoration: BoxDecoration(
        color: ColorConst.themeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConst.themeColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(size.width * 0.015),
            decoration: BoxDecoration(
              color: ColorConst.themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bookmark_rounded,
              size: size.width * 0.04,
              color: ColorConst.themeColor,
            ),
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  version,
                  style: TextStyle(
                    fontSize: size.width * 0.036,
                    fontWeight: FontWeight.bold,
                    color: ColorConst.themeColor,
                  ),
                ),
                Text(
                  versionName,
                  style: TextStyle(
                    fontSize: size.width * 0.026,
                    color: ColorConst.textgrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.03, vertical: size.height * 0.005),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Text(
              date,
              style: TextStyle(
                fontSize: size.width * 0.024,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(Size size, String title) {
    return Container(
      margin: EdgeInsets.only(
        left: size.width * 0.04,
        right: size.width * 0.04,
        top: size.height * 0.02,
        bottom: size.height * 0.008,
      ),
      child: Row(
        children: [
          Container(
            width: size.width * 0.012,
            height: size.height * 0.022,
            decoration: BoxDecoration(
              color: ColorConst.themeColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          SizedBox(width: size.width * 0.03),
          Text(
            title,
            style: TextStyle(
              fontSize: size.width * 0.034,
              fontWeight: FontWeight.bold,
              color: ColorConst.otpTitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNoteCard(Size size, ReleaseNoteItem item) {
    final accentColor = ColorConst.themeColor;
    
    return GestureDetector(
      onTap: () {
        _showDetailsDialog(context, size, item);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.006),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.04),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: size.width * 0.12,
                height: size.width * 0.12,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  size: size.width * 0.055,
                  color: accentColor,
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: size.width * 0.036,
                        fontWeight: FontWeight.bold,
                        color: ColorConst.otpTitleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: size.width * 0.028,
                        color: ColorConst.textgrey,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.version,
                            style: TextStyle(
                              fontSize: size.width * 0.022,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(
                              fontSize: size.width * 0.022,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: size.width * 0.035,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataWidget(Size size) {
    return Container(
      margin: EdgeInsets.all(size.width * 0.04),
      padding: EdgeInsets.all(size.height * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: size.width * 0.1,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No release notes found',
            style: TextStyle(
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.w600,
              color: ColorConst.otpTitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a different version to view release notes',
            style: TextStyle(
              fontSize: size.width * 0.03,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Size size) {
    return Container(
      margin: EdgeInsets.all(size.width * 0.04),
      padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.favorite,
              color: ColorConst.themeColor.withOpacity(0.5),
              size: size.width * 0.06,
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for choosing our Attendance Punching Application',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width * 0.028,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'We remain committed to continuous improvement',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width * 0.025,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Size size, ReleaseNoteItem item) {
    final accentColor = ColorConst.themeColor;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: size.width * 0.85,
            constraints: BoxConstraints(
              maxHeight: size.height * 0.75,
            ),
            padding: EdgeInsets.all(size.width * 0.05),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(size.width * 0.04),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      size: size.width * 0.1,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: size.width * 0.042,
                      fontWeight: FontWeight.bold,
                      color: ColorConst.otpTitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.version} • ${item.versionName}',
                      style: TextStyle(
                        fontSize: size.width * 0.026,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      color: ColorConst.textgrey,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (item.features.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Key Details:',
                        style: TextStyle(
                          fontSize: size.width * 0.032,
                          fontWeight: FontWeight.bold,
                          color: ColorConst.otpTitleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...item.features.map((feature) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: size.width * 0.04,
                              color: accentColor,
                            ),
                            SizedBox(width: size.width * 0.025),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: size.width * 0.028,
                                  color: ColorConst.textgrey,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConst.themeColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Got it',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ReleaseNoteItem {
  final int id;
  final String title;
  final String description;
  final String version;
  final String versionName;
  final String date;
  final String category;
  final IconData icon;
  final Color bgColor;
  final List<String> features;

  ReleaseNoteItem({
    required this.id,
    required this.title,
    required this.description,
    required this.version,
    required this.versionName,
    required this.date,
    required this.category,
    required this.icon,
    required this.bgColor,
    this.features = const [],
  });
}