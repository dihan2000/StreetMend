# StreetMend Appearance Settings

## User experience

Open Profile → Appearance and choose System Default, Light Mode, or Dark Mode. System Default follows the operating system while the app is open. Explicit Light/Dark choices override the operating system. All three choices are remembered locally. Changing appearance preserves the navigation history, Reports search/filters, and in-progress capture form.

Light uses ivory backgrounds, white cards, pastel panels, navy text and readable teal accents. Dark uses deep navy backgrounds, charcoal/navy cards, soft white text and lighter teal accents. Gold highlights and branded navy panels remain. Status badges keep text labels in addition to colours.

Map imagery and photographs retain their original colours. Map attribution, loading messages and surrounding controls use the selected theme. The operating system owns camera/photo-picker appearance. The native launch storyboard shown before Flutter renders is separate from the themed Flutter Splash screen.

## Architecture for an advisor

- `lib/theme/streetmend_theme.dart`: two ThemeData configurations define the shared Material component styles.
- `lib/brand.dart`: original brand constants plus semantic colours. For example, `ink` means readable foreground text; it is navy in Light Mode and soft white in Dark Mode.
- `lib/theme/appearance_controller.dart`: a small ChangeNotifier owns ThemeMode and notifies the app when it changes. Serialized writes prevent rapid selections from saving in the wrong order. Storage failures show an honest message while allowing the session's theme to change.
- `lib/theme/appearance_store.dart`: saves one string (`system`, `light`, or `dark`) under `streetmend.appearance` using SharedPreferencesAsync. This is not a database and stores no reports or photos.
- `lib/theme/appearance_scope.dart`: shares the controller with Profile and Appearance screens using Flutter's built-in inherited notification mechanism.
- `lib/main.dart`: loads the saved preference before runApp, supplies theme/darkTheme/themeMode to MaterialApp, and connects Profile to the existing tab container. The Navigator is not replaced on theme changes.
- `lib/profile/profile_page.dart` and `appearance_page.dart`: settings navigation and labelled, accessible selection rows.

All existing screens now read theme-aware foreground/background colours. Selected light-on-dark branded panels remain intentional. Larger-text layout fixes let the Welcome brand, Home points, report status/date and shortcut tiles fit without changing report behaviour.

## Dependencies and platform behaviour

Only `shared_preferences` was added as a direct dependency (along with its required transitive implementations in the lockfile). It uses iOS NSUserDefaults and browser local storage through the platform plugin. No permissions, authentication, or database were added. Browser persistence is specific to its origin and can be cleared by the user or private browsing; local preferences are not cross-device sync.

No saved value, an unrecognized value, or an unreadable preference falls back to System Default. The small preference is suitable for this package; it is not a replacement for durable report storage.

## Verification

Automated coverage includes all three saved choices with a fresh controller/store adapter; absent/invalid values; read/write failures and retry; rapid changes; live platform-brightness changes and explicit overrides; Profile navigation; preservation of Reports search and Capture input; core foreground/background contrast of at least 4.5:1; and all screens at 375 × 667 with 1.5× text in both themes. The existing capture, map, manual location, custom issue, and reports regression tests also run.

Storage tests use an in-memory implementation of the plugin interface; real iPhone persistence, native permission dialogs, and system appearance changes should also be checked on a device. Physical iPhone verification is not claimed by widget tests. Full Xcode was unavailable in this environment in the earlier native build check.

To review manually: select Dark Mode, return to Home/Reports/Capture, restart the app, and confirm Dark Mode remains. Then select System Default and change the iPhone's appearance in Settings. The app should follow without losing its current screen.

Final verification for this implementation: `flutter analyze --no-pub` reported no issues, and `flutter test --no-pub` passed all 29 tests. Light/dark widget previews were also rendered for visual review. These results cover Flutter code and simulated platform behaviour, not a physical-device certification.
