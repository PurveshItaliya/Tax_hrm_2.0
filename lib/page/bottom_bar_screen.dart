// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:provider/provider.dart';

import 'package:tax_hrm/controllers/main_bottom_bar_controller.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/attendance/showviewdata.dart';
import 'package:tax_hrm/page/attendance/viewAttendance_screen.dart';
import 'package:tax_hrm/page/home/home_screen.dart';
import 'package:tax_hrm/page/home/selfie_punch_screen.dart';
import 'package:tax_hrm/page/leave/admin_leave_page.dart';
import 'package:tax_hrm/page/leave/leavepage.dart';
import 'package:tax_hrm/page/setting/setting_page.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/theme_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/common_dialogBox.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widgets/native_liquid_glass_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Interaction state enum
// ─────────────────────────────────────────────────────────────────────────────
enum _BarState { idle, pressed, dragging, settling }

// ─────────────────────────────────────────────────────────────────────────────
// Top-level animated bottom bar — all GetX / routing logic UNCHANGED
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedBottomBar extends StatelessWidget {
  AnimatedBottomBar({super.key});

  final MainBottomBarController controller =
      Get.put(MainBottomBarController());

  bool get isAdmin => curentUser['Role'] == 'Admin';

  List<Widget> get pageList {
    if (isAdmin) {
      return [
        HomeScreen(),
        ShowAttenDanceEmployeData(),
        AdminLeavePage(),
        SettingPage(),
      ];
    }
    return [
      HomeScreen(),
      AttendanceScreen(empData: null),
      LeaveViewPage(),
      SettingPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final internetProvider = context.watch<InternetConnectionProvider>();

    // Keep listening for theme and language changes.
    context.watch<ThemeProvider>();
    context.watch<LanguageProvider>();

    return WillPopScope(
      onWillPop: () => commonDialogBoxDesign(
        context: context,
        size: size,
        title: exitString,
      ),
      child: internetProvider.connectionType == 0
          ? const NoInternetViewPage()
          : Obx(() {
              final selectedPage = controller.fabSelected.value
                  ? SelfiePunchScreen()
                  : pageList[controller.selectedIndex.value];

              // ── iOS: use the real native UITabBar (Liquid Glass on iOS 26+) ──
              if (Platform.isIOS && !controller.fabSelected.value) {
                return Scaffold(
                  backgroundColor: ColorConst.scaffoldColor,
                  extendBody: true,
                  body: selectedPage,
                  bottomNavigationBar: NativeLiquidGlassBar(
                    key: ValueKey(
                      context.watch<LanguageProvider>().currentLanguage,
                    ),
                    currentIndex: controller.selectedIndex.value,
                    onTap: controller.changeTab,
                    tintColor: ColorConst.themeColor,
                    items: isAdmin
                        ? [
                            LiquidTabItem(
                              label: homeString,
                              symbol: 'house',
                              selectedSymbol: 'house.fill',
                            ),
                            LiquidTabItem(
                              label: attendanceString,
                              symbol: 'calendar',
                              selectedSymbol: 'calendar',
                            ),
                            LiquidTabItem(
                              label: leaveString,
                              symbol: 'doc.text',
                              selectedSymbol: 'doc.text.fill',
                            ),
                            LiquidTabItem(
                              label: settingString,
                              symbol: 'gearshape',
                              selectedSymbol: 'gearshape.fill',
                            ),
                          ]
                        : [
                            LiquidTabItem(
                              label: homeString,
                              symbol: 'house',
                              selectedSymbol: 'house.fill',
                            ),
                            LiquidTabItem(
                              label: attendanceString,
                              symbol: 'calendar',
                              selectedSymbol: 'calendar',
                            ),
                            LiquidTabItem(
                              label: leaveString,
                              symbol: 'doc.text',
                              selectedSymbol: 'doc.text.fill',
                            ),
                            LiquidTabItem(
                              label: settingString,
                              symbol: 'gearshape',
                              selectedSymbol: 'gearshape.fill',
                            ),
                          ],
                  ),
                );
              }

              // ── iOS FAB / other platforms: Flutter Liquid Glass bar ──
              return Scaffold(
                backgroundColor: ColorConst.scaffoldColor,
                extendBody: true,
                body: LiquidGlassView(
                  backgroundWidget: selectedPage,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _LiquidNavBar(
                          key: ValueKey(
                            context
                                .watch<LanguageProvider>()
                                .currentLanguage,
                          ),
                          isAdmin: isAdmin,
                          selectedIndex: controller.selectedIndex.value,
                          fabSelected: controller.fabSelected.value,
                          onTabSelected: controller.changeTab,
                          onPunchSelected: controller.selectFab,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab data model
// ─────────────────────────────────────────────────────────────────────────────
class _TabData {
  const _TabData({required this.asset, required this.title});
  final String asset;
  final String title;
}

// ─────────────────────────────────────────────────────────────────────────────
// _LiquidNavBar — StatefulWidget that owns all animation state
// ─────────────────────────────────────────────────────────────────────────────
class _LiquidNavBar extends StatefulWidget {
  const _LiquidNavBar({
    super.key,
    required this.isAdmin,
    required this.selectedIndex,
    required this.fabSelected,
    required this.onTabSelected,
    required this.onPunchSelected,
  });

  final bool isAdmin;
  final int selectedIndex;
  final bool fabSelected;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onPunchSelected;

  @override
  State<_LiquidNavBar> createState() => _LiquidNavBarState();
}

class _LiquidNavBarState extends State<_LiquidNavBar>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _slideCtrl;
  late final AnimationController _liftCtrl;
  late final AnimationController _pressCtrl;
  late final AnimationController _stretchCtrl;

  // ── Animated values ────────────────────────────────────────────────────────
  late Animation<double> _dropXAnim;  // slide X animation
  late Animation<double> _stretchAnim; // –1 (left) … 0 … +1 (right)

  // Live values (updated directly during drag)
  final ValueNotifier<double> _dropX = ValueNotifier(0);
  final ValueNotifier<double> _liftProgress = ValueNotifier(0);
  final ValueNotifier<double> _pressProgress = ValueNotifier(0);
  final ValueNotifier<double> _stretchProgress = ValueNotifier(0);

  // ── Gesture state (Listener-based — no arena conflicts) ─────────────────────
  _BarState _barState = _BarState.idle;
  int _committedIndex = 0;    // drives actual navigation
  int _previewIndex = 0;      // visual target during drag
  int _lastHapticIndex = -1;  // track haptic boundaries

  // Raw pointer tracking
  bool _pointerDown = false;
  Offset _pointerDownPos = Offset.zero;
  bool _isDragging = false;
  bool _isLongPressed = false;
  Timer? _longPressTimer;

  // ── Layout cache (set once the bar is laid out) ────────────────────────────
  double _barWidth = 0;
  double _pillWidth = 0;

  // ── Tab definitions (not const — strings are runtime values) ───────────────
  static final List<_TabData> _adminTabs = [
    _TabData(asset: homeImageString, title: homeString),
    _TabData(asset: attendanceImageString, title: attendanceString),
    _TabData(asset: leaveImageString, title: leaveString),
    _TabData(asset: settingImageString, title: settingString),
  ];
  static final List<_TabData> _employeeTabs = [
    _TabData(asset: homeImageString, title: homeString),
    _TabData(asset: attendanceImageString, title: attendanceString),
    _TabData(asset: leaveImageString, title: leaveString),
    _TabData(asset: settingImageString, title: settingString),
  ];

  // ── Glass style for punch button (unchanged) ───────────────────────────────
  static const LiquidGlassStyle _punchGlassStyle = LiquidGlassStyle(
    shape: LiquidGlassShape.roundedRectangle(
      cornerRadius: 100,
      borderWidth: 0,
    ),
    appearance: LiquidGlassAppearance(
      color: Color(0x32FFFFFF),
      saturation: 1.20,
      blur: LiquidGlassBlur(sigmaX: 5, sigmaY: 5),
    ),
    refraction: LiquidGlassRefraction(
      refractionType: OpticalRefraction(
        refraction: 1.55,
        refractionWidth: 20,
        depth: 0.80,
      ),
    ),
  );

  // ── Geometry helpers ───────────────────────────────────────────────────────

  /// Returns the X-center (in pill-local coords) for a logical tab index.
  /// For admin: 4 perfectly equal columns, no edge inset (flush to pill edges).
  /// For employee: 4 columns with a 72-wide gap in the middle (punch button).
  double _centerForIndex(int index) {
    if (widget.isAdmin) {
      final slotW = (_pillWidth - 28.0) / 4; // 14px padding each side = 28px
      return 14.0 + slotW * index + slotW / 2;
    } else {
      final slotW = (_pillWidth - 28.0 - 72.0) / 4; // 72px center gap
      if (index <= 1) {
        return 14.0 + slotW * index + slotW / 2;
      } else {
        return 14.0 + slotW * 2 + 72.0 + slotW * (index - 2) + slotW / 2;
      }
    }
  }

  double get _dropNormalWidth {
    if (widget.isAdmin) {
      final slotW = (_pillWidth - 28.0) / 4;
      return slotW + 20.0; // increase width by 20
    } else {
      final slotW = (_pillWidth - 28.0 - 72.0) / 4;
      return slotW + 20.0; // increase width by 20
    }
  }

  int _indexFromX(double localX) {
    // localX is relative to the pill's left edge
    if (widget.isAdmin) {
      final slotW = (_pillWidth - 28.0) / 4;
      final x = localX - 14.0;
      if (x < 0) return 0;
      return (x / slotW).floor().clamp(0, 3);
    } else {
      final slotW = (_pillWidth - 28.0 - 72.0) / 4;
      final x = localX - 14.0;
      if (x < 0) return 0;
      if (x < slotW * 2) return (x / slotW).floor().clamp(0, 1);
      if (x < slotW * 2 + 72.0) {
        return x < slotW * 2 + 36.0 ? 1 : 2;
      }
      final x2 = x - slotW * 2 - 72.0;
      return (2 + (x2 / slotW).floor()).clamp(2, 3);
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _committedIndex = widget.selectedIndex;
    _previewIndex = widget.selectedIndex;

    _slideCtrl = AnimationController(vsync: this);
    _liftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),   // tap bounce: quick rise
      reverseDuration: const Duration(milliseconds: 300), // spring-fall
    );
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _stretchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _dropXAnim = AlwaysStoppedAnimation(0);
    _stretchAnim = AlwaysStoppedAnimation(0);

    _liftCtrl.addListener(() {
      _liftProgress.value = _liftCtrl.value;
    });
    _pressCtrl.addListener(() {
      _pressProgress.value = _pressCtrl.value;
    });
    _stretchCtrl.addListener(() {
      _stretchProgress.value = _stretchAnim.value;
    });
  }

  @override
  void didUpdateWidget(_LiquidNavBar old) {
    super.didUpdateWidget(old);
    // External navigation change (e.g. back button)
    if (old.selectedIndex != widget.selectedIndex && _barState == _BarState.idle) {
      _committedIndex = widget.selectedIndex;
      _previewIndex = widget.selectedIndex;
      if (_pillWidth > 0) _animateTo(widget.selectedIndex, fromExternal: true);
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _slideCtrl.dispose();
    _liftCtrl.dispose();
    _pressCtrl.dispose();
    _stretchCtrl.dispose();
    _dropX.dispose();
    _liftProgress.dispose();
    _pressProgress.dispose();
    _stretchProgress.dispose();
    super.dispose();
  }

  // ── Animation helpers ──────────────────────────────────────────────────────
  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  void _animateTo(int index, {bool fromExternal = false}) {
    final target = _centerForIndex(index);
    final current = _dropX.value;
    final diff = target - current;

    // Determine stretch direction
    if (!_reducedMotion && diff.abs() > 10) {
      final dir = diff > 0 ? 1.0 : -1.0;
      _stretchAnim = Tween<double>(begin: 0, end: dir).animate(
        CurvedAnimation(parent: _stretchCtrl, curve: Curves.easeOut),
      );
      _stretchCtrl.forward(from: 0).then((_) {
        // Return stretch
        _stretchAnim = Tween<double>(begin: dir, end: 0).animate(
          CurvedAnimation(parent: _stretchCtrl, curve: Curves.elasticOut),
        );
        _stretchCtrl.forward(from: 0);
      });
    }

    final ms = fromExternal
        ? 300
        : (_reducedMotion ? 80 : 300);

    _slideCtrl.duration = Duration(milliseconds: ms);
    _dropXAnim = Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
    );
    _slideCtrl.forward(from: 0);
    _slideCtrl.addListener(_onSlideUpdate);
  }

  void _onSlideUpdate() {
    _dropX.value = _dropXAnim.value;
  }

  void _snapTo(int index, {bool spring = true}) {
    _slideCtrl.removeListener(_onSlideUpdate);
    final target = _centerForIndex(index);
    final current = _dropX.value;

    final ms = _reducedMotion ? 80 : 270;
    _slideCtrl.duration = Duration(milliseconds: ms);
    _dropXAnim = Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(
        parent: _slideCtrl,
        curve: spring && !_reducedMotion
            ? Curves.easeOutBack
            : Curves.easeOutCubic,
      ),
    );
    _slideCtrl.forward(from: 0);
    _slideCtrl.addListener(_onSlideUpdate);
  }

  void _onLayoutReady(double barWidth) {
    if (_barWidth == barWidth && _pillWidth > 0) return;
    _barWidth = barWidth;
    _pillWidth = barWidth - 20; // 10px margin each side

    // Initialize drop position without animation
    final initialX = _centerForIndex(_committedIndex);
    _dropX.value = initialX;

    // Must call setState so _GlassDropLayer rebuilds with the real
    // pillWidth/dropNormalWidth values (they were 0 on first paint).
    if (mounted) setState(() {});
  }

  // ── Pointer handlers (single Listener — no gesture arena conflicts) ──────────

  /// Called the moment the finger touches down.
  void _onPointerDown(PointerDownEvent e) {
    if (_pillWidth == 0) return;
    _pointerDown = true;
    _pointerDownPos = e.localPosition;
    _isDragging = false;
    _isLongPressed = false;
    _barState = _BarState.pressed;

    // Cancel any ongoing bounce/lift from a previous interaction so
    // it cannot bleed into this new gesture.
    _liftCtrl.stop();
    _liftCtrl.value = 0;

    // Subtle press squash
    if (!_reducedMotion) _pressCtrl.forward(from: 0);

    // Long-press timer triggers the lift if dragging hasn't started yet.
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 450), () {
      if (!_pointerDown || _isDragging) return;
      _isLongPressed = true;
      _barState = _BarState.dragging;
      _lastHapticIndex = _committedIndex;
      if (!_reducedMotion) {
        _liftCtrl.forward();
        _pressCtrl.reverse();
      }
      HapticFeedback.mediumImpact();
    });
  }

  /// Called on every pointer movement.
  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointerDown) return;
    final delta = e.localPosition - _pointerDownPos;

    // Enter DRAG mode when horizontal movement > 8px
    if (!_isDragging && !_isLongPressed &&
        delta.dx.abs() > 8 &&
        delta.dx.abs() > delta.dy.abs()) {
      _isDragging = true;
      _longPressTimer?.cancel();
      _barState = _BarState.dragging;
      _lastHapticIndex = _committedIndex;
      if (!_reducedMotion) {
        _pressCtrl.reverse();
        // Lift the pill even on a quick swipe/drag
        _liftCtrl.forward();
      }
    }

    if (_isDragging || _isLongPressed) {
      // Cancel on large downward drag
      if (delta.dy > 35) {
        _onPointerCancel(null);
        return;
      }

      // localPosition.dx is already pill-relative (Positioned starts at pill edge)
      final localX = e.localPosition.dx.clamp(0.0, _pillWidth);
      final nearestIndex = _indexFromX(localX).clamp(0, 3);

      // Follow finger DIRECTLY — natural sliding without stopping between tabs.
      // The GlassDropLayer clamps the rendered position to pill bounds.
      _dropX.value = localX;

      // Haptic + color update on tab crossing
      if (nearestIndex != _lastHapticIndex) {
        _previewIndex = nearestIndex;
        _lastHapticIndex = nearestIndex;
        HapticFeedback.selectionClick();
        setState(() {}); // update icon/label colors
      }
    }
  }

  /// Called when the finger lifts.
  void _onPointerUp(PointerUpEvent e) {
    if (!_pointerDown) return;
    _longPressTimer?.cancel();
    _pointerDown = false;

    if (_isDragging || _isLongPressed) {
      // Commit nearest tab from release position
      final localX = e.localPosition.dx.clamp(0.0, _pillWidth);
      final releasedIndex = _indexFromX(localX).clamp(0, 3);

      _barState = _BarState.settling;
      _committedIndex = releasedIndex;
      _previewIndex = releasedIndex;
      _snapTo(releasedIndex, spring: true);

      if (!_reducedMotion) _liftCtrl.reverse();
      widget.onTabSelected(releasedIndex);
      setState(() {});

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _barState = _BarState.idle);
      });
    } else {
      // Pure tap — navigate immediately
      if (!_reducedMotion) _pressCtrl.reverse();
      _barState = _BarState.idle;

      // localPosition.dx is pill-relative (no need to subtract _pillLeft)
      final localX = e.localPosition.dx.clamp(0.0, _pillWidth);
      final tappedIndex = _indexFromX(localX).clamp(0, 3);

      // If they tapped a different tab, OR if they are currently on the Punch screen
      // (in which case tapping ANY tab should close the punch screen).
      if (tappedIndex != _committedIndex || widget.fabSelected) {
        _committedIndex = tappedIndex;
        _previewIndex = tappedIndex;
        _animateTo(tappedIndex);
        widget.onTabSelected(tappedIndex);
        setState(() {});

        // Pop bounce: pill briefly grows then springs back
        if (!_reducedMotion) {
          _liftCtrl.forward(from: 0).then((_) {
            if (mounted) _liftCtrl.reverse();
          });
        }
      }
    }

    _isDragging = false;
    _isLongPressed = false;
  }

  /// Called when the system cancels the pointer (call, notification, etc.).
  void _onPointerCancel(PointerCancelEvent? e) {
    _longPressTimer?.cancel();
    _pointerDown = false;
    _isDragging = false;
    _isLongPressed = false;

    // Restore to committed tab
    _previewIndex = _committedIndex;
    _barState = _BarState.settling;
    _snapTo(_committedIndex, spring: false);
    if (!_reducedMotion) {
      _liftCtrl.reverse();
      _pressCtrl.reverse();
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _barState = _BarState.idle);
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final tabs =
        widget.isAdmin ? _adminTabs : _employeeTabs;

    final barGlassStyle = LiquidGlassStyle(
      shape: LiquidGlassShape.continuousRoundedRectangle(
        cornerRadius: 100,
        borderWidth: 0,
        borderColor: isDark
            ? Colors.grey.withOpacity(0.05)
            : Colors.white.withOpacity(0.50),
        clipQuality: LiquidGlassClipQuality.roundedRectangle,
      ),
      appearance: LiquidGlassAppearance(
        // Increased opacity for better visibility
        color: isDark
            ? const Color(0x89000000) // 60% black
            : const Color(0x5CFFFFFF), // 70% white
        saturation: 1.8,
        blur: const LiquidGlassBlur(sigmaX: 7, sigmaY: 7),
      ),
      refraction: const LiquidGlassRefraction(
        refractionType: OpticalRefraction(
          refraction: 1.5,
          refractionWidth: 18,
          depth: 1.1,
        ),
      ),
    );

    return SizedBox(
      height: (widget.isAdmin ? 72 : 86) + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none, // allow drop to rise above pill
        alignment: Alignment.bottomCenter,
        children: [
          // ── Glass pill background ───────────────────────────────────────
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            height: 62,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _onLayoutReady(constraints.maxWidth + 20); // include margins
                });
                // Wrapping in a standard Container to draw a proper border,
                // bypassing the buggy LiquidGlassShape border rendering.
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.12) // subtle white border for dark
                          : Colors.white.withOpacity(0.80), // strong white border for light
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: RepaintBoundary(
                      child: LiquidGlassLens(
                        style: barGlassStyle,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Moving glass drop (sits between background and icons) ────────
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            height: 62,
            child: RepaintBoundary(
              child: _GlassDropLayer(
                isDark: isDark,
                fabSelected: widget.fabSelected,
                dropX: _dropX,
                liftProgress: _liftProgress,
                pressProgress: _pressProgress,
                stretchProgress: _stretchProgress,
                dropNormalWidth: _dropNormalWidth,
                pillWidth: _pillWidth,
                reducedMotion: _reducedMotion,
              ),
            ),
          ),

          // ── Tab icons & labels (fixed — never move) ──────────────────────
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            height: 62,
            // Listener gives raw pointer events — no gesture arena, no conflicts
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: widget.isAdmin
                    ? _buildAdminTabRow(tabs, isDark)
                    : _buildEmployeeTabRow(tabs, isDark),
              ),
            ),
          ),

          // ── Employee punch FAB ───────────────────────────────────────────
          if (!widget.isAdmin)
            Positioned(
              bottom: 35, // Perfectly vertically centered within the 62px height bar (which is at bottom: 10)
              child: _LiquidPunchButton(
                selected: widget.fabSelected,
                onTap: widget.onPunchSelected,
                glassStyle: _punchGlassStyle,
              ),
            ),
        ],
      ),
    );
  }

  // Pure visual rows — tap/drag is handled entirely by the parent Listener
  Widget _buildAdminTabRow(List<_TabData> tabs, bool isDark) {
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: _TabItem(
            asset: tabs[i].asset,
            title: tabs[i].title,
            selected: i == _previewIndex && !widget.fabSelected,
            isDark: isDark,
          ),
        );
      }),
    );
  }

  Widget _buildEmployeeTabRow(List<_TabData> tabs, bool isDark) {
    return Row(
      children: [
        for (int i = 0; i < 2; i++)
          Expanded(
            child: _TabItem(
              asset: tabs[i].asset,
              title: tabs[i].title,
              selected: i == _previewIndex && !widget.fabSelected,
              isDark: isDark,
            ),
          ),
        const SizedBox(width: 72), // space for punch button
        for (int i = 2; i < 4; i++)
          Expanded(
            child: _TabItem(
              asset: tabs[i].asset,
              title: tabs[i].title,
              selected: i == _previewIndex && !widget.fabSelected,
              isDark: isDark,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GlassDropLayer — renders only the moving glass drop
// ─────────────────────────────────────────────────────────────────────────────
class _GlassDropLayer extends StatelessWidget {
  const _GlassDropLayer({
    required this.isDark,
    required this.fabSelected,
    required this.dropX,
    required this.liftProgress,
    required this.pressProgress,
    required this.stretchProgress,
    required this.dropNormalWidth,
    required this.pillWidth,
    required this.reducedMotion,
  });

  final bool isDark;
  final bool fabSelected;
  final ValueNotifier<double> dropX;
  final ValueNotifier<double> liftProgress;
  final ValueNotifier<double> pressProgress;
  final ValueNotifier<double> stretchProgress;
  final double dropNormalWidth;
  final double pillWidth;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    if (dropNormalWidth <= 0 || pillWidth <= 0) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: fabSelected ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: AnimatedBuilder(
        animation: Listenable.merge([
        dropX,
        liftProgress,
        pressProgress,
        stretchProgress,
      ]),
      builder: (ctx, _) {
        final lift = reducedMotion ? 0.0 : liftProgress.value;
        final press = reducedMotion ? 0.0 : pressProgress.value;
        final stretch = reducedMotion ? 0.0 : stretchProgress.value;

        // ── Drop geometry ───────────────────────────────────────────────
        // normalH = 54px inside a 62px pill — 4px padding top & bottom.
        // No baseLift at idle: the pill is perfectly centred in the bar.
        // liftCtrl animates it upward only during long-press / drag.
        final stretchExtra = dropNormalWidth * 0.18 * stretch.abs();
        final currentWidth = dropNormalWidth + stretchExtra;
        const normalH = 54.0;
        final liftedExtra = lift * 16.0;   // rises 16px on long-press
        final pressedSquash = press * 4.0;
        final currentH = normalH + liftedExtra - pressedSquash;

        // Vertical: centred growth — top formula handles both up & down

        // Horizontal: center the drop on dropX (clamped to pill bounds)
        final left = dropX.value - currentWidth / 2;
        final clampedLeft = left.clamp(0.0, pillWidth - currentWidth);


        // Stack with Clip.none so the lifted drop can rise ABOVE the pill
        // without being clipped by the container bounds.
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: clampedLeft,
              // Centre-anchored growth: as currentH increases the pill
              // expands equally upward AND downward — centre stays fixed.
              top: (62 - currentH) / 2 + (press * 2.0),
              width: currentWidth,
              height: currentH,
              child: RepaintBoundary(
                // LiquidGlassLens provides real-time blur + refraction
                // magnification — replacing the manual BackdropFilter stack.
                child: LiquidGlassLens(
                  style: LiquidGlassStyle(
                    shape: LiquidGlassShape.continuousRoundedRectangle(
                      cornerRadius: 50,
                      borderWidth: 0.1,
                      borderColor: isDark
                          ? Colors.white.withOpacity(0.20)
                          : Colors.white.withOpacity(0.78),
                      clipQuality: LiquidGlassClipQuality.roundedRectangle,
                    ),
                    appearance: LiquidGlassAppearance(
                      color: Color.lerp(
                            isDark ? const Color(0x8E7E7E7E) : const Color(
                                0x2A1E1616), // Idle: Opaque
                            isDark ? const Color(0x401C1C1E) : const Color(0x40FFFFFF), // Drag: True transparent glass
                            lift,
                          ) ??
                          (isDark ? const Color(0xEE1C1C1E) : const Color(0xFAFFFFFF)),
                      saturation: 1.0 + (2.0 * lift), // 1.0 -> 3.0 (high saturation for glassy look)
                      blur: LiquidGlassBlur(
                        sigmaX: 40.0 * lift, // Deep blur
                        sigmaY: 40.0 * lift,
                      ),
                    ),
                    refraction: LiquidGlassRefraction(
                      refractionType: OpticalRefraction(
                        refraction: 1.0 + (1.0 * lift),      // 1.0 -> 2.0 (strong optical distortion)
                        refractionWidth: 32.0 * lift,        // 0 -> 32
                        depth: 1 * lift,                  // 0 -> 1.50 (thick glass depth)
                      ),
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        );
      },
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TabItem — purely visual, no GestureDetector.
// All touch handling is done by the parent Listener in _LiquidNavBarState.
class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.asset,
    required this.title,
    required this.selected,
    required this.isDark,
  });

  final String asset;
  final String title;
  final bool selected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark ? Colors.white : ColorConst.black;
    final unselectedColor =
        isDark ? Colors.white.withOpacity(0.48) : ColorConst.bottomIconColor;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: SizedBox(
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon — clearly larger when selected (matches reference images)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                // Selected: 23px (noticeably bigger), unselected: 17px
                height: selected ? 23 : 17,
                width:  selected ? 23 : 17,
                child: SvgPicture.asset(
                  asset,
                  colorFilter: ColorFilter.mode(
                    selected ? selectedColor : unselectedColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(height: selected ? 4 : 2),
              // Label — larger and bolder when selected
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: TextStyle(
                  // Selected: 11.5px heavy, unselected: 9px regular
                  fontSize: selected ? 11.5 : 9.0,
                  color: selected ? selectedColor : unselectedColor,
                  fontFamily: fontInterMediumString,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LiquidPunchButton — UNCHANGED from original
// ─────────────────────────────────────────────────────────────────────────────
class _LiquidPunchButton extends StatelessWidget {
  const _LiquidPunchButton({
    required this.selected,
    required this.onTap,
    required this.glassStyle,
  });

  final bool selected;
  final VoidCallback onTap;
  final LiquidGlassStyle glassStyle;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.08 : 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      child: SizedBox(
        height: 58,
        width: 58,
        child: RepaintBoundary(
          child: LiquidGlassLens(
            style: glassStyle,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: selected
                          ? [
                              ColorConst.darkGreenColor,
                              ColorConst.themeColor,
                            ]
                          : [
                              ColorConst.themeColor,
                              ColorConst.darkGreenColor,
                            ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.80),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConst.themeColor
                            .withOpacity(selected ? 0.40 : 0.22),
                        blurRadius: selected ? 18 : 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      tapImageString,
                      height: 31,
                      width: 31,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}