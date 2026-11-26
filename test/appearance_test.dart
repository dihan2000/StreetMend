import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetmend_mobile/brand.dart';
import 'package:streetmend_mobile/main.dart';
import 'package:streetmend_mobile/theme/appearance_controller.dart';
import 'package:streetmend_mobile/theme/appearance_store.dart';
import 'package:streetmend_mobile/theme/streetmend_theme.dart';
import 'package:streetmend_mobile/profile/appearance_page.dart';
import 'package:streetmend_mobile/profile/profile_page.dart';
import 'package:streetmend_mobile/reports/my_reports_page.dart';
import 'package:streetmend_mobile/reports/report_details_page.dart';
import 'package:streetmend_mobile/reports/report.dart';
import 'package:streetmend_mobile/capture/capture_page.dart';
import 'package:streetmend_mobile/capture/location_picker_page.dart';
import 'package:streetmend_mobile/capture/review_report_page.dart';
import 'package:streetmend_mobile/capture/report_draft.dart';

class MemoryAppearanceStore implements AppearanceStore {
  String? value;
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? gate;
  final writes = <String>[];
  @override
  Future<String?> read() async {
    if (failRead) throw StateError('read unavailable');
    return value;
  }

  @override
  Future<void> write(String value) async {
    await gate?.future;
    if (failWrite) throw StateError('write unavailable');
    this.value = value;
    writes.add(value);
  }
}

