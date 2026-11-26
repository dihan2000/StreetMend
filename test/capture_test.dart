import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:streetmend_mobile/capture/widgets/issue_map.dart';
import 'package:streetmend_mobile/capture/capture_page.dart';
import 'package:streetmend_mobile/capture/location_picker_page.dart';
import 'package:streetmend_mobile/capture/report_draft.dart';
import 'package:streetmend_mobile/capture/review_report_page.dart';
import 'package:streetmend_mobile/capture/services/location_service.dart';
import 'package:streetmend_mobile/capture/services/photo_service.dart';
import 'package:streetmend_mobile/main.dart';

final photo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGMQXjvpPwAEewJSRPuekAAAAABJRU5ErkJggg==',
);

class MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(photo);
}

class FakePhotos extends PhotoService {
  bool cancel = false;
  bool fail = false;
  bool? camera;
  @override
  Future<Uint8List?> pick({required bool camera}) async {
    this.camera = camera;
    if (fail) throw const FormatException('Unsupported photo.');
    return cancel ? null : photo;
  }
}

class FakeLocation extends LocationService {
  int calls = 0;
  Future<DevicePosition> Function()? response;
  @override
  Future<DevicePosition> current() {
    calls++;
    return response?.call() ??
        Future.error(const LocationFailure('GPS denied. Choose manually.'));
  }
}

