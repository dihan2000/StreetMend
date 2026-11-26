import 'package:flutter/material.dart';

import '../brand.dart';
import 'report.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReportStatus.pending => appColors(context).soft,
      ReportStatus.inProgress =>
        appColors(context).dark ? const Color(0xFF594622) : kWarmGold,
      ReportStatus.resolved =>
        appColors(context).dark
            ? const Color(0xFF164D43)
            : const Color(0xFFDDF4ED),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: appColors(context).ink,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

IconData reportIcon(Report report) => switch (report.category) {
  'Streetlight' => Icons.lightbulb_outline_rounded,
  'Drainage' => Icons.water_rounded,
  'Road sign' => Icons.signpost_outlined,
  _ => Icons.warning_amber_rounded,
};

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report, required this.onTap});
  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: appColors(context).surface,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: appColors(context).soft),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appColors(context).soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    reportIcon(report),
                    color: appColors(context).ink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.id,
                    style: TextStyle(
                      color: appColors(context).ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: appColors(context).accent,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              report.title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: appColors(context).ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              report.location,
              style: TextStyle(color: appColors(context).body),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(status: report.status),
                Text(
                  report.formattedDate,
                  style: TextStyle(
                    color: appColors(context).body,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
