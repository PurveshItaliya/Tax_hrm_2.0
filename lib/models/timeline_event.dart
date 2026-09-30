// ignore_for_file: prefer_collection_literals

/// Represents the type of a processed timeline event.
enum TimelineEventType { punchIn, stay, punchOut }

/// A single processed event in the smart movement timeline.
/// Built from raw GPS records after filtering, stay-detection, and geocoding.
/// Raw location data is NEVER modified — this is purely a view-layer model.
class TimelineEvent {
  /// What type of event this is.
  final TimelineEventType type;

  /// When the event started (punch time or arrival at stop).
  final DateTime startTime;

  /// When the event ended (departure from stop). Null for punchIn/punchOut.
  final DateTime? endTime;

  /// Representative coordinate for this event (centroid of stay cluster, or punch coords).
  final double latitude;
  final double longitude;

  /// Human-readable address — resolved asynchronously via reverse geocoding.
  /// Starts as empty string; updated via [AddressResolver].
  String address;

  /// How many minutes the user stayed at this location. 0 for punchIn/punchOut.
  final int durationMinutes;

  /// Travelled distance (km) between this event and the previous one.
  /// Calculated using sequential filtered GPS points — not straight-line.
  final double distanceFromPrevKm;

  /// Cumulative total distance (km) from Punch In up to this event.
  final double totalDistanceKm;

  TimelineEvent({
    required this.type,
    required this.startTime,
    this.endTime,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.durationMinutes = 0,
    this.distanceFromPrevKm = 0.0,
    this.totalDistanceKm = 0.0,
  });

  /// Formatted label used in the timeline card title.
  String get typeLabel {
    switch (type) {
      case TimelineEventType.punchIn:
        return 'Punch In';
      case TimelineEventType.punchOut:
        return 'Punch Out';
      case TimelineEventType.stay:
        return 'Stop';
    }
  }

  /// Formatted time string, e.g. "09:30 AM" or "11:30 – 11:55 AM" for stays.
  String get formattedTimeLabel {
    String fmt(DateTime t) {
      final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
      final m = t.minute.toString().padLeft(2, '0');
      final ampm = t.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $ampm';
    }

    if (type == TimelineEventType.stay && endTime != null) {
      return '${fmt(startTime)} – ${fmt(endTime!)}';
    }
    return fmt(startTime);
  }

  /// Duration text, e.g. "25 min" or "1 hr 5 min".
  String get durationText {
    if (durationMinutes <= 0) return '';
    if (durationMinutes < 60) return '$durationMinutes min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m > 0 ? '$h hr $m min' : '$h hr';
  }

  /// Distance label to show between two consecutive events.
  String get distanceLabel {
    if (distanceFromPrevKm <= 0) return '';
    if (distanceFromPrevKm < 1.0) {
      return '${(distanceFromPrevKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceFromPrevKm.toStringAsFixed(1)} km';
  }
}
