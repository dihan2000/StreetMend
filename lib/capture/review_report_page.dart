import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../brand.dart';
import 'report_draft.dart';
import 'widgets/draft_photo.dart';
import 'widgets/issue_map.dart';

class ReviewReportPage extends StatelessWidget {
  const ReviewReportPage({super.key, required this.draft, this.mapPreview});
  final ReportDraft draft;
  final Widget? mapPreview;

  @override
  Widget build(BuildContext context) {
    final location = draft.location!;
    return Scaffold(
      backgroundColor: appColors(context).background,
      appBar: AppBar(title: const Text('Review Issue')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '3 of 3 • Check your draft',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: appColors(context).ink,
              ),
            ),
            const SizedBox(height: 18),
            DraftPhoto(bytes: draft.photo!),
            TextButton(
              onPressed: () => Navigator.pop(context, 'issue'),
              child: const Text('Edit Photo and Issue'),
            ),
            _section(context, 'Category', draft.category!.label),
            if (draft.category == IssueCategory.other)
              _section(context, 'Custom issue title', draft.customTitle.trim()),
            _section(context, 'Description', draft.description.trim()),
            mapPreview ??
                IssueMap(center: LatLng(location.latitude, location.longitude)),
            const SizedBox(height: 16),
            _section(
              context,
              'Confirmed latitude',
              location.latitude.toStringAsFixed(6),
            ),
            _section(
              context,
              'Confirmed longitude',
              location.longitude.toStringAsFixed(6),
            ),
            _section(
              context,
              'Location selected using',
              '${location.sourceLabel}, confirmed by you',
            ),
            if (location.method == 'gps' && location.accuracyMeters != null)
              _section(
                context,
                'Device-reported accuracy',
                'About ${location.accuracyMeters!.toStringAsFixed(0)} m; not a guarantee of exact positioning.',
              ),
            if (draft.landmark.trim().isNotEmpty)
              _section(
                context,
                'Location note (not verified)',
                draft.landmark.trim(),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'location'),
              child: const Text('Edit Location'),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: appColors(context).soft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Your report has not been submitted. Submission will be available when StreetMend’s backend is connected. This draft is kept only during this capture session and is lost when you discard it or restart the app.',
              ),
            ),
            const SizedBox(height: 16),
            const FilledButton(
              onPressed: null,
              child: Text('Submit — Not Available Yet'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Draft'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appColors(context).ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    ),
  );
}
