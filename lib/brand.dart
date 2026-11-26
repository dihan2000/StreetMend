import 'package:flutter/material.dart';

// StreetMend brand colours. These names make the palette easy to reuse.
const Color kOceanNavy = Color(0xFF173448);
const Color kFreshTeal = Color(0xFF13AD92);
const Color kSoftIvory = Color(0xFFF7F9F8);
const Color kWarmGold = Color(0xFFFFD27A);
const Color kMistBlue = Color(0xFFDDEEF1);

// Dark navy-tinted body text for readable contrast on ivory and white.
const Color kBodyText = Color(0xFF1A2F3A);

/// Semantic colours: the role stays the same while appearance changes.
StreetMendColors appColors(BuildContext context) =>
    StreetMendColors(Theme.of(context).brightness == Brightness.dark);

class StreetMendColors {
  const StreetMendColors(this.dark);
  final bool dark;
  Color get background => dark ? const Color(0xFF0C1822) : kSoftIvory;
  Color get surface => dark ? const Color(0xFF192B37) : Colors.white;
  Color get soft => dark ? const Color(0xFF243D49) : kMistBlue;
  Color get ink => dark ? const Color(0xFFF1F6F8) : kOceanNavy;
  Color get body => dark ? const Color(0xFFCFDCE2) : kBodyText;
  Color get muted => dark ? const Color(0xFFA9BCC6) : const Color(0xFF526874);
  Color get accent => dark ? const Color(0xFF58DCC1) : const Color(0xFF007765);
  Color get border => dark ? const Color(0xFF49616E) : const Color(0xFFBCCFD6);
  Color get panel => dark ? const Color(0xFF122A38) : kOceanNavy;
  Color get error => dark ? const Color(0xFFFFB4AB) : const Color(0xFFB42318);
  List<Color> get heroGradient => dark
      ? const [Color(0xFF102330), Color(0xFF183C43)]
      : const [Color(0xFF122A3A), Color(0xFF1B5C62)];
}
