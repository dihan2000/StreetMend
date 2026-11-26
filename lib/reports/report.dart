/// The three stages used by our local demonstration reports.
enum ReportStatus {
  pending('Pending'),
  inProgress('In Progress'),
  resolved('Resolved');

  const ReportStatus(this.label);
  final String label;
}

/// A report is data, separate from the widgets that display it.
class Report {
  const Report({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.date,
    required this.description,
    required this.status,
    this.imageAsset,
  });

  final String id;
  final String title;
  final String category;
  final String location;
  final DateTime date;
  final String description;
  final ReportStatus status;
  final String? imageAsset;

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// Sample data only: nothing is sent to a server or saved to an account.
final sampleReports = List<Report>.unmodifiable([
  Report(
    id: 'SM-1001',
    title: 'Broken Streetlight',
    category: 'Streetlight',
    location: 'Jalan Teknokrat',
    date: DateTime(2026, 10, 18),
    description: 'The streetlight near the pedestrian crossing is not working, making the walkway difficult to see at night.',
    status: ReportStatus.inProgress,
  ),
  Report(
    id: 'SM-1002',
    title: 'Pothole Near Bus Stop',
    category: 'Road damage',
    location: 'Persiaran Multimedia',
    date: DateTime(2026, 10, 20),
    description: 'A deep pothole has formed beside the bus stop. Rainwater collects here and vehicles swerve to avoid it.',
    status: ReportStatus.pending,
  ),
  Report(
    id: 'SM-1003',
    title: 'Blocked Roadside Drain',
    category: 'Drainage',
    location: 'Jalan Cyber Point',
    date: DateTime(2026, 10, 15),
    description: 'Leaves and litter were blocking the roadside drain. The sample maintenance update records that the blockage has been cleared.',
    status: ReportStatus.resolved,
  ),
  Report(
    id: 'SM-1004',
    title: 'Damaged Pedestrian Sign',
    category: 'Road sign',
    location: 'Jalan Teknokrat',
    date: DateTime(2026, 10, 21),
    description: 'The pedestrian crossing sign is bent and faces away from approaching drivers.',
    status: ReportStatus.pending,
  ),
]);

/// Search and status filtering are combined, so both controls work together.
List<Report> filterReports(
  List<Report> reports,
  String query,
  ReportStatus? status,
) {
  final search = query.trim().toLowerCase();
  return reports
      .where(
        (report) =>
            (status == null || report.status == status) &&
            '${report.title} ${report.location} ${report.id}'
                .toLowerCase()
                .contains(search),
      )
      .toList();
}
