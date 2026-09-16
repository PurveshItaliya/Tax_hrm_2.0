// ignore_for_file: deprecated_member_use, avoid_print, unnecessary_underscores

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/models/timeline_event.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/services/location_timeline_processor.dart';
import 'package:tax_hrm/services/smart_timeline_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

class SmartTimelineScreen extends StatefulWidget {
  final String userId;
  const SmartTimelineScreen({super.key, required this.userId});

  @override
  State<SmartTimelineScreen> createState() => _SmartTimelineScreenState();
}

class _SmartTimelineScreenState extends State<SmartTimelineScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  int? _selectedEventIndex;   // marker tap highlight
  int? _focusedEventIndex;    // list tap highlight (from bottom sheet)
  bool _isSheetOpen = true;
  bool _hasMapFitted = false;
  final Set<int> _expandedSessionIndexes = {0};
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late VoidCallback _sheetListener;

  @override
  void initState() {
    super.initState();
    // Signal background service: user is on map → use 5-min upload interval
    SharedPreferences.getInstance().then((p) => p.setBool('MapActive', true));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Store listener reference so we can remove it in dispose —
    // failing to do so causes a leak because the sheet retains the closure.
    _sheetListener = () {
      if (mounted && _sheetController.isAttached) {
        final open = _sheetController.size > 0.05;
        if (open != _isSheetOpen) setState(() => _isSheetOpen = open);
      }
    };
    _sheetController.addListener(_sheetListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SmartTimelineProvider>(
        context,
        listen: false,
      ).load(empId: widget.userId);
    });
  }

  @override
  void dispose() {
    // Clear MapActive flag so background service reverts to 10-min interval
    SharedPreferences.getInstance().then((p) => p.setBool('MapActive', false));

    // Properly remove listener to avoid closure leak
    _sheetController.removeListener(_sheetListener);
    _sheetController.dispose();

    _pulseController.dispose();
    _mapController.dispose(); // MapController holds tile textures in memory

    // Reset provider state so large GPS arrays are freed from memory
    // Use a post-frame callback so it runs after this frame completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only reset if the context is still valid (provider still alive)
      try {
        AddressResolver.clearCache();
      } catch (_) {}
    });

    super.dispose();
  }

  void _openSheet() {
    setState(() => _isSheetOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.55,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _closeSheet() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Map helpers ────────────────────────────────────────────────────────────
  void _fitMapToEvents(List<TimelineEvent> events) {
    if (events.isEmpty) return;
    final lats = events.map((e) => e.latitude).where((v) => v != 0).toList();
    final lngs = events.map((e) => e.longitude).where((v) => v != 0).toList();
    if (lats.isEmpty) return;

    final south = lats.reduce((a, b) => a < b ? a : b);
    final north = lats.reduce((a, b) => a > b ? a : b);
    final west = lngs.reduce((a, b) => a < b ? a : b);
    final east = lngs.reduce((a, b) => a > b ? a : b);

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(LatLng(south, west), LatLng(north, east)),
          padding: const EdgeInsets.fromLTRB(60, 120, 60, 320),
        ),
      );
    } catch (_) {}
  }

  /// Called when user taps a punch/stop in the bottom sheet list.
  /// Animates the map to that event, highlights it, and partially collapses the sheet.
  void _focusOnEvent(TimelineEvent ev, int globalIndex) {
    if (ev.latitude == 0 && ev.longitude == 0) return;

    setState(() {
      _selectedEventIndex = globalIndex;
      _focusedEventIndex = globalIndex;
    });

    // Animate map to the event location
    try {
      _mapController.move(LatLng(ev.latitude, ev.longitude), 16.0);
    } catch (_) {}

    // Partially collapse sheet so map is visible
    if (_sheetController.isAttached && _sheetController.size > 0.35) {
      _sheetController.animateTo(
        0.35,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Marker builders ────────────────────────────────────────────────────────
  Widget _punchInMarker(bool isSelected) => AnimatedBuilder(
    animation: _pulseAnim,
    builder: (_, __) => Container(
      width: isSelected ? 34 : 28,
      height: isSelected ? 34 : 28,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(isSelected ? 0.6 : 0.35),
            blurRadius: isSelected ? 12 * _pulseAnim.value : 6,
            spreadRadius: isSelected ? 3 * _pulseAnim.value : 1,
          ),
        ],
      ),
      child: const Icon(Icons.login_rounded, color: Colors.white, size: 14),
    ),
  );

  Widget _punchOutMarker(bool isSelected) => Container(
    width: isSelected ? 34 : 28,
    height: isSelected ? 34 : 28,
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2.5),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFEF4444).withOpacity(isSelected ? 0.6 : 0.35),
          blurRadius: isSelected ? 12 : 6,
        ),
      ],
    ),
    child: const Icon(Icons.logout_rounded, color: Colors.white, size: 14),
  );

  Widget _stayMarker(bool isSelected, int index) => Container(
    width: isSelected ? 32 : 26,
    height: isSelected ? 32 : 26,
    decoration: BoxDecoration(
      color: isSelected ? Colors.orange : ColorConst.themeColor,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: (isSelected ? Colors.orange : ColorConst.themeColor)
              .withOpacity(0.4),
          blurRadius: isSelected ? 10 : 5,
        ),
      ],
    ),
    child: Center(
      child: Text(
        '$index',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: fontInterSemiBoldString,
        ),
      ),
    ),
  );

  // ── Stay event tap detail card ─────────────────────────────────────────────
  void _showStayDetail(BuildContext ctx, TimelineEvent event) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorConst.themeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_pin,
                    color: ColorConst.themeColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Stop Detected',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ColorConst.black,
                    fontFamily: fontInterSemiBoldString,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConst.themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event.durationText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ColorConst.themeColor,
                      fontFamily: fontInterSemiBoldString,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(
              Icons.login,
              'Arrived',
              DateFormat('hh:mm a').format(event.startTime),
            ),
            const SizedBox(height: 8),
            _detailRow(
              Icons.logout,
              'Departed',
              DateFormat('hh:mm a').format(event.endTime ?? event.startTime),
            ),
            const SizedBox(height: 8),
            _detailRow(Icons.timer_outlined, 'Duration', event.durationText),
            const SizedBox(height: 8),
            _detailRow(
              Icons.location_on_outlined,
              'Address',
              event.address.isNotEmpty ? event.address : 'Resolving…',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: ColorConst.textgrey),
      const SizedBox(width: 8),
      Text(
        '$label: ',
        style: TextStyle(
          fontSize: 12,
          color: ColorConst.textgrey,
          fontFamily: fontInterMediumString,
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorConst.black,
            fontFamily: fontInterSemiBoldString,
          ),
        ),
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SmartTimelineProvider>(context);
    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    final size = MediaQuery.of(context).size;

    // Auto-fit map only once per data load — NOT every rebuild.
    // Putting addPostFrameCallback inside build() is a memory leak:
    // it registers a new callback on every setState/rebuild.
    if (!provider.isLoading && provider.events.isNotEmpty && !_hasMapFitted) {
      _hasMapFitted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMapToEvents(provider.events);
      });
    }
    // Reset the flag when a new load starts so the map re-fits after date change
    if (provider.isLoading) _hasMapFitted = false;

    // Build map markers from processed events
    final List<Marker> markers = [];
    int stopCounter = 1;

    for (int i = 0; i < provider.events.length; i++) {
      final ev = provider.events[i];
      if (ev.latitude == 0 && ev.longitude == 0) continue;
      final isSelected = _selectedEventIndex == i;
      final pt = LatLng(ev.latitude, ev.longitude);

      Widget child;
      switch (ev.type) {
        case TimelineEventType.punchIn:
          child = GestureDetector(
            onTap: () =>
                setState(() => _selectedEventIndex = isSelected ? null : i),
            child: _punchInMarker(isSelected),
          );
          break;
        case TimelineEventType.punchOut:
          child = GestureDetector(
            onTap: () =>
                setState(() => _selectedEventIndex = isSelected ? null : i),
            child: _punchOutMarker(isSelected),
          );
          break;
        case TimelineEventType.stay:
          final idx = stopCounter++;
          child = GestureDetector(
            onTap: () {
              setState(() => _selectedEventIndex = isSelected ? null : i);
              _showStayDetail(context, ev);
            },
            child: _stayMarker(isSelected, idx),
          );
          break;
      }

      markers.add(
        Marker(
          point: pt,
          width: isSelected ? 38 : 32,
          height: isSelected ? 38 : 32,
          child: child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── 1. Full-screen Map or Empty State ────────────────────────────────
          if (provider.isLoading)
            Positioned.fill(
              child: Container(
                color: ColorConst.scaffoldColor,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: ColorConst.themeColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fetching timeline data...',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorConst.textgrey,
                          fontFamily: fontInterMediumString,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (provider.events.isNotEmpty)
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: provider.events.isNotEmpty
                      ? LatLng(
                          provider.events.first.latitude,
                          provider.events.first.longitude,
                        )
                      : const LatLng(21.209371, 72.833692),
                  initialZoom: 13.0,
                  minZoom: 3.0,
                  maxZoom: 22.0,
                  onTap: (_, __) {
                    setState(() => _selectedEventIndex = null);
                    _closeSheet();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                    fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.hrmnewapp.taxhrm',
                    maxNativeZoom: 20,
                  ),
                  // Route polyline — split into focused (highlighted) and normal segments
                  if (provider.routeSegments.isNotEmpty) ...[
                    // Normal (dim) polyline
                    PolylineLayer(
                      polylines: provider.routeSegments
                          .where((segment) => segment.length > 1)
                          .map(
                            (segment) => Polyline(
                              points: segment,
                              strokeWidth: 3.0,
                              color: _focusedEventIndex != null
                                  ? ColorConst.themeColor.withOpacity(0.25)
                                  : ColorConst.themeColor.withOpacity(0.75),
                            ),
                          )
                          .toList(),
                    ),
                    // Highlighted segment: draw a thicker, bright segment near the focused event
                    if (_focusedEventIndex != null &&
                        _focusedEventIndex! < provider.events.length)
                      Builder(builder: (ctx) {
                        final focusedEv = provider.events[_focusedEventIndex!];
                        if (focusedEv.latitude == 0 && focusedEv.longitude == 0) {
                          return const SizedBox.shrink();
                        }
                        // Find nearest route point and build a short highlight segment
                        final focusLat = focusedEv.latitude;
                        final focusLng = focusedEv.longitude;
                        final LatLng focusPt = LatLng(focusLat, focusLng);

                        // Collect all route points near the focused event (within ~500m window)
                        final List<LatLng> highlightPts = [];
                        for (final seg in provider.routeSegments) {
                          for (int ri = 0; ri < seg.length; ri++) {
                            final pt = seg[ri];
                            final distM = const Distance().as(
                              LengthUnit.Meter,
                              pt,
                              focusPt,
                            );
                            if (distM < 800) highlightPts.add(pt);
                          }
                        }
                        if (highlightPts.length < 2) {
                          // Just draw a two-point stub at the focus point
                          highlightPts.insert(0, focusPt);
                        }
                        final Color highlightColor = focusedEv.type == TimelineEventType.punchIn
                            ? const Color(0xFF22C55E)
                            : focusedEv.type == TimelineEventType.punchOut
                                ? const Color(0xFFEF4444)
                                : Colors.orange;
                        return PolylineLayer(
                          polylines: [
                            Polyline(
                              points: highlightPts,
                              strokeWidth: 5.5,
                              color: highlightColor.withOpacity(0.90),
                              strokeCap: StrokeCap.round,
                            ),
                          ],
                        );
                      }),
                  ],
                  // Event markers
                  MarkerLayer(markers: markers),
                ],
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: ColorConst.scaffoldColor,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage ?? 'No Location Data Available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorConst.black,
                          fontFamily: fontInterSemiBoldString,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The user has not punched in for this date.',
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorConst.textgrey,
                          fontFamily: fontInterMediumString,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── 2. Glassmorphic header ───────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 6,
                    left: 10,
                    right: 10,
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.88),
                        Colors.black.withOpacity(0.50),
                        Colors.black.withOpacity(0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.75, 1.0],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Back button
                      _headerBtn(
                        Icons.arrow_back_ios_new_rounded,
                        () => backScreen(context),
                      ),
                      const SizedBox(width: 10),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Smart Timeline',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: fontInterSemiBoldString,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (provider.isCurrentlyWorkedIn &&
                                    !provider.isLoading)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Live',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              DateFormat(
                                'dd MMMM yyyy',
                              ).format(provider.selectedDate),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withOpacity(0.8),
                                fontFamily: fontInterMediumString,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Date picker
                      GestureDetector(
                        onTap: () => datePickerProvider.pickDate(
                          context,
                          size,
                          provider.selectedDate,
                          null,
                          DateTime.now(),
                          (val) => provider.changeDate(val, widget.userId),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.30),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                DateFormat(
                                  'dd MMM',
                                ).format(provider.selectedDate),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: fontInterSemiBoldString,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Refresh
                      _headerBtn(
                        Icons.refresh_rounded,
                        () => provider.load(empId: widget.userId),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Summary strip (above sheet) ───────────────────────────────────
          if (!provider.isLoading && provider.hasData)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: IgnorePointer(
                ignoring: _isSheetOpen,
                child: AnimatedOpacity(
                  opacity: _isSheetOpen ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConst.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryTile(
                        Icons.route_rounded,
                        ColorConst.themeColor,
                        provider.totalDistanceLabel,
                        'Distance',
                      ),
                      _vDivider(),
                      _summaryTile(
                        Icons.timer_rounded,
                        const Color(0xFF22C55E),
                        provider.workingDurationLabel,
                        'Duration',
                      ),
                      _vDivider(),
                      _summaryTile(
                        Icons.pin_drop_rounded,
                        Colors.orange,
                        '${provider.stopsCount}',
                        'Stops',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── 4. Draggable bottom sheet ────────────────────────────────────────
          if (_isSheetOpen && !provider.isLoading && provider.events.isNotEmpty)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.55,
              minChildSize: 0.0,
              maxChildSize: 0.75,
              snap: true,
              snapSizes: const [0.0, 0.55, 0.75],
              builder: (ctx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: ColorConst.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Handle
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _closeSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          width: double.infinity,
                          child: Center(
                            child: Container(
                              width: 44,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: ColorConst.themeColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.route_rounded,
                                color: ColorConst.themeColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Movement Timeline',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: ColorConst.black,
                                fontFamily: fontInterSemiBoldString,
                              ),
                            ),
                            const Spacer(),
                            if (provider.isCurrentlyWorkedIn)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF22C55E,
                                  ).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Currently Working',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF22C55E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _closeSheet,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: ColorConst.greyOpicityColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 14, thickness: 0.8),

                      // ── Timeline event list ───────────────────────────────────
                      Expanded(
                        child: provider.events.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_off_rounded,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      provider.errorMessage ??
                                          'No movement data',
                                      style: TextStyle(
                                        color: ColorConst.textgrey,
                                        fontFamily: fontInterMediumString,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : () {
                                final sessions = _groupEventsIntoSessions(provider.events);
                                return ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    20,
                                  ),
                                  itemCount: sessions.length,
                                  itemBuilder: (_, sIndex) {
                                    final session = sessions[sIndex];
                                    final isExpanded = _expandedSessionIndexes.contains(sIndex);
                                    return _buildSessionCard(
                                      context,
                                      session,
                                      sIndex,
                                      isExpanded,
                                      provider,
                                    );
                                  },
                                );
                              }(),
                      ),
                    ],
                  ),
                );
              },
            ),

          // ── 5. Floating pill (when sheet is closed) ──────────────────────────
          if (!_isSheetOpen)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _openSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConst.themeColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConst.themeColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.isLoading
                              ? 'Processing…'
                              : 'Timeline (${provider.events.length} events)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontInterSemiBoldString,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── 6. Loading overlay ───────────────────────────────────────────────
          if (provider.isLoading)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: ColorConst.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                          ColorConst.themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Analysing movement data…',
                      style: TextStyle(
                        fontSize: 13,
                        color: ColorConst.black,
                        fontFamily: fontInterMediumString,
                      ),
                    ),
                  ],
                ),
              ),
            ),

        ],
      ),
    );
  }

  // ── Session Card (Unboxed Inner Data with Explicit Travel Steps) ─────────────
  Widget _buildSessionCard(
    BuildContext context,
    _TimelineSession session,
    int sIndex,
    bool isExpanded,
    SmartTimelineProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build chronological inner step widgets when expanded
    final List<Widget> innerStepWidgets = [];
    if (isExpanded) {
      TimelineEvent prevEv = session.punchInEvent;

      // 1. Punch IN
      final bool isOnlyPunchIn =
          session.innerStops.isEmpty && session.punchOutEvent == null;
      innerStepWidgets.add(
        _buildEventItem(
          context,
          session.punchInEvent,
          stopIndex: null,
          isFirst: true,
          isLast: isOnlyPunchIn,
          isDark: isDark,
          globalIndex: provider.events.indexOf(session.punchInEvent),
        ),
      );

      // 2. Inner Stops with explicit Travel steps before each stop
      for (int i = 0; i < session.innerStops.length; i++) {
        final stopEv = session.innerStops[i];
        final departureTime = prevEv.endTime ?? prevEv.startTime;
        final travelDuration = _formatTravelDuration(
          departureTime,
          stopEv.startTime,
        );

        Widget? travelBadge;
        if (stopEv.distanceFromPrevKm > 0 || travelDuration.isNotEmpty) {
          travelBadge = _buildTravelBadge(
            context,
            distanceText: stopEv.distanceLabel.isNotEmpty
                ? stopEv.distanceLabel
                : '${stopEv.distanceFromPrevKm.toStringAsFixed(1)} km',
            durationText: travelDuration,
            isDark: isDark,
          );
        }

        final isLastItem =
            (i == session.innerStops.length - 1) &&
            session.punchOutEvent == null;
        innerStepWidgets.add(
          _buildEventItem(
            context,
            stopEv,
            stopIndex: i + 1,
            isFirst: false,
            isLast: isLastItem,
            isDark: isDark,
            topTravelConnector: travelBadge,
            globalIndex: provider.events.indexOf(stopEv),
          ),
        );

        prevEv = stopEv;
      }

      // 3. Punch OUT with explicit Travel step before punch out
      if (session.punchOutEvent != null) {
        final poEv = session.punchOutEvent!;
        final departureTime = prevEv.endTime ?? prevEv.startTime;
        final travelDuration = _formatTravelDuration(
          departureTime,
          poEv.startTime,
        );

        Widget? travelBadge;
        if (poEv.distanceFromPrevKm > 0 || travelDuration.isNotEmpty) {
          travelBadge = _buildTravelBadge(
            context,
            distanceText: poEv.distanceLabel.isNotEmpty
                ? poEv.distanceLabel
                : '${poEv.distanceFromPrevKm.toStringAsFixed(1)} km',
            durationText: travelDuration,
            isDark: isDark,
          );
        }

        innerStepWidgets.add(
          _buildEventItem(
            context,
            poEv,
            stopIndex: null,
            isFirst: false,
            isLast: true,
            isDark: isDark,
            topTravelConnector: travelBadge,
            globalIndex: provider.events.indexOf(poEv),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Standalone Session Header Bar (Closed/Open Summary View) ─────────
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSessionIndexes.remove(sIndex);
                } else {
                  _expandedSessionIndexes.add(sIndex);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorConst.themeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.work_history_rounded,
                      size: 16,
                      color: ColorConst.themeColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Session ${session.sessionIndex}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontFamily: fontInterSemiBoldString,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              session.timeRangeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ColorConst.themeColor,
                                fontFamily: fontInterSemiBoldString,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _miniChip(
                              context,
                              isDark,
                              Icons.pin_drop_outlined,
                              '${session.stopsCount} ${session.stopsCount == 1 ? 'stop' : 'stops'}',
                            ),
                            if (session.totalDistanceKm > 0)
                              _miniChip(
                                context,
                                isDark,
                                Icons.directions_car_outlined,
                                '${session.totalDistanceKm.toStringAsFixed(1)} km',
                              ),
                            _miniChip(
                              context,
                              isDark,
                              Icons.schedule_outlined,
                              session.durationLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Direct Inner Timeline Data (Unboxed - shown directly below header) ──
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: innerStepWidgets,
            ),
          ),
      ],
    );
  }

  // ── Vertical Travel Distance Badge ──
  Widget _buildTravelBadge(
    BuildContext context, {
    required String distanceText,
    required String durationText,
    required bool isDark,
  }) {
    final String label = distanceText.isNotEmpty ? distanceText : 'Travel';

    return RotatedBox(
      quarterTurns: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 1.5,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: ColorConst.themeColor.withOpacity(0.45),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: ColorConst.themeColor,
            fontFamily: fontInterSemiBoldString,
          ),
        ),
      ),
    );
  }

  // ── Event Timeline Item (Punch IN / Stop / Punch OUT) ──────────────────────
  Widget _buildEventItem(
    BuildContext context,
    TimelineEvent ev, {
    required int? stopIndex,
    required bool isFirst,
    required bool isLast,
    required bool isDark,
    Widget? topTravelConnector,
    required int globalIndex, // index in provider.events list
  }) {
    final bool isPunchIn = ev.type == TimelineEventType.punchIn;
    final bool isPunchOut = ev.type == TimelineEventType.punchOut;
    final bool isFocused = _focusedEventIndex == globalIndex;

    final Color primaryAccent = ColorConst.themeColor;
    final Color statusColor = isPunchIn
        ? const Color(0xFF10B981)
        : (isPunchOut ? const Color(0xFFEF4444) : primaryAccent);

    final IconData statusIcon = isPunchIn
        ? Icons.login_rounded
        : (isPunchOut ? Icons.logout_rounded : Icons.location_pin);

    final String displayTitle = isPunchIn
        ? 'Punch In'
        : (isPunchOut
            ? 'Punch Out'
            : (stopIndex != null ? 'Stop $stopIndex' : 'Stop'));

    final bool hasLocation = ev.latitude != 0 || ev.longitude != 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SmartTimelineBranchPainter(
                      isFirst: isFirst,
                      isLast: isLast,
                      lineColor: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    child: Icon(
                      statusIcon,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
              ),
              if (topTravelConnector != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: FractionalTranslation(
                    translation: const Offset(0, -0.5),
                    child: Center(
                      child: topTravelConnector,
                    ),
                  ),
                ),
            ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: hasLocation ? () => _focusOnEvent(ev, globalIndex) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isFocused
                      ? statusColor.withOpacity(isDark ? 0.15 : 0.07)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFocused
                        ? statusColor.withOpacity(0.6)
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                    width: isFocused ? 1.8 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isFocused
                          ? statusColor.withOpacity(0.18)
                          : Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                      blurRadius: isFocused ? 10 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            displayTitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              fontFamily: fontInterSemiBoldString,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ev.formattedTimeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontFamily: fontInterBoldString,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (ev.type == TimelineEventType.stay) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ev.durationText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryAccent,
                              ),
                            ),
                          ),
                        ],
                        // Map pin affordance — visible only when location exists
                        if (hasLocation) ...[
                          const SizedBox(width: 6),
                          Icon(
                            isFocused
                                ? Icons.location_on_rounded
                                : Icons.location_on_outlined,
                            size: 16,
                            color: isFocused
                                ? statusColor
                                : (isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400),
                          ),
                        ],
                      ],
                    ),
                    if (ev.address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ev.address,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                                fontFamily: fontInterRegularString,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _miniChip(
    BuildContext context,
    bool isDark,
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              fontFamily: fontInterMediumString,
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable header icon button ────────────────────────────────────────────
  Widget _headerBtn(IconData icon, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );

  Widget _summaryTile(IconData icon, Color color, String value, String label) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: ColorConst.black,
              fontFamily: fontInterSemiBoldString,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: ColorConst.textgrey,
              fontFamily: fontInterRegularString,
            ),
          ),
        ],
      );

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.shade200);
}

