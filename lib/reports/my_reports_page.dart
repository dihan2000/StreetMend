import 'package:flutter/material.dart';

import '../brand.dart';
import 'report.dart';
import 'report_details_page.dart';
import 'report_widgets.dart';

/// Kept alive by the dashboard's IndexedStack when switching tabs.
class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key, this.reports});
  final List<Report>? reports;

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  final _search = TextEditingController();
  ReportStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reports = widget.reports ?? sampleReports;
    final visible = filterReports(reports, _search.text, _status);
    return ColoredBox(
      color: appColors(context).background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR NEIGHBOURHOOD, IMPROVED',
                      style: TextStyle(
                        color: appColors(context).ink,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'My Reports',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: appColors(context).ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Small actions. Better streets.',
                      style: TextStyle(color: appColors(context).body),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: appColors(context).heroGradient,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${reports.length} reports submitted',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sample reports • Preview your community impact',
                            style: TextStyle(color: kWarmGold, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search title, location or ID',
                        prefixIcon: Icon(
                          Icons.search,
                          color: appColors(context).ink,
                        ),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(_search.clear),
                              ),
                        filled: true,
                        fillColor: appColors(context).surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: appColors(context).soft,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final status in <ReportStatus?>[
                          null,
                          ...ReportStatus.values,
                        ])
                          ChoiceChip(
                            label: Text(status?.label ?? 'All'),
                            selected: _status == status,
                            selectedColor: appColors(context).soft,
                            onSelected: (_) => setState(() => _status = status),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${visible.length} ${visible.length == 1 ? 'report' : 'reports'} shown',
                      style: TextStyle(
                        color: appColors(context).ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (visible.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: appColors(context).accent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        reports.isEmpty
                            ? 'No reports yet'
                            : 'No matching reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: appColors(context).ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reports.isEmpty
                            ? 'Your submitted reports will appear here.'
                            : 'Try another search or reset your filters.',
                        textAlign: TextAlign.center,
                      ),
                      if (reports.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() {
                            _search.clear();
                            _status = null;
                          }),
                          child: const Text('Reset filters'),
                        ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) => ReportCard(
                    report: visible[index],
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ReportDetailsPage(report: visible[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
