import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetmend_mobile/main.dart';
import 'package:streetmend_mobile/reports/report.dart';
import 'package:streetmend_mobile/reports/my_reports_page.dart';
import 'package:streetmend_mobile/reports/report_details_page.dart';
import 'package:streetmend_mobile/reports/report_widgets.dart';

void main() {
  test('Search matches titles, locations and IDs and combines with status', () {
    expect(
      filterReports(sampleReports, '  STREETLIGHT ', null).single.id,
      'SM-1001',
    );
    expect(filterReports(sampleReports, 'teknokrat', null).length, 2);
    expect(
      filterReports(sampleReports, 'sm-1003', null).single.status,
      ReportStatus.resolved,
    );
    expect(
      filterReports(sampleReports, 'teknokrat', ReportStatus.pending).single.id,
      'SM-1004',
    );
    expect(
      filterReports(sampleReports, 'streetlight', ReportStatus.resolved),
      isEmpty,
    );
    for (final status in ReportStatus.values) {
      expect(
        filterReports(
          sampleReports,
          '',
          status,
        ).every((r) => r.status == status),
        isTrue,
      );
    }
  });

  testWidgets('Splash opens Welcome and Get Started opens Home', (
    tester,
  ) async {
    await tester.pumpWidget(const StreetMendApp());
    expect(find.byType(StreetMendSplashPage), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(StreetMendWelcomePage), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Dihan!'), findsOneWidget);
  });

  testWidgets('Reports search, filter, details and tab state work together', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StreetMendHomePage()));
    await tester.tap(
      find.descendant(
        of: find.byType(StreetMendTabBar),
        matching: find.text('Reports'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My Reports'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'teknokrat');
    await tester.tap(find.widgetWithText(ChoiceChip, 'In Progress'));
    await tester.pumpAndSettle();
    expect(find.text('1 report shown'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ReportCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(ReportDetailsPage), findsOneWidget);
    expect(find.text('SM-1001'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'teknokrat',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(StreetMendTabBar),
        matching: find.text('Home'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(StreetMendTabBar),
        matching: find.text('Reports'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 report shown'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'nothing matches');
    await tester.pumpAndSettle();
    expect(find.text('No matching reports'), findsOneWidget);
    await tester.ensureVisible(find.text('Reset filters'));
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    expect(find.text('4 reports shown'), findsOneWidget);
  });

  testWidgets('Home report shortcuts open list and matching details', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StreetMendHomePage()));
    await tester.tap(find.byType(CurrentReportCard));
    await tester.pumpAndSettle();
    expect(find.text('SM-1001'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final shortcut = find.descendant(
      of: find.byType(ExploreGrid),
      matching: find.text('Reports'),
    );
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pumpAndSettle();
    expect(find.text('My Reports'), findsOneWidget);
  });

  testWidgets('Empty collection has a helpful message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MyReportsPage(reports: [])),
      ),
    );
    expect(find.text('No reports yet'), findsOneWidget);
    expect(find.text('Reset filters'), findsNothing);
  });

  testWidgets('Reports and details fit small screens with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget app(Widget page) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.8)),
        child: child!,
      ),
      home: page,
    );
    await tester.pumpWidget(app(const Scaffold(body: MyReportsPage())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(ReportDetailsPage(report: sampleReports.last)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Issue resolved'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Awaiting a future update.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
