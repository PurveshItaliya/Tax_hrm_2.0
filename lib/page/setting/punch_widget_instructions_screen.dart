import 'dart:io';
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:tax_hrm/services/punch_widget_customization_service.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';

class PunchWidgetInstructionsScreen extends StatefulWidget {
  const PunchWidgetInstructionsScreen({super.key});

  @override
  State<PunchWidgetInstructionsScreen> createState() =>
      _PunchWidgetInstructionsScreenState();
}

class _PunchWidgetInstructionsScreenState
    extends State<PunchWidgetInstructionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showCustomization = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    safeAreaBgAndTextColor(
      context,
      safeAreaBgColor: ColorConst.themeColor,
      safeAreaBrightness: Brightness.light,
    );

    return Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ColorConst.themeColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 19,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          punchWidgetTitleString,
          style: const TextStyle(
            fontFamily: fontInterSemiBoldString,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showCustomization ? Icons.tune_rounded : Icons.palette_outlined,
              color: Colors.white,
              size: 21,
            ),
            tooltip: "Customize Widget",
            onPressed: () {
              setState(() {
                _showCustomization = !_showCustomization;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Compact Widget Preview
                    const _CompactWidgetPreviewSection(),

                    // 2. Inline Live Customization (Default hidden, toggle via AppBar icon)
                    if (_showCustomization)
                      const _InlineWidgetCustomizationSection(),

                    const SizedBox(height: 24),

                    // 3. Platform-Specific Steps (ONLY current platform shown)
                    _PlatformStepsList(
                      isIos: Platform.isIOS,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 5. Compact Bottom Action Bar
            _CompactBottomCTA(
              onGotIt: () => Navigator.pop(context),
              onViewAgain: _scrollToTop,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 1. Compact Widget Live Preview ───────────────────────────────────────────
class _CompactWidgetPreviewSection extends StatelessWidget {
  const _CompactWidgetPreviewSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConst.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConst.textBorder.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ValueListenableBuilder<PunchWidgetSettings>(
        valueListenable:
            PunchWidgetCustomizationService.instance.settingsNotifier,
        builder: (context, settings, _) {
          return Column(
            children: [
              // Simulated Phone Wallpaper Area for Transparent Liquid Glass Blur Preview
              Container(
                width: double.infinity,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                      Color(0xFF334155),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient colorful circles behind to make real glass blur & refraction clearly visible
                    Positioned(
                      top: 15,
                      left: 35,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF6366F1).withOpacity(0.85),
                              const Color(0xFF6366F1).withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 18,
                      right: 40,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF06B6D4).withOpacity(0.8),
                              const Color(0xFF06B6D4).withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Transparent Liquid Glass Punch Widget (Clean centered PUNCH text only)
                    LiquidGlassLens(
                      style: LiquidGlassStyle(
                        shape:
                            const LiquidGlassShape.continuousRoundedRectangle(
                          cornerRadius: 24,
                          clipQuality:
                              LiquidGlassClipQuality.roundedRectangle,
                        ),
                        color: settings.glassTintColor,
                        blur: settings.blurSigma,
                        saturation: 1.3,
                        refractionIndex: 1.25,
                        refractionWidth: 20,
                        specular: LiquidGlassLight.specular(
                          thickness: 4.5,
                          sharpness: 0.7,
                          angle: 45,
                          intensity: settings.color == 'black' ? 0.35 : 1.2,
                        ),
                        glow: LiquidGlassLight.glow(
                          thickness: 8.0,
                          angle: 135,
                          intensity: settings.color == 'black' ? 0.0 : 0.6,
                        ),
                      ),
                      child: Container(
                        width: 250,
                        height: 115,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: settings.innerGradientColors,
                          ),
                          border: Border.all(
                            color: settings.color == 'white'
                                ? Colors.black.withOpacity(0.18)
                                : settings.color == 'black'
                                    ? Colors.white.withOpacity(0.18)
                                    : Colors.white.withOpacity(0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          punchUpperString,
                          style: TextStyle(
                            fontFamily: fontInterBoldString,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                            color: settings.textColor,
                            shadows: settings.color == 'white'
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.55),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                addWidgetShortcutDescString,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: fontInterRegularString,
                  fontSize: 12.5,
                  color: ColorConst.textgrey,
                  height: 1.4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── 2. Inline Widget Customization Section ───────────────────────────────────
class _InlineWidgetCustomizationSection extends StatefulWidget {
  const _InlineWidgetCustomizationSection();

  @override
  State<_InlineWidgetCustomizationSection> createState() =>
      _InlineWidgetCustomizationSectionState();
}

class _InlineWidgetCustomizationSectionState
    extends State<_InlineWidgetCustomizationSection> {
  bool _isApplied = false;

  void _onApply() async {
    await PunchWidgetCustomizationService.instance.syncWithNative();
    if (!mounted) return;
    setState(() {
      _isApplied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              "Widget settings applied instantly!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isApplied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PunchWidgetSettings>(
      valueListenable:
          PunchWidgetCustomizationService.instance.settingsNotifier,
      builder: (context, settings, _) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ColorConst.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ColorConst.textBorder.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (Compact)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: ColorConst.themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      size: 16,
                      color: ColorConst.themeColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Widget Customization",
                    style: TextStyle(
                      fontFamily: fontInterBoldString,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorConst.settingTextColors,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 12, color: Color(0xFF10B981)),
                        SizedBox(width: 2),
                        Text(
                          "Instant Sync",
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. 4 Themes in 1 Single Row (Expanded View)
              Row(
                children: [
                  _buildThemeCard(
                    id: 'blue',
                    name: 'Blue',
                    color: const Color(0xFF0F49BB),
                    isSelected: settings.color == 'blue',
                  ),
                  const SizedBox(width: 8),
                  _buildThemeCard(
                    id: 'white',
                    name: 'White',
                    color: Colors.white,
                    isSelected: settings.color == 'white',
                    hasBorder: true,
                  ),
                  const SizedBox(width: 8),
                  _buildThemeCard(
                    id: 'black',
                    name: 'Black',
                    color: Colors.black,
                    isSelected: settings.color == 'black',
                  ),
                  const SizedBox(width: 8),
                  _buildThemeCard(
                    id: 'transparent',
                    name: 'Glass',
                    color: const Color(0xFFE2E8F0),
                    isGlass: true,
                    isSelected: settings.color == 'transparent',
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 3. Instant Apply Button
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConst.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _onApply,
                  icon: Icon(
                    _isApplied
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: Text(
                    _isApplied
                        ? "Applied Instantly! ✓"
                        : "Apply Settings Instantly",
                    style: const TextStyle(
                      fontFamily: fontInterBoldString,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeCard({
    required String id,
    required String name,
    required Color color,
    required bool isSelected,
    bool hasBorder = false,
    bool isGlass = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final double newTransparency = (id == 'transparent') ? 1.0 : 0.0;
          PunchWidgetCustomizationService.instance.updateAndSyncSettings(
            color: id,
            transparency: newTransparency,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorConst.themeColor.withOpacity(0.08)
                : Colors.grey.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? ColorConst.themeColor
                  : Colors.grey.withOpacity(0.22),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isGlass ? null : color,
                  gradient: isGlass
                      ? const LinearGradient(
                          colors: [Colors.white70, Color(0xFFCBD5E1)],
                        )
                      : null,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasBorder ? Colors.grey.shade400 : Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: isGlass
                    ? const Icon(Icons.auto_awesome,
                        size: 11, color: Color(0xFF64748B))
                    : null,
              ),
              const SizedBox(height: 5),
              Text(
                name,
                style: TextStyle(
                  fontFamily: isSelected
                      ? fontInterSemiBoldString
                      : fontInterRegularString,
                  fontSize: 11.5,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? ColorConst.themeColor
                      : ColorConst.settingTextColors,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 4. Platform-Specific Steps (ONLY selected platform shown) ────────────────
class _PlatformStepsList extends StatelessWidget {
  final bool isIos;

  const _PlatformStepsList({required this.isIos});

  @override
  Widget build(BuildContext context) {
    final steps = isIos ? _getIosSteps() : _getAndroidSteps();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            isIos ? howToAddOnIphoneString : howToAddOnAndroidString,
            style: TextStyle(
              fontFamily: fontInterBoldString,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ColorConst.settingTextColors,
            ),
          ),
        ),

        // Steps List Box
        Container(
          decoration: BoxDecoration(
            color: ColorConst.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ColorConst.textBorder.withOpacity(0.2),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: ColorConst.textBorder.withOpacity(0.15),
              indent: 48,
            ),
            itemBuilder: (context, index) {
              final step = steps[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Step Number Pill
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: ColorConst.themeColor.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        step.number,
                        style: TextStyle(
                          fontFamily: fontInterBoldString,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ColorConst.themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Step Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontFamily: fontInterSemiBoldString,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: ColorConst.settingTextColors,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            step.description,
                            style: TextStyle(
                              fontFamily: fontInterRegularString,
                              fontSize: 11.5,
                              color: ColorConst.textgrey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),
                    Icon(
                      step.icon,
                      size: 16,
                      color: ColorConst.themeColor.withOpacity(0.7),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<_StepModel> _getAndroidSteps() {
    return [
      _StepModel(
        number: "01",
        title: openHomeScreenString,
        description: longPressEmptyAreaString,
        icon: Icons.touch_app_rounded,
      ),
      _StepModel(
        number: "02",
        title: openWidgetsString,
        description: tapWidgetsBottomMenuString,
        icon: Icons.widgets_rounded,
      ),
      _StepModel(
        number: "03",
        title: searchTaxHrmString,
        description: findTaxHrmSelectPunchWidgetString,
        icon: Icons.search_rounded,
      ),
      _StepModel(
        number: "04",
        title: addWidgetString,
        description: tapAddWidgetOrDragString,
        icon: Icons.add_to_home_screen_rounded,
      ),
      _StepModel(
        number: "05",
        title: positionAndResizeString,
        description: moveOrResizeWidgetString,
        icon: Icons.open_with_rounded,
      ),
      _StepModel(
        number: "06",
        title: startPunchingString,
        description: tapWidgetAnytimeString,
        icon: Icons.fingerprint_rounded,
      ),
    ];
  }

  List<_StepModel> _getIosSteps() {
    return [
      _StepModel(
        number: "01",
        title: openHomeScreenString,
        description: touchAndHoldEmptySpaceString,
        icon: Icons.touch_app_rounded,
      ),
      _StepModel(
        number: "02",
        title: tapPlusButtonString,
        description: tapPlusButtonUpperLeftString,
        icon: Icons.add_circle_outline_rounded,
      ),
      _StepModel(
        number: "03",
        title: searchTaxHrmString,
        description: searchForTaxHrmSelectPunchWidgetString,
        icon: Icons.search_rounded,
      ),
      _StepModel(
        number: "04",
        title: addWidgetString,
        description: tapAddWidgetAtBottomString,
        icon: Icons.add_to_home_screen_rounded,
      ),
      _StepModel(
        number: "05",
        title: organizeAndDoneString,
        description: moveWidgetToDesiredSpotString,
        icon: Icons.space_dashboard_rounded,
      ),
      _StepModel(
        number: "06",
        title: startPunchingString,
        description: tapWidgetAnytimeString,
        icon: Icons.fingerprint_rounded,
      ),
    ];
  }
}

class _StepModel {
  final String number;
  final String title;
  final String description;
  final IconData icon;

  _StepModel({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });
}

// ── 5. Compact Bottom Action Bar ─────────────────────────────────────────────
class _CompactBottomCTA extends StatelessWidget {
  final VoidCallback onGotIt;
  final VoidCallback onViewAgain;

  const _CompactBottomCTA({
    required this.onGotIt,
    required this.onViewAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ColorConst.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: ColorConst.textBorder.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: onGotIt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConst.themeColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  gotItString,
                  style: const TextStyle(
                    fontFamily: fontInterBoldString,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
