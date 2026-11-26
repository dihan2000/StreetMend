import 'dart:typed_data';

enum IssueCategory {
  pothole('Pothole'),
  streetlight('Broken streetlight'),
  sign('Damaged road sign'),
  trafficLight('Faulty traffic light'),
  drain('Blocked drain'),
  other('Other Issue (Specify)');

  const IssueCategory(this.label);
  final String label;
}

/// A confirmed issue position, not necessarily the phone's position.
class IssueLocation {
  const IssueLocation({
    required this.latitude,
    required this.longitude,
    required this.method,
    required this.confirmedAt,
    this.accuracyMeters,
  });
  final double latitude;
  final double longitude;
  final String method;
  final DateTime confirmedAt;
  final double? accuracyMeters;

  String get sourceLabel => switch (method) {
    'gps' => 'Device location (GPS/browser)',
    'manual_coordinates' => 'Manual coordinates',
    'manual_map' => 'Map selection',
    _ => 'Unknown source',
  };

  static bool isValid(double? latitude, double? longitude) =>
      latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  String get coordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

/// Session-only data. Never inserted into the sample submitted reports.
class ReportDraft {
  Uint8List? photo;
  IssueCategory? category;
  String customTitle = '';
  String description = '';
  String landmark = '';
  IssueLocation? location;

  bool get hasChanges =>
      photo != null ||
      category != null ||
      customTitle.trim().isNotEmpty ||
      description.trim().isNotEmpty ||
      landmark.trim().isNotEmpty ||
      location != null;
  bool get issueComplete =>
      photo != null &&
      category != null &&
      (category != IssueCategory.other ||
          (customTitle.trim().isNotEmpty &&
              customTitle.trim().length <= 100)) &&
      description.trim().isNotEmpty &&
      description.trim().length <= 1000;
  bool get readyForReview =>
      issueComplete &&
      location != null &&
      IssueLocation.isValid(location!.latitude, location!.longitude);
}
