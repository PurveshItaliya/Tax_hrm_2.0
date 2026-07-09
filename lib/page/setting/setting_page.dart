// ignore_for_file: empty_catches, deprecated_member_use, use_build_context_synchronously, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/adminprofileapi.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/bottom_bar_screen.dart';
import 'package:tax_hrm/page/personal_info/profilepage.dart';
import 'package:tax_hrm/page/authpages/loginpage.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/provider/setting_provider.dart';
import 'package:tax_hrm/provider/theme_provider.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/userloginprovider.dart';
import 'package:tax_hrm/repository/background_location_repository.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/reminder_service.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/services/fcm_token_service.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/common_dialogBox.dart';
import 'package:tax_hrm/provider/location_tracking_provider.dart';

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

class _SettingPageState extends State<SettingPage> with WidgetsBindingObserver {
  bool _showAdminToggle = false;
  String _appVersion = '';

  // ── Background location permission state (Android + IsFetchLocation only) ──
  bool _bgLocationGranted = false;
  bool get _showBgLocationTile =>
      Platform.isAndroid &&
      BackgroundLocationRepository.isFetchLocationEnabled();

  Future<void> _checkBgLocationPermission() async {
    if (!_showBgLocationTile) return;
    final perm = await Geolocator.checkPermission();
    final granted = perm == LocationPermission.always;
    if (mounted && granted != _bgLocationGranted) {
      setState(() => _bgLocationGranted = granted);
    }
  }

  Future<void> loadVersion() async {
    _appVersion = await AppVersion.getVersion();
    if (mounted) setState(() {});
  }

