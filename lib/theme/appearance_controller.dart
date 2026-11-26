import 'package:flutter/material.dart';

import 'appearance_store.dart';

/// Owns the selection; Flutter resolves System against device brightness.
class AppearanceController extends ChangeNotifier {
  AppearanceController(this.store);
  final AppearanceStore store;
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  String? error;
  int _revision = 0;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _writes = Future.value();

  Future<void> load() async {
    final revision = _revision;
    try {
      final value = await store.read();
      if (_disposed || revision != _revision) return;
      error = null;
      _mode =
          ThemeMode.values.where((mode) => mode.name == value).firstOrNull ??
          ThemeMode.system;
    } catch (_) {
      if (_disposed || revision != _revision) return;
      _mode = ThemeMode.system;
      error = 'Appearance could not be loaded. Using System Default.';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> select(ThemeMode mode) {
    _mode = mode;
    error = null;
    final revision = ++_revision;
    notifyListeners();
    // Serialize writes so rapid taps cannot leave an older preference on disk.
    _writes = _writes.then((_) async {
      try {
        await store.write(mode.name);
      } catch (_) {
        if (!_disposed && revision == _revision) {
          error = 'Appearance changed for this session, but could not be saved. Tap the option again to retry.';
          notifyListeners();
        }
      }
    });
    return _writes;
  }
}
