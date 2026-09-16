// ignore_for_file: avoid_print

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tax_hrm/models/company/timelines.dart';
import 'package:tax_hrm/models/timeline_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ⚙️  CONFIGURABLE CONSTANTS — tune these without touching any other file
// ─────────────────────────────────────────────────────────────────────────────

/// Radius in meters within which consecutive GPS points are treated as the
/// SAME location during stay-detection. Increase to merge wider clusters.
const double kStayRadiusMeters = 40.0;

/// Minimum duration (minutes) a user must remain within [kStayRadiusMeters]
/// to be considered a meaningful "stay/stop" event.
const int kMinStayMinutes = 5;

/// Reject GPS points with accuracy worse than this value (meters).
const double kMaxAccuracyMeters = 80.0;

/// Skip consecutive points that are less than this far apart — eliminates
/// GPS drift while stationary so distance is not over-counted.
const double kGpsDriftSkipMeters = 10.0;

/// Reject a GPS point if it implies movement of more than this many km
/// in less than [kImpossibleJumpSeconds] seconds (impossible jump filter).
const double kImpossibleJumpKm = 150.0;
const int kImpossibleJumpSeconds = 30;

// ─────────────────────────────────────────────────────────────────────────────
// Internal helper: a validated GPS point with its parsed timestamp
// ─────────────────────────────────────────────────────────────────────────────
class _GpsPoint {
  final DateTime time;
  final double lat;
  final double lng;

  const _GpsPoint({required this.time, required this.lat, required this.lng});
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. LocationPointFilter — Removes bad & impossible GPS readings
// ─────────────────────────────────────────────────────────────────────────────
class LocationPointFilter {
  /// Takes raw [LocationTimelInes] records (from API), validates and sorts them.
  /// Returns a clean, chronologically ordered list of [_GpsPoint].
  static List<_GpsPoint> _filter(List<LocationTimelInes> rawPoints) {
    final List<_GpsPoint> result = [];

    for (final p in rawPoints) {
      // Parse coordinates
      final lat = double.tryParse(p.latitude ?? '');
      final lng = double.tryParse(p.logitude ?? '');
      if (lat == null || lng == null) continue;
      if (lat == 0.0 && lng == 0.0) continue;

      // Parse timestamp
      final time = DateTime.tryParse(p.entryTime ?? '');
      if (time == null) continue;

      result.add(_GpsPoint(time: time, lat: lat, lng: lng));
    }

    // Sort chronologically
    result.sort((a, b) => a.time.compareTo(b.time));

    // Remove impossible jumps (teleport detection)
    final List<_GpsPoint> validated = [];
    for (int i = 0; i < result.length; i++) {
      if (i == 0) {
        validated.add(result[i]);
        continue;
      }
      final prev = validated.last;
      final curr = result[i];
      final secs = curr.time.difference(prev.time).inSeconds.abs();
      if (secs > 0 && secs <= kImpossibleJumpSeconds) {
        final distM = Geolocator.distanceBetween(
          prev.lat,
          prev.lng,
          curr.lat,
          curr.lng,
        );
        final distKm = distM / 1000;
        if (distKm > kImpossibleJumpKm) {
          print(
            '[SMART_TIMELINE] ⚡ Rejected impossible jump: ${distKm.toStringAsFixed(1)}km in ${secs}s',
          );
          continue;
        }
      }
      validated.add(curr);
    }

    print(
      '[SMART_TIMELINE] LocationPointFilter: ${rawPoints.length} raw → ${validated.length} valid points',
    );
    return validated;
  }

  // Public wrapper that returns LatLng list for external consumers
  static List<LatLng> filterToLatLng(List<LocationTimelInes> rawPoints) =>
      _filter(rawPoints).map((p) => LatLng(p.lat, p.lng)).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. StayDetector — Groups stationary clusters into meaningful stop events
// ─────────────────────────────────────────────────────────────────────────────
class _StayCluster {
  final DateTime arrivalTime;
  final DateTime departureTime;
  final double lat;
  final double lng;

  /// Indices into the point array covered by this cluster (for route splitting)
  final int startIndex;
  final int endIndex;

  const _StayCluster({
    required this.arrivalTime,
    required this.departureTime,
    required this.lat,
    required this.lng,
    required this.startIndex,
    required this.endIndex,
  });