  Future<void> _checkAdminAccess() async {
    try {
      if (curentUser != null && curentUser['Id'] != null) {
        final menuSettings = await AdminProfileApiClass().getMenuSettingsData(
          empId: curentUser['Id'],
        );
        if (menuSettings != null && menuSettings is List) {
          final hasAdminRight = menuSettings.any(
            (element) =>
                element.columnKey.toString().toLowerCase() == 'asadmin' &&
                element.columnValue.toString().toLowerCase() == 'true',
          );
          if (mounted) {
            setState(() {
              _showAdminToggle = hasAdminRight;
            });
          }
        }
      }
    } catch (e) {
      /* ignored */
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Provider.of<SettingProvider>(
      context,
      listen: false,
    ).settingMenuLoading(context);
    _checkAdminAccess();
    loadVersion();
    _checkBgLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check permission when user returns from system Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBgLocationPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final settingProvider = Provider.of<SettingProvider>(context);
    Provider.of<ThemeProvider>(context);
    Provider.of<LanguageProvider>(context);

    // Refresh settings menu items so they translate instantly
    settingProvider.settingMenuGet(context);

    safeAreaBgAndTextColor(
      context,
      safeAreaBgColor: ColorConst.themeColor,
      safeAreaBrightness: Brightness.light,
    );

    return Scaffold(
      backgroundColor: ColorConst
          .scaffoldColor, // Matches the app's grey/off-white background
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
                          // 1. Stop location tracking
                          try {
                            Provider.of<LocationTrackingProvider>(
                              context,
                              listen: false,
                            ).stopLocationTracking();
                          } catch (e) {}

                          // 2. Clear/Deactivate FCM Token on server and device
                          try {
                            await FcmTokenService.instance.handleLogout();
                          } catch (e) {}

                          // 3. Clear all notification reminders
                          try {
                            await ReminderNotificationService.cancelAll();
                          } catch (e) {}

                          // 4. Securely clear SharedPreferences (preserving isDarkMode theme)
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final isDarkMode =
                                prefs.getBool('isDarkMode') ?? false;
                            await prefs.clear();
                            // Restore dark mode
                            await prefs.setBool('isDarkMode', isDarkMode);
                          } catch (e) {}

                          // 5. Reset all global session variables
                          curentUser = null;
                          selectedcurentcompany = null;
                          getAllCompany = [];
                          allManinEmplyeList = [];
                          payrollstoreDatalist = [];
                          positionlistt = [];
                          switchValue = false;

                          Provider.of<Userloginprovider>(
                            context,
                            listen: false,
                          ).clearData();

                          // 6. Redirect to Login Screen
                          nextscreenRemove(
                            context,
                            const LoginScreen(),
                            onthenValue: (value) {},
                          );
                        },
                      );
                    },
                    child: Container(
                      width: size.width * 0.85,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: ColorConst.logoutBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ColorConst.logoutBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: ColorConst.logoutText,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            logoutString,
                            style: TextStyle(
                              color: ColorConst.logoutText,
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
              decoration: BoxDecoration(color: ColorConst.themeColor),
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
                        (curentUser['FirstName'] != null &&
                                curentUser['FirstName'] != "")
                            ? ('${curentUser['FirstName']}'[0] +
                                  (curentUser['LastName'] != null &&
                                          curentUser['LastName'] != ""
                                      ? '${curentUser['LastName']}'[0]
                                      : ""))
                            : (curentUser['Username'] != null &&
                                      curentUser['Username'] != ""
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
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: Icon(
                        Icons.edit_rounded,
                        color: ColorConst.themeColor,
                        size: 18,
                      ),
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
                        style: TextStyle(
                          fontFamily: fontInterSemiBoldString,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConst.settingTextColors,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        curentUser['Role'] == 'Admin'
                            ? 'Administrator'
                            : employeeRoleString,
                        style: TextStyle(
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

    // Dark Theme Toggle Tile
    final themeProvider = Provider.of<ThemeProvider>(context);
    list.add(
      _buildDarkThemeToggleTile(
        size: size,
        val: themeProvider.isDarkMode,
        onChanged: (val) {
          themeProvider.toggleTheme(val);
          safeAreaBgAndTextColor(
            context,
            safeAreaBgColor: val ? ColorConst.black : ColorConst.themeColor,
            safeAreaBrightness: val ? Brightness.dark : Brightness.light,
          );
        },
      ),
    );
    list.add(Divider(height: 1, color: ColorConst.textBorder.withOpacity(0.2)));

    // Language Selection Tile
    final languageProvider = Provider.of<LanguageProvider>(context);
    list.add(
      _buildLanguageTile(size, languageProvider),
    );
    list.add(Divider(height: 1, color: ColorConst.textBorder.withOpacity(0.2)));

    // Background Location Permission tile (Android + IsFetchLocation=true only)
    if (_showBgLocationTile) {
      list.add(_buildBgLocationTile(size));
      list.add(
        Divider(height: 1, color: ColorConst.textBorder.withOpacity(0.2)),
      );
    }

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
              Provider.of<HomeProvider>(
                context,
                listen: false,
              ).changeSelectBottomBar(0);
              nextscreenRemove(
                context,
                const AnimatedBottomBar(),
                onthenValue: (value) {},
              );
            },
          ),
        );
        list.add(
          Divider(height: 1, color: ColorConst.textBorder.withOpacity(0.2)),
        );
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
        list.add(
          Divider(height: 1, color: ColorConst.textBorder.withOpacity(0.2)),
        );
      }
    }

    return list;
  }

  // ── Background Location Permission Tile ────────────────────────────────────
  Widget _buildBgLocationTile(Size size) {
    final bool granted = _bgLocationGranted;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: granted
                ? ColorConst.themeColor.withOpacity(0.08)
                : Colors.red.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.my_location_rounded,
            color: granted ? ColorConst.themeColor : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          'Background Location',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: ColorConst.settingTextColors,
          ),
        ),
        subtitle: Text(
          granted
              ? 'Always Allow — active for shift tracking'
              : 'Required to track location during your shift',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: granted ? Colors.green.shade600 : Colors.red.shade600,
          ),
        ),
        trailing: Switch(
          value: granted,
          activeColor: ColorConst.themeColor,
          inactiveThumbColor: Colors.red.shade400,
          inactiveTrackColor: Colors.red.withOpacity(0.25),
          onChanged: (_) => _openBgLocationSettings(),
        ),
        onTap: _openBgLocationSettings,
      ),
    );
  }

  /// Opens the app system settings page so the user can set "Always Allow".
  Future<void> _openBgLocationSettings() async {
    await openAppSettings();
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
            child: Image.asset(image, color: ColorConst.themeColor),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: ColorConst.settingTextColors,
          ),
        ),
        trailing: Icon(
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
          child: Icon(
            Icons.admin_panel_settings_rounded,
            color: ColorConst.themeColor,
            size: 20,
          ),
        ),
        title: Text(
          adminModeString,
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

  // ── Custom Dark Theme Switch Tile ──────────────────────────────────────────
  Widget _buildDarkThemeToggleTile({
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
          child: Icon(
            val ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: ColorConst.themeColor,
            size: 20,
          ),
        ),
        title: Text(
          darkThemeString,
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

  Widget _buildLanguageTile(Size size, LanguageProvider languageProvider) {
    final Map<String, String> languages = {
      'en': 'English',
      'hi': 'हिन्दी',
      'gu': 'ગુજરાતી',
      'mr': 'मराठी',
      'bn': 'বাংলা',
      'ta': 'தமிழ்',
      'te': 'తెలుగు',
      'kn': 'ಕನ್ನಡ',
      'ml': 'മലയാളം',
      'pa': 'ਪੰਜਾਬੀ',
      'or': 'ଓଡ଼ିଆ',
      'as': 'অসমীয়া',
    };

    final langName =
        languages[languageProvider.currentLanguage] ?? 'English';

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: ColorConst.themeColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.language_rounded,
            color: ColorConst.themeColor,
            size: 20,
          ),
        ),
        title: Text(
          'Language',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: ColorConst.settingTextColors,
          ),
        ),
        subtitle: Text(
          langName,
          style: TextStyle(
            fontSize: 12,
            color: ColorConst.textgrey,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: ColorConst.settingIconsColors,
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: ColorConst.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            builder: (_) => _LanguageSelectionBottomSheet(
              languages: languages,
              languageProvider: languageProvider,
            ),
          );
        },
      ),
    );
  }
}

