import 'package:flutter/material.dart';

import '../brand.dart';
import 'report.dart';
import 'report_widgets.dart';

class ReportDetailsPage extends StatelessWidget {
  const ReportDetailsPage({super.key, required this.report});
  final Report report;

  @override
  Widget build(BuildContext context) {
    final completedStage = report.status.index;
    return Scaffold(
      backgroundColor: appColors(context).background,
      appBar: AppBar(title: const Text('Report Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: appColors(context).panel,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(reportIcon(report), size: 48, color: kWarmGold),
                  const SizedBox(height: 18),
                  Text(report.id, style: const TextStyle(color: kMistBlue)),
                  const SizedBox(height: 8),
                  Text(
                    report.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatusBadge(status: report.status),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section(context, 'Location', report.location),
            _section(context, 'Category', report.category),
            _section(context, 'Submitted', report.formattedDate),
            _section(context, 'Description', report.description),
            if (report.imageAsset != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(report.imageAsset!),
              ),
            Text(
              'Report progress',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: appColors(context).ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sample timeline • These are demonstration updates.',
              style: TextStyle(color: appColors(context).body),
            ),
            const SizedBox(height: 20),
            for (var stage = 0; stage < 3; stage++)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      stage <= completedStage
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: stage <= completedStage
                          ? appColors(context).accent
                          : appColors(context).muted,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              'Report submitted',
                              'Work in progress',
                              'Issue resolved',
                            ][stage],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: appColors(context).ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stage <= completedStage
                                ? [
                                    '${report.formattedDate} — Report received and awaiting review.',
                                    'The maintenance team is working on the reported issue.',
                                    'Maintenance is complete and the report is closed.',
                                  ][stage]
                                : 'Awaiting a future update.',
                            style: TextStyle(
                              color: appColors(context).body,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: appColors(context).ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: appColors(context).body,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