  int get durationMinutes => departureTime.difference(arrivalTime).inMinutes;
}

class StayDetector {
  /// Runs sliding-window stay detection on a sorted, filtered point list.
  /// Returns a list of detected stop clusters that meet the minimum duration.
  static List<_StayCluster> _detect(List<_GpsPoint> points) {
    final List<_StayCluster> stays = [];
    int i = 0;

    while (i < points.length) {
      // Anchor point for this potential cluster
      final anchor = points[i];
      int j = i + 1;

      // Expand window while points remain within kStayRadiusMeters of anchor
      while (j < points.length) {
        final dist = Geolocator.distanceBetween(
          anchor.lat,
          anchor.lng,
          points[j].lat,
          points[j].lng,
        );
        if (dist > kStayRadiusMeters) break;
        j++;
      }

      // j is now the first point OUTSIDE the radius
      final clusterPoints = points.sublist(i, j);
      if (clusterPoints.length >= 2) {
        // The time they left is approximately the time of the first point OUTSIDE the radius
        final departureTime = j < points.length
            ? points[j].time
            : clusterPoints.last.time;
        final duration = departureTime
            .difference(clusterPoints.first.time)
            .inMinutes;

        if (duration >= kMinStayMinutes) {
          // Compute centroid of all points in cluster
          final centLat =
              clusterPoints.map((p) => p.lat).reduce((a, b) => a + b) /
              clusterPoints.length;
          final centLng =
              clusterPoints.map((p) => p.lng).reduce((a, b) => a + b) /
              clusterPoints.length;

          stays.add(
            _StayCluster(
              arrivalTime: clusterPoints.first.time,
              departureTime: departureTime,
              lat: centLat,
              lng: centLng,
              startIndex: i,
              endIndex: j - 1,
            ),
          );
          print(
            '[SMART_TIMELINE] 🛑 Stay detected: ${clusterPoints.first.time} – ${clusterPoints.last.time} ($duration min) @ ($centLat, $centLng)',
          );
          i = j; // Skip past this entire cluster
          continue;
        }
      }
      i++;
    }

    print('[SMART_TIMELINE] StayDetector: ${stays.length} stop(s) found');
    return stays;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. DistanceCalculator — Sequential travelled distance (not straight-line)
// ─────────────────────────────────────────────────────────────────────────────
class DistanceCalculator {
  /// Calculates the total sequential travelled distance (km) across [points].
  /// Skips micro-movements < [kGpsDriftSkipMeters] to avoid drift inflation.
  static double _totalKm(List<_GpsPoint> points) {
    double totalM = 0;
    for (int i = 1; i < points.length; i++) {
      final d = Geolocator.distanceBetween(
        points[i - 1].lat,
        points[i - 1].lng,
        points[i].lat,
        points[i].lng,
      );
      if (d >= kGpsDriftSkipMeters) totalM += d;
    }
    return totalM / 1000;
  }

  /// Calculates distance (km) between two points in the list [from] index to [to] index (inclusive).
  static double _segmentKm(List<_GpsPoint> points, int from, int to) {
    if (from >= to || from < 0 || to >= points.length) return 0;
    return _totalKm(points.sublist(from, to + 1));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. AddressResolver — Reverse geocodes only important points, with cache
// ─────────────────────────────────────────────────────────────────────────────
class AddressResolver {
  /// Cache keyed by "lat,lng" rounded to 4 decimal places.
  /// Capped at 200 entries to prevent unbounded memory growth when the user
  /// browses many different dates in a single session.
  static final Map<String, String> _cache = {};
  static const int _kMaxCacheSize = 200;

  static String _cacheKey(double lat, double lng) =>
      '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  /// Resolves address for a single coordinate. Returns cached value instantly
  /// if a nearby address was already resolved in this session.
  static Future<String> resolve(double lat, double lng) async {
    final key = _cacheKey(lat, lng);
    if (_cache.containsKey(key)) return _cache[key]!;

    // Evict oldest entries if cache is full
    if (_cache.length >= _kMaxCacheSize) {
      final oldest = _cache.keys.take(_cache.length - _kMaxCacheSize + 1).toList();
      for (final k in oldest) {
        _cache.remove(k);
      }
    }

    try {
      final placemarks = await Geocoding()
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 6));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
          if ((p.locality ?? '').isNotEmpty) p.locality!,
          if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
        ];
        final address = parts.isNotEmpty
            ? parts.join(', ')
            : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        _cache[key] = address;
        return address;
      }
    } catch (e) {
      print('[SMART_TIMELINE] ⚠️ Geocoding failed for ($lat, $lng): $e');
    }
    final fallback = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    _cache[key] = fallback;
    return fallback;
  }

  /// Clears the session cache (call on date change or screen dispose).
  static void clearCache() => _cache.clear();
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. LocationTimelineProcessor — Orchestrates the full pipeline
// ─────────────────────────────────────────────────────────────────────────────
class ProcessedTimeline {
  final List<TimelineEvent> events;
  final List<List<LatLng>> routeSegments; // disjoint polyline segments
  final double totalDistanceKm;
  final int totalWorkingMinutes;
  final int stopsCount;
  final bool isCurrentlyWorkedIn; // true when no Punch Out yet

  const ProcessedTimeline({
    required this.events,
    required this.routeSegments,
    required this.totalDistanceKm,
    required this.totalWorkingMinutes,
    required this.stopsCount,
    required this.isCurrentlyWorkedIn,
  });