Widget map(LatLng center, ValueChanged<LatLng> moved) => SizedBox(
  height: 150,
  child: Center(
    child: TextButton(
      onPressed: () => moved(const LatLng(3.123456789, 101.654321987)),
      child: const Text('Move test pin'),
    ),
  ),
);
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Manual coordinates are explicitly confirmed and used by Review',
    (tester) async {
      IssueLocation? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open location'),
                onPressed: () async {
                  confirmed = await Navigator.of(context).push<IssueLocation>(
                    MaterialPageRoute(
                      builder: (_) => const LocationPickerPage(mapBuilder: map),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open location'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Latitude'),
        '-33.9',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Longitude'),
        '151.2',
      );
      expect(confirmed, isNull);
      await tapVisible(tester, find.text('Use Entered Coordinates'));
      expect(confirmed, isNull);
      await tapVisible(tester, find.text('Confirm This Location'));
      expect(confirmed!.latitude, -33.9);
      expect(confirmed!.longitude, 151.2);
      expect(confirmed!.method, 'manual_coordinates');
      expect(confirmed!.accuracyMeters, isNull);
      final draft = ReportDraft()
        ..photo = photo
        ..category = IssueCategory.other
        ..customTitle = 'Broken railing'
        ..description = 'Unsafe railing'
        ..location = confirmed;
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewReportPage(
            draft: draft,
            mapPreview: const SizedBox(height: 10),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Broken railing'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Manual coordinates, confirmed by you'),
        150,
      );
      expect(find.text('-33.900000'), findsOneWidget);
      expect(find.text('151.200000'), findsOneWidget);
    },
  );

  test(
    'Other Issue rejects blank titles; landmark notes cannot confirm location',
    () {
      final draft = ReportDraft()
        ..photo = photo
        ..category = IssueCategory.other
        ..description = 'A broken railing'
        ..landmark = 'dPulze mall';
      expect(draft.issueComplete, isFalse);
      draft.customTitle = '   ';
      expect(draft.issueComplete, isFalse);
      draft.customTitle = 'Damaged railing';
      expect(draft.issueComplete, isTrue);
      expect(draft.readyForReview, isFalse);
      expect(draft.location, isNull);
    },
  );

  testWidgets(
    'Existing map updates to changed coordinates, including Review reuse',
    (tester) async {
      final controller = MapController();
      addTearDown(controller.dispose);
      Widget app(LatLng point) => MaterialApp(
        home: Scaffold(
          body: IssueMap(
            center: point,
            controller: controller,
            tileProvider: MemoryTiles(),
          ),
        ),
      );
      await tester.pumpWidget(app(const LatLng(3.132282, 101.673444)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(const LatLng(-33.9, 151.2)));
      await tester.pumpAndSettle();
      expect(controller.camera.center.latitude, closeTo(-33.9, 0.0000001));
      expect(controller.camera.center.longitude, closeTo(151.2, 0.0000001));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'GPS and map selection synchronize coordinate fields and accuracy',
    (tester) async {
      final gps = FakeLocation()
        ..response = () async => const DevicePosition(4.5, 102.5, 90);
      await tester.pumpWidget(
        MaterialApp(
          home: LocationPickerPage(service: gps, mapBuilder: map),
        ),
      );
      await tapVisible(tester, find.text('Use My Current Location'));
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Latitude'))
            .controller!
            .text,
        '4.5',
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Longitude'))
            .controller!
            .text,
        '102.5',
      );
      await tapVisible(tester, find.text('Move test pin'));
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Latitude'))
            .controller!
            .text,
        '3.123456789',
      );
      expect(find.textContaining('Source: Map selection'), findsOneWidget);
      expect(find.textContaining('Device-reported accuracy'), findsNothing);
    },
  );

  testWidgets('Real map responds to manual pan on iPhone-sized layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LatLng? moved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IssueMap(
            center: const LatLng(3.1, 101.1),
            tileProvider: MemoryTiles(),
            onMoved: (point) => moved = point,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(FlutterMap), const Offset(70, 30));
    await tester.pumpAndSettle();
    expect(moved, isNotNull);
    expect(moved!.longitude, isNot(101.1));
    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Draft requires photo, category, description and valid confirmed coordinates', () {
    final draft = ReportDraft();
    expect(draft.readyForReview, isFalse);
    draft.photo = photo;
    draft.category = IssueCategory.pothole;
    draft.description = '  ';
    expect(draft.issueComplete, isFalse);
    draft.description = 'Deep pothole near crossing';
    expect(draft.issueComplete, isTrue);
    expect(draft.readyForReview, isFalse);
    draft.location = IssueLocation(
      latitude: 3.123456789,
      longitude: 101.6,
      method: 'manual_map',
      confirmedAt: DateTime(2026),
    );
    expect(draft.readyForReview, isTrue);
    expect(draft.location!.latitude, 3.123456789);
    expect(IssueLocation.isValid(double.nan, 0), isFalse);
    expect(IssueLocation.isValid(0, double.infinity), isFalse);
    expect(IssueLocation.isValid(91, 181), isFalse);
    expect(IssueLocation.isValid(-90, -180), isTrue);
  });

  testWidgets('Capture tab opens and closing an empty draft returns Home', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StreetMendHomePage()));
    await tester.tap(find.text('Capture'));
    await tester.pumpAndSettle();
    expect(find.byType(CapturePage), findsOneWidget);
    await tester.tap(find.byTooltip('Close capture'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Dihan!'), findsOneWidget);
  });

  testWidgets('Required inputs, photo cancellation and failure', (
    tester,
  ) async {
    final photos = FakePhotos()..cancel = true;
    await tester.pumpWidget(
      MaterialApp(home: CapturePage(photoService: photos)),
    );
    await tapVisible(tester, find.text('Continue to Location'));
    expect(find.text('Please choose a category.'), findsOneWidget);
    expect(find.text('Please describe the issue.'), findsOneWidget);
    await tapVisible(tester, find.text('Choose Photo'));
    expect(find.text('Remove Photo'), findsNothing);
    photos.cancel = false;
    photos.fail = true;
    await tapVisible(tester, find.text('Take Photo'));
    expect(find.text('Unsupported photo.'), findsOneWidget);
    expect(photos.camera, isTrue);
  });

  testWidgets('GPS is on demand; denial permits manual selection', (
    tester,
  ) async {
    final gps = FakeLocation();
    await tester.pumpWidget(
      MaterialApp(
        home: LocationPickerPage(service: gps, mapBuilder: map),
      ),
    );
    expect(gps.calls, 0);
    await tapVisible(tester, find.text('Confirm This Location'));
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirm This Location'),
          )
          .onPressed,
      isNull,
    );
    await tapVisible(tester, find.text('Use My Current Location'));
    expect(gps.calls, 1);
    expect(find.text('GPS denied. Choose manually.'), findsOneWidget);
    await tapVisible(tester, find.text('Move test pin'));
    await tester.enterText(find.widgetWithText(TextField, 'Latitude'), '91');
    await tapVisible(tester, find.text('Use Entered Coordinates'));
    expect(
      find.text(
        'Enter latitude from −90 to 90 and longitude from −180 to 180.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Late GPS response cannot overwrite manually selected coordinates',
    (tester) async {
      final pending = Completer<DevicePosition>();
      final gps = FakeLocation()..response = () => pending.future;
      await tester.pumpWidget(
        MaterialApp(
          home: LocationPickerPage(service: gps, mapBuilder: map),
        ),
      );
      await tester.tap(find.text('Use My Current Location'));
      await tester.pump();
      await tester.ensureVisible(find.text('Move test pin'));
      await tester.pump();
      await tester.tap(find.text('Move test pin'));
      await tester.pump();
      pending.complete(const DevicePosition(5, 100, 10));
      await tester.pumpAndSettle();
      expect(find.text('Selected: 3.123457, 101.654322'), findsOneWidget);
    },
  );

  testWidgets('Successful GPS remains a candidate until explicitly confirmed', (
    tester,
  ) async {
    final gps = FakeLocation()
      ..response = () async => const DevicePosition(4.5, 102.5, 90);
    await tester.pumpWidget(
      MaterialApp(
        home: LocationPickerPage(service: gps, mapBuilder: map),
      ),
    );
    await tester.tap(find.text('Use My Current Location'));
    await tester.pumpAndSettle();
    expect(find.text('Selected: 4.500000, 102.500000'), findsOneWidget);
    expect(
      find.textContaining('Device-reported accuracy: about 90 m'),
      findsOneWidget,
    );
    expect(find.byType(LocationPickerPage), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.ensureVisible(fields.first);
    await tester.enterText(fields.first, '-33.9');
    await tester.enterText(fields.last, '151.2');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirm This Location'),
          )
          .onPressed,
      isNull,
    );
    await tapVisible(tester, find.text('Use Entered Coordinates'));
    expect(find.text('Selected: -33.900000, 151.200000'), findsOneWidget);
  });

  testWidgets(
    'Full draft flow reviews exact manual coordinates and preserves edits',
    (tester) async {
      final photos = FakePhotos();
      await tester.pumpWidget(
        MaterialApp(
          home: CapturePage(
            photoService: photos,
            mapBuilder: map,
            reviewMap: const SizedBox(height: 100),
          ),
        ),
      );
      await tapVisible(tester, find.text('Choose Photo'));
      expect(photos.camera, isFalse);
      await tapVisible(
        tester,
        find.byType(DropdownButtonFormField<IssueCategory>),
      );
      await tester.tap(find.text('Other Issue (Specify)').last);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Continue to Location'));
      expect(find.text('Please specify the issue title.'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Custom issue title'),
        'Damaged pavement railing',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Location notes / nearby landmark (optional)',
        ),
        'dPulze mall, Cyberjaya',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Problem description'),
        'Deep pothole near the crossing.',
      );
      await tapVisible(tester, find.text('Continue to Location'));
      await tapVisible(tester, find.text('Move test pin'));
      await tapVisible(tester, find.text('Confirm This Location'));
      expect(find.byType(ReviewReportPage), findsOneWidget);
      await tester.scrollUntilVisible(find.text('101.654322'), 200);
      expect(find.text('3.123457'), findsOneWidget);
      final review = tester.widget<ReviewReportPage>(
        find.byType(ReviewReportPage),
      );
      expect(review.draft.location!.latitude, 3.123456789);
      expect(review.draft.customTitle, 'Damaged pavement railing');
      expect(review.draft.landmark, 'dPulze mall, Cyberjaya');
      expect(review.draft.location!.method, 'manual_map');

      await tester.scrollUntilVisible(
        find.text('Submit — Not Available Yet'),
        200,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Submit — Not Available Yet'),
            )
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.text('Back to Draft'));
      await tester.tap(find.byTooltip('Close capture'));
      await tester.pumpAndSettle();
      expect(find.text('Discard this draft?'), findsOneWidget);
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(find.byType(CapturePage), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.widgetWithText(TextFormField, 'Problem description'),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'Deep pothole near the crossing.',
      );
    },
  );

  testWidgets(
    'Capture, location and review fit a small iPhone with large text',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget app(Widget child) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: child,
      );
      final draft = ReportDraft()
        ..photo = photo
        ..category = IssueCategory.streetlight
        ..description = 'A damaged light.'
        ..location = IssueLocation(
          latitude: 3.1,
          longitude: 101.1,
          method: 'manual_map',
          confirmedAt: DateTime(2026),
        );
      for (final page in <Widget>[
        const CapturePage(),
        const LocationPickerPage(mapBuilder: map),
        ReviewReportPage(draft: draft, mapPreview: const SizedBox(height: 100)),
      ]) {
        await tester.pumpWidget(app(page));
        await tester.pumpAndSettle();
        for (var i = 0; i < 5; i++) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