// ─────────────────────────────────────────────────────────────────────────────
// Session grouping models & helpers
// ─────────────────────────────────────────────────────────────────────────────
class _TimelineSession {
  final int sessionIndex;
  final TimelineEvent punchInEvent;
  final List<TimelineEvent> innerStops;
  final TimelineEvent? punchOutEvent;

  _TimelineSession({
    required this.sessionIndex,
    required this.punchInEvent,
    required this.innerStops,
    this.punchOutEvent,
  });

  int get stopsCount => innerStops.length;

  double get totalDistanceKm {
    double total = punchInEvent.distanceFromPrevKm;
    for (var ev in innerStops) {
      total += ev.distanceFromPrevKm;
    }
    if (punchOutEvent != null) {
      total += punchOutEvent!.distanceFromPrevKm;
    }
    return total;
  }

  String get timeRangeLabel {
    final startStr = DateFormat('hh:mm a').format(punchInEvent.startTime);
    if (punchOutEvent != null) {
      final endStr = DateFormat('hh:mm a').format(punchOutEvent!.startTime);
      return '$startStr - $endStr';
    } else {
      return '$startStr - Active';
    }
  }

  String get durationLabel {
    final endTime = punchOutEvent?.startTime ?? DateTime.now();
    final diff = endTime.difference(punchInEvent.startTime);
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }
}

