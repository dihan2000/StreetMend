import 'package:flutter/material.dart';

import '../brand.dart';
import '../theme/appearance_scope.dart';
import 'appearance_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: appColors(context).ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Personalise your StreetMend experience.'),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.palette_outlined,
              color: appColors(context).accent,
            ),
            title: const Text('Appearance'),
            subtitle: Text(
              appearanceLabel(
                AppearanceScope.maybeOf(context)?.mode ?? ThemeMode.system,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AppearancePage()),
            ),
          ),
        ),
      ],
    ),
  );
}
