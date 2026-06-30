// ignore_for_file: deprecated_member_use, use_build_context_synchronously, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/adminprofileapi.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/bottom_bar_screen.dart';
import 'package:tax_hrm/page/personal_info/profilepage.dart';
import 'package:tax_hrm/page/splashPage.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/provider/setting_provider.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/reminder_service.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/common_dialogBox.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class AppVersion {
  static Future<String> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String version = packageInfo.version; // e.g. 1.2.0

    // Clean up the version string to remove any appended build info or tags
    if (version.contains('+')) {
      version = version.split('+')[0];
    }
    if (version.contains('-')) {
      version = version.split('-')[0];
    }

    String buildNumber = packageInfo.buildNumber; // e.g. 15

    return '$version ($buildNumber)';
  }
}

class _SettingPageState extends State<SettingPage> {
  bool _showAdminToggle = false;
  String _appVersion = '';

  Future<void> loadVersion() async {
    _appVersion = await AppVersion.getVersion();
    if (mounted) setState(() {});
  }

  Future<void> _checkAdminAccess() async {
    try {
      if (curentUser != null && curentUser['Id'] != null) {
        final menuSettings =
            await AdminProfileApiClass().getMenuSettingsData(empId: curentUser['Id']);
        if (menuSettings != null && menuSettings is List) {
          final hasAdminRight = menuSettings.any((element) =>
              element.columnKey.toString().toLowerCase() == 'asadmin' &&
              element.columnValue.toString().toLowerCase() == 'true');
          if (mounted) {
            setState(() {
              _showAdminToggle = hasAdminRight;
            });
          }
        }
      }
    } catch (e) { /* ignored */ }
  }