class _LanguageSelectionBottomSheet extends StatefulWidget {
  final Map<String, String> languages;
  final LanguageProvider languageProvider;

  const _LanguageSelectionBottomSheet({
    required this.languages,
    required this.languageProvider,
  });

  @override
  State<_LanguageSelectionBottomSheet> createState() => _LanguageSelectionBottomSheetState();
}

class _LanguageSelectionBottomSheetState extends State<_LanguageSelectionBottomSheet> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredLanguages = widget.languages.entries
        .where((e) => e.value.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorConst.textgrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LanguageProvider.translate('Select Language', 'Select Language'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConst.settingTextColors,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: TextStyle(color: ColorConst.settingTextColors),
              decoration: InputDecoration(
                hintText: LanguageProvider.translate('Search Language', 'Search Language...'),
                hintStyle: TextStyle(color: ColorConst.hintextColor),
                prefixIcon: Icon(Icons.search, color: ColorConst.settingIconsColors),
                filled: true,
                fillColor: ColorConst.scaffoldColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorConst.textBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorConst.themeColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredLanguages.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: ColorConst.textBorder.withOpacity(0.5),
                  ),
                  itemBuilder: (context, index) {
                    final code = filteredLanguages[index].key;
                    final label = filteredLanguages[index].value;
                    final isSelected = widget.languageProvider.currentLanguage == code;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? ColorConst.themeColor : ColorConst.settingTextColors,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: ColorConst.themeColor)
                          : null,
                      onTap: () {
                        widget.languageProvider.changeLanguage(code);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