// Exercise the real store adapter without invoking native storage in widget tests.
class MemoryPreferences implements SharedPreferencesAsync {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (first > second ? first + .05 : second + .05) /
      (first > second ? second + .05 : first + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const fontPath = String.fromEnvironment('THEME_PREVIEW_FONT');
    if (fontPath.isNotEmpty) {
      final bytes = ByteData.sublistView(await File(fontPath).readAsBytes());
      for (final family in ['Roboto', 'Ahem']) {
        final loader = FontLoader(family)..addFont(Future.value(bytes));
        await loader.load();
      }
      final iconFile = File(
        '${File(fontPath).parent.path}/MaterialIcons-Regular.otf',
      );
      if (await iconFile.exists()) {
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(ByteData.sublistView(await iconFile.readAsBytes())),
          );
        await icons.load();
      }
    }
  });

  test('All choices survive a new controller and store adapter', () async {
    final preferences = MemoryPreferences();
    for (final mode in ThemeMode.values) {
      final first = AppearanceController(
        LocalAppearanceStore(preferences: preferences),
      );
      await first.select(mode);
      first.dispose();
      final restarted = AppearanceController(
        LocalAppearanceStore(preferences: preferences),
      );
      await restarted.load();
      expect(restarted.mode, mode);
      expect(preferences.values[LocalAppearanceStore.key], mode.name);
      restarted.dispose();
    }
  });

  test(
    'Missing, invalid and unreadable preferences safely use System Default',
    () async {
      for (final value in <String?>[null, 'unknown']) {
        final controller = AppearanceController(
          MemoryAppearanceStore()..value = value,
        );
        await controller.load();
        expect(controller.mode, ThemeMode.system);
        controller.dispose();
      }
      final controller = AppearanceController(
        MemoryAppearanceStore()..failRead = true,
      );
      await controller.load();
      expect(controller.mode, ThemeMode.system);
      expect(controller.error, isNotNull);
      controller.dispose();
    },
  );

  test('Rapid selections save in order; failures can be retried', () async {
    final store = MemoryAppearanceStore()..gate = Completer<void>();
    final controller = AppearanceController(store);
    final first = controller.select(ThemeMode.dark);
    final last = controller.select(ThemeMode.light);
    expect(controller.mode, ThemeMode.light);
    store.gate!.complete();
    await Future.wait([first, last]);
    expect(store.writes, ['dark', 'light']);
    expect(store.value, 'light');
    store.failWrite = true;
    await controller.select(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);
    expect(controller.error, isNotNull);
    store.failWrite = false;
    await controller.select(ThemeMode.dark);
    expect(controller.error, isNull);
    expect(store.value, 'dark');
    controller.dispose();
  });

  test('Text and primary action colour pairs have at least 4.5:1 contrast', () {
    for (final dark in [false, true]) {
      final c = StreetMendColors(dark);
      for (final background in [c.background, c.surface, c.soft]) {
        expect(contrast(c.ink, background), greaterThanOrEqualTo(4.5));
        expect(contrast(c.body, background), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(c.accent, c.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(c.muted, c.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(kOceanNavy, kFreshTeal), greaterThanOrEqualTo(4.5));
      expect(contrast(Colors.white, c.panel), greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets(
    'System follows platform brightness; explicit choices override it',
    (tester) async {
      final controller = AppearanceController(MemoryAppearanceStore());
      addTearDown(controller.dispose);
      final platform = tester.binding.platformDispatcher;
      addTearDown(platform.clearPlatformBrightnessTestValue);
      platform.platformBrightnessTestValue = Brightness.light;
      await tester.pumpWidget(
        StreetMendApp(
          appearance: controller,
          home: const Scaffold(body: Text('Theme probe')),
        ),
      );
      Brightness brightness() =>
          Theme.of(tester.element(find.text('Theme probe'))).brightness;
      expect(brightness(), Brightness.light);
      platform.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.dark);
      await controller.select(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.light);
      await controller.select(ThemeMode.dark);
      platform.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.dark);
      await controller.select(ThemeMode.system);
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.light);
    },
  );

  testWidgets(
    'Profile settings switch theme without losing Reports search or navigation',
    (tester) async {
      final store = MemoryAppearanceStore();
      final controller = AppearanceController(store);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        StreetMendApp(appearance: controller, home: const StreetMendHomePage()),
      );
      Finder tab(String label) => find.descendant(
        of: find.byType(StreetMendTabBar),
        matching: find.text(label),
      );
      await tester.tap(tab('Reports'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'teknokrat');
      await tester.tap(tab('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();
      expect(store.value, 'dark');
      expect(find.byType(AppearancePage), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Dark Mode'))).brightness,
        Brightness.dark,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(tab('Reports'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'teknokrat',
      );
    },
  );

  final photo = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGMQXjvpPwAEewJSRPuekAAAAABJRU5ErkJggg==',
  );
  // Each page is tested in both appearances, with large text on a small iPhone viewport.
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      '${mode.name}: all screens fit a small iPhone and use the selected theme',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = AppearanceController(MemoryAppearanceStore());
        await controller.select(mode);
        addTearDown(controller.dispose);
        final draft = ReportDraft()
          ..photo = photo
          ..category = IssueCategory.other
          ..customTitle = 'Damaged railing'
          ..description = 'The railing is loose.'
          ..location = IssueLocation(
            latitude: 3.1,
            longitude: 101.1,
            method: 'manual_map',
            confirmedAt: DateTime(2026),
          );
        final pages = <String, Widget>{
          'welcome': const StreetMendWelcomePage(),
          'login': const StreetMendLoginPage(),
          'home': const StreetMendHomePage(),
          'reports': const Scaffold(body: MyReportsPage()),
          'details': ReportDetailsPage(report: sampleReports.first),
          'capture': const CapturePage(),
          'location': LocationPickerPage(
            mapBuilder: (center, moved) => const SizedBox(
              height: 300,
              child: Center(child: Text('Map preview')),
            ),
          ),
          'review': ReviewReportPage(
            draft: draft,
            mapPreview: const SizedBox(height: 100),
          ),
          'profile': const Scaffold(body: ProfilePage()),
          'appearance': const AppearancePage(),
        };
        for (final entry in pages.entries) {
          final boundary = GlobalKey();
          await tester.pumpWidget(
            StreetMendApp(
              key: ValueKey('${mode.name}-${entry.key}'),
              appearance: controller,
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: RepaintBoundary(key: boundary, child: entry.value),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            Theme.of(tester.element(find.byKey(boundary))).brightness,
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
          );
          expect(tester.takeException(), isNull, reason: entry.key);
          if (const bool.fromEnvironment('WRITE_THEME_PREVIEWS') &&
              [
                'home',
                'reports',
                'appearance',
                'welcome',
              ].contains(entry.key)) {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('/tmp/streetmend-${mode.name}-${entry.key}.png')
                  .writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          final scroll = find.byType(Scrollable);
          if (scroll.evaluate().isNotEmpty) {
            await tester.drag(scroll.first, const Offset(0, -450));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} scrolled',
            );
          }
        }
        await tester.pumpWidget(
          StreetMendApp(key: UniqueKey(), appearance: controller),
        );
        await tester.pump(const Duration(milliseconds: 900));
        expect(find.byType(StreetMendSplashPage), findsOneWidget);
        expect(
          Theme.of(tester.element(find.byType(StreetMendSplashPage)))
              .brightness,
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.byType(StreetMendWelcomePage), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Capture input and validation survive a global appearance change',
    (tester) async {
      final controller = AppearanceController(MemoryAppearanceStore());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        StreetMendApp(appearance: controller, home: const CapturePage()),
      );
      final description = find.widgetWithText(
        TextFormField,
        'Problem description',
      );
      await tester.ensureVisible(description);
      await tester.enterText(description, 'Damaged railing near the crossing.');
      await controller.select(ThemeMode.dark);
      await tester.pumpAndSettle();
      final field = tester.widget<EditableText>(
        find.descendant(of: description, matching: find.byType(EditableText)),
      );
      expect(field.controller.text, 'Damaged railing near the crossing.');
      expect(Theme.of(tester.element(description)).brightness, Brightness.dark);
      await tester.ensureVisible(find.text('Continue to Location'));
      await tester.tap(find.text('Continue to Location'));
      await tester.pumpAndSettle();
      expect(find.text('Please choose a category.'), findsOneWidget);
    },
  );

  test(
    'ThemeData exposes matching brightness for Flutter system switching',
    () {
      expect(StreetMendTheme.light.brightness, Brightness.light);
      expect(StreetMendTheme.dark.brightness, Brightness.dark);
    },
  );
}