  @override
  void initState() {
    super.initState();
    Provider.of<SettingProvider>(context, listen: false).settingMenuLoading(context);
    _checkAdminAccess();
    loadVersion();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final settingProvider = Provider.of<SettingProvider>(context);
    safeAreaBgAndTextColor(context,
        safeAreaBgColor: ColorConst.themeColor, safeAreaBrightness: Brightness.light);

    return Scaffold(
      backgroundColor: ColorConst.scaffoldColor, // Matches the app's grey/off-white background
      body: settingProvider.islodering
          ? settingShimmer(size)
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header Section (Flat Blue design, no gradient)
                  _buildProfileHeader(size, settingProvider),
                  const SizedBox(height: 16),

                  // Settings Card Container (with white bg and light shadows)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorConst.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ColorConst.textBorder.withOpacity(0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildSettingsList(size, settingProvider),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button (Sleek red solid outline style, no gradient)
                  GestureDetector(
                    onTap: () {
                      commonDialogBoxDesign(
                        context: context,
                        size: size,
                        title: logoutString,
                        onTapLogOut: () async {
                          SaveUser().saveUserData('');
                          SaveUser().saveselectedcopany('');
                          await ReminderNotificationService.cancelAll();
                          nextscreenRemove(context, ShowSpleshPage(), onthenValue: (value) {});
                        },
                      );
                    },
                    child: Container(
                      width: size.width * 0.85,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            logoutString,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Version Text
                  Text(
                    "Version: $_appVersion",
                    style: TextStyle(
                      fontSize: size.width * 0.032,
                      color: ColorConst.textgrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Profile Header Section ─────────────────────────────────────────────────
  Widget _buildProfileHeader(Size size, SettingProvider settingProvider) {
    return SizedBox(
      width: size.width,
      height: size.width * 0.72,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Solid brand color header strip (no gradient)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.width * 0.38,
              decoration: const BoxDecoration(
                color: ColorConst.themeColor,
              ),
            ),
          ),

          // Profile Picture Overlapping
          Positioned(
            top: size.width * 0.18,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ColorConst.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: size.width * 0.16,
                backgroundColor: ColorConst.greyOpicityColor,
                child: settingProvider.setEmpProfile?.img != null
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(
                              '${apibaseurl}UploadFiles/Emp/${settingProvider.setEmpProfile!.img}',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Text(
                        (curentUser['FirstName'] != null && curentUser['FirstName'] != "")
                            ? ('${curentUser['FirstName']}'[0] +
                                (curentUser['LastName'] != null && curentUser['LastName'] != ""
                                    ? '${curentUser['LastName']}'[0]
                                    : ""))
                            : (curentUser['Username'] != null && curentUser['Username'] != ""
                                ? '${curentUser['Username']}'[0]
                                : ""),
                        style: TextStyle(
                          fontSize: size.height * 0.045,
                          color: ColorConst.themeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),

          // Edit Profile image overlap icon
          Positioned(
            top: size.width * 0.40,
            right: size.width * 0.36,
            child: settingProvider.setEmpProfile == null
                ? const SizedBox()
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorConst.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.edit_rounded, color: ColorConst.themeColor, size: 18),
                      onPressed: () {
                        nextScreen(
                          context,
                          ProfileViewPage(isEdit: false),
                          onthenValue: (value) {
                            safeAreaBgAndTextColor(
                              context,
                              safeAreaBgColor: ColorConst.themeColor,
                              safeAreaBrightness: Brightness.light,
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),

          // Employee Name and Title
          Positioned(
            bottom: 4,
            child: curentUser == null
                ? const SizedBox()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (curentUser['FirstName'] != null &&
                                curentUser['FirstName'] != "" &&
                                curentUser['LastName'] != null &&
                                curentUser['LastName'] != "")
                            ? '${curentUser['FirstName'] + ' ' + curentUser['LastName']}'
                            : '${curentUser['Username']}',
                        style: const TextStyle(
                          fontFamily: fontInterSemiBoldString,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConst.settingTextColors,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        curentUser['Role'] == 'Admin' ? 'Administrator' : 'Employee',
                        style: const TextStyle(
                          fontSize: 13,
                          color: ColorConst.textgrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Settings List Builder ──────────────────────────────────────────────────
  List<Widget> _buildSettingsList(Size size, SettingProvider settingProvider) {
    final List<Widget> list = [];

    for (int i = 0; i < settingProvider.settingGridOptionList.length; i++) {
      final item = settingProvider.settingGridOptionList[i];

      // Insert Admin Mode switch at index 1 if available
      if (_showAdminToggle && i == 1) {
        list.add(
          _buildAdminToggleTile(
            size: size,
            val: curentUser['Role'] == 'Admin',
            onChanged: (val) async {
              if (curentUser['OriginalRole'] == null) {
                curentUser['OriginalRole'] = curentUser['Role'];
              }
              if (val) {
                curentUser['Role'] = 'Admin';
                switchValue = true;
              } else {
                curentUser['Role'] = curentUser['OriginalRole'] ?? 'User';
                switchValue = false;
              }
              await SaveUser().saveAdminSwitch(switchValue);
              await SaveUser().saveUserData(jsonEncode(curentUser));

              if (!context.mounted) return;
              Provider.of<HomeProvider>(context, listen: false).changeSelectBottomBar(0);
              nextscreenRemove(context, const AnimatedBottomBar(), onthenValue: (value) {});
            },
          ),
        );
        list.add(Divider(height: 1, color: ColorConst.textBorder.withOpacity(0.2)));
      }

      list.add(
        _buildSettingTile(
          size: size,
          title: item.title,
          image: item.image,
          onTap: () {
            settingProvider.settingMenuiHandleSubmit(size, context, item);
          },
        ),
      );

      if (i < settingProvider.settingGridOptionList.length - 1) {
        list.add(Divider(height: 1, color: ColorConst.textBorder.withOpacity(0.2)));
      }
    }

    return list;
  }

  // ── Custom Settings Tile ───────────────────────────────────────────────────
  Widget _buildSettingTile({
    required Size size,
    required String title,
    required String image,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: ColorConst.themeColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(
              image,
              color: ColorConst.themeColor,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: ColorConst.settingTextColors,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: ColorConst.settingIconsColors,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }

  // ── Custom Admin Switch Tile ───────────────────────────────────────────────
  Widget _buildAdminToggleTile({
    required Size size,
    required bool val,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: ColorConst.themeColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: ColorConst.themeColor,
            size: 20,
          ),
        ),
        title: const Text(
          "Admin Mode",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: ColorConst.settingTextColors,
          ),
        ),
        trailing: Switch(
          value: val,
          activeColor: ColorConst.themeColor,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