List<_TimelineSession> _groupEventsIntoSessions(List<TimelineEvent> events) {
  List<_TimelineSession> sessions = [];
  TimelineEvent? currentPunchIn;
  List<TimelineEvent> currentStops = [];

  for (var ev in events) {
    if (ev.type == TimelineEventType.punchIn) {
      if (currentPunchIn != null) {
        sessions.add(_TimelineSession(
          sessionIndex: sessions.length + 1,
          punchInEvent: currentPunchIn,
          innerStops: List.from(currentStops),
          punchOutEvent: null,
        ));
        currentStops.clear();
      }
      currentPunchIn = ev;
    } else if (ev.type == TimelineEventType.punchOut) {
      if (currentPunchIn != null) {
        sessions.add(_TimelineSession(
          sessionIndex: sessions.length + 1,
          punchInEvent: currentPunchIn,
          innerStops: List.from(currentStops),
          punchOutEvent: ev,
        ));
        currentPunchIn = null;
        currentStops.clear();
      } else {
        sessions.add(_TimelineSession(
          sessionIndex: sessions.length + 1,
          punchInEvent: ev,
          innerStops: [],
          punchOutEvent: ev,
        ));
      }
    } else {
      if (currentPunchIn != null) {
        currentStops.add(ev);
      } else {
        sessions.add(_TimelineSession(
          sessionIndex: sessions.length + 1,
          punchInEvent: ev,
          innerStops: [],
          punchOutEvent: null,
        ));
      }
    }
  }

  if (currentPunchIn != null) {
    sessions.add(_TimelineSession(
      sessionIndex: sessions.length + 1,
      punchInEvent: currentPunchIn,
      innerStops: List.from(currentStops),
      punchOutEvent: null,
    ));
  }

  return sessions;
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick config constants display for debugging (kStayRadiusMeters etc)
// ─────────────────────────────────────────────────────────────────────────────
String get smartTimelineConfigDebug =>
    'StayRadius=${kStayRadiusMeters}m | MinStay=${kMinStayMinutes}min | MaxAccuracy=${kMaxAccuracyMeters}m';

String _formatTravelDuration(DateTime start, DateTime end) {
  final diff = end.difference(start);
  if (diff.inSeconds <= 0) return '';
  final mins = diff.inMinutes;
  if (mins <= 0) return '';
  if (mins < 60) return '$mins min';
  final h = mins ~/ 60;
  final m = mins % 60;
  return m > 0 ? '$h hr $m min' : '$h hr';
}

class _SmartTimelineBranchPainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color lineColor;

  _SmartTimelineBranchPainter({
    required this.isFirst,
    required this.isLast,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double mainX = 18.0;
    final double nodeY = size.height / 2;

    if (!isFirst) {
      canvas.drawLine(Offset(mainX, 0), Offset(mainX, nodeY), linePaint);
    }
    if (!isLast) {
      canvas.drawLine(Offset(mainX, nodeY), Offset(mainX, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmartTimelineBranchPainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.lineColor != lineColor;
  }
}

class _TravelDashedLinePainter extends CustomPainter {
  final Color lineColor;

  _TravelDashedLinePainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double x = 18.0;
    double startY = 0;
    final double dashWidth = 4;
    final double dashSpace = 3;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, (startY + dashWidth).clamp(0, size.height)),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TravelDashedLinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