  static ProcessedTimeline empty() => const ProcessedTimeline(
    events: [],
    routeSegments: [],
    totalDistanceKm: 0,
    totalWorkingMinutes: 0,
    stopsCount: 0,
    isCurrentlyWorkedIn: false,
  );
}

class LocationTimelineProcessor {
  static Future<ProcessedTimeline> process({
    required List<LocationTimelInes> rawGpsPoints,
    required DateTime punchInTime,
    DateTime? punchOutTime,
    double? punchInLat,
    double? punchInLng,
    double? punchOutLat,
    double? punchOutLng,
  }) async {
    final isCurrentlyWorkedIn = punchOutTime == null;
    final boundary = punchOutTime ?? DateTime.now();

    print(
      '[SMART_TIMELINE] 🚀 Processing ${rawGpsPoints.length} raw points | IN: $punchInTime | OUT: $punchOutTime',
    );

    final allFiltered = LocationPointFilter._filter(rawGpsPoints);

    final windowed = allFiltered.where((p) {
      return !p.time.isBefore(punchInTime) && !p.time.isAfter(boundary);
    }).toList();

    print(
      '[SMART_TIMELINE] Window filtered: ${windowed.length} points between IN and OUT',
    );

    final stays = StayDetector._detect(windowed);
    final List<LatLng> routePoints = [];
    int wIndex = 0;
    for (final stay in stays) {
      for (; wIndex < stay.startIndex; wIndex++) {
        routePoints.add(LatLng(windowed[wIndex].lat, windowed[wIndex].lng));
      }
      routePoints.add(LatLng(stay.lat, stay.lng));
      wIndex = stay.endIndex + 1;
    }
    for (; wIndex < windowed.length; wIndex++) {
      routePoints.add(LatLng(windowed[wIndex].lat, windowed[wIndex].lng));
    }
    final totalDistanceKm = DistanceCalculator._totalKm(windowed);
    print(
      '[SMART_TIMELINE] 📏 Total distance: ${totalDistanceKm.toStringAsFixed(2)} km',
    );

    final List<TimelineEvent> events = [];

    final piLat =
        punchInLat ?? (windowed.isNotEmpty ? windowed.first.lat : 0.0);
    final piLng =
        punchInLng ?? (windowed.isNotEmpty ? windowed.first.lng : 0.0);

    if (piLat != 0.0 && piLng != 0.0) {
      routePoints.insert(0, LatLng(piLat, piLng));
    }

    events.add(
      TimelineEvent(
        type: TimelineEventType.punchIn,
        startTime: punchInTime,
        latitude: piLat,
        longitude: piLng,
        distanceFromPrevKm: 0,
        totalDistanceKm: 0,
      ),
    );

    int prevPointIndex = 0;
    double runningDistKm = 0;

    for (final stay in stays) {
      final segDist = DistanceCalculator._segmentKm(
        windowed,
        prevPointIndex,
        stay.startIndex,
      );
      runningDistKm += segDist;
      events.add(
        TimelineEvent(
          type: TimelineEventType.stay,
          startTime: stay.arrivalTime,
          endTime: stay.departureTime,
          latitude: stay.lat,
          longitude: stay.lng,
          durationMinutes: stay.durationMinutes,
          distanceFromPrevKm: segDist,
          totalDistanceKm: runningDistKm,
        ),
      );
      prevPointIndex = stay.endIndex;
    }

    if (!isCurrentlyWorkedIn) {
      final poLat =
          punchOutLat ?? (windowed.isNotEmpty ? windowed.last.lat : 0.0);
      final poLng =
          punchOutLng ?? (windowed.isNotEmpty ? windowed.last.lng : 0.0);

      if (poLat != 0.0 && poLng != 0.0) {
        routePoints.add(LatLng(poLat, poLng));
      }

      final lastSegDist = DistanceCalculator._segmentKm(
        windowed,
        prevPointIndex,
        windowed.length - 1,
      );
      runningDistKm += lastSegDist;
      events.add(
        TimelineEvent(
          type: TimelineEventType.punchOut,
          startTime: punchOutTime,
          latitude: poLat,
          longitude: poLng,
          distanceFromPrevKm: lastSegDist,
          totalDistanceKm: runningDistKm,
        ),
      );
    }

    for (final event in events) {
      if (event.latitude != 0.0 && event.longitude != 0.0) {
        event.address = await AddressResolver.resolve(
          event.latitude,
          event.longitude,
        );
      }
    }

    final workingMinutes = boundary.difference(punchInTime).inMinutes;

    print(
      '[SMART_TIMELINE] ✅ Done: ${events.length} events | ${stays.length} stops | ${totalDistanceKm.toStringAsFixed(2)} km',
    );

    return ProcessedTimeline(
      events: events,
      routeSegments: [routePoints],
      totalDistanceKm: totalDistanceKm,
      totalWorkingMinutes: workingMinutes,
      stopsCount: stays.length,
      isCurrentlyWorkedIn: isCurrentlyWorkedIn,
    );
  }
}
