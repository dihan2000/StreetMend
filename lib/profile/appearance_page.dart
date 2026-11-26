import 'package:flutter/material.dart';

import '../brand.dart';
import '../theme/appearance_scope.dart';

String appearanceLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'System Default',
  ThemeMode.light => 'Light Mode',
  ThemeMode.dark => 'Dark Mode',
};

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = AppearanceScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Make StreetMend yours',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: appColors(context).ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your preferred appearance. Your choice is saved on this device.',
            ),
            const SizedBox(height: 24),
            for (final mode in ThemeMode.values)
              Card(
                child: Semantics(
                  selected: controller.mode == mode,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: Icon(switch (mode) {
                      ThemeMode.system => Icons.brightness_auto_outlined,
                      ThemeMode.light => Icons.light_mode_outlined,
                      ThemeMode.dark => Icons.dark_mode_outlined,
                    }, color: appColors(context).accent),
                    title: Text(
                      appearanceLabel(mode),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(switch (mode) {
                      ThemeMode.system =>
                        'Follow your device’s Light or Dark appearance.',
                      ThemeMode.light => 'Always use soft, light surfaces.',
                      ThemeMode.dark =>
                        'Always use deep navy and charcoal surfaces.',
                    }),
                    trailing: controller.mode == mode
                        ? Icon(
                            Icons.check_circle,
                            color: appColors(context).accent,
                          )
                        : null,
                    onTap: () => controller.select(mode),
                  ),
                ),
              ),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  controller.error!,
                  style: TextStyle(color: appColors(context).error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
