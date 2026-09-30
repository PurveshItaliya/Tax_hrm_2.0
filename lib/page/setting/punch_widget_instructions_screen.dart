import 'dart:io';
import 'package:flutter/material.dart';
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


                    // 2. Features Grid Summary

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

// ── 1. Compact Widget Preview ────────────────────────────────────────────────
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
      child: Column(
        children: [


          // Exact Match Widget Card (Blue Rounded Pill)
          Container(
            width: 250,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1864EC),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1864EC).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "PUNCH",
                  style: TextStyle(
                    fontFamily: fontInterBoldString,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tap to open app",
                  style: TextStyle(
                    fontFamily: fontInterMediumString,
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Add this widget to your Home Screen for a quick shortcut. Tapping it will instantly open the app directly to the Punch screen.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontInterRegularString,
              fontSize: 12.5,
              color: ColorConst.textgrey,
              height: 1.4,
            ),
          ),
        ],
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
            isIos ? "How to add on iPhone" : "How to add on Android",
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
        title: "Open Home Screen",
        description: "Long-press an empty area on your phone's Home Screen.",
        icon: Icons.touch_app_rounded,
      ),
      _StepModel(
        number: "02",
        title: "Open Widgets",
        description: "Tap Widgets from the bottom menu options.",
        icon: Icons.widgets_rounded,
      ),
      _StepModel(
        number: "03",
        title: "Search TAX HRM",
        description: "Find TAX HRM and select the Punch Widget.",
        icon: Icons.search_rounded,
      ),
      _StepModel(
        number: "04",
        title: "Add Widget",
        description: "Tap Add Widget or drag it to your Home Screen.",
        icon: Icons.add_to_home_screen_rounded,
      ),
      _StepModel(
        number: "05",
        title: "Position & Resize",
        description: "Move or resize the widget according to your choice.",
        icon: Icons.open_with_rounded,
      ),
      _StepModel(
        number: "06",
        title: "Start Punching",
        description: "Tap the widget anytime to open the app directly to the Punch screen.",
        icon: Icons.fingerprint_rounded,
      ),
    ];
  }

  List<_StepModel> _getIosSteps() {
    return [
      _StepModel(
        number: "01",
        title: "Open Home Screen",
        description: "Touch and hold an empty space on your Home Screen.",
        icon: Icons.touch_app_rounded,
      ),
      _StepModel(
        number: "02",
        title: "Tap + Button",
        description: "Tap the + button in the upper-left corner.",
        icon: Icons.add_circle_outline_rounded,
      ),
      _StepModel(
        number: "03",
        title: "Search TAX HRM",
        description: "Search for TAX HRM and select the Punch Widget.",
        icon: Icons.search_rounded,
      ),
      _StepModel(
        number: "04",
        title: "Add Widget",
        description: "Tap Add Widget at the bottom to place it on screen.",
        icon: Icons.add_to_home_screen_rounded,
      ),
      _StepModel(
        number: "05",
        title: "Organize & Done",
        description: "Move the widget to your desired spot and tap Done.",
        icon: Icons.space_dashboard_rounded,
      ),
      _StepModel(
        number: "06",
        title: "Start Punching",
        description: "Tap the widget anytime to open the app directly to the Punch screen.",
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
                child: const Text(
                  "Got it",
                  style: TextStyle(
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
