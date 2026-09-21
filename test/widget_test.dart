// Smoke tests for Paper & Ink.
//
// The full app requires async initialization (SharedPreferences) and is not
// trivially pumpable in the default test environment, so we test the isolated
// pieces instead.

import 'package:flutter_test/flutter_test.dart';

import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  group('AppColorsExtension tokens', () {
    test('light palette provides all required color fields', () {
      final light = AppColorsExtension.light;
      expect(light.primary, isA<Color>());
      expect(light.onPrimary, isA<Color>());
      expect(light.appBackground, isA<Color>());
      expect(light.surface, isA<Color>());
      expect(light.textPrimary, isA<Color>());
      expect(light.textSecondary, isA<Color>());
      expect(light.error, isA<Color>());
    });

    test('dark palette provides all required color fields', () {
      final dark = AppColorsExtension.dark;
      expect(dark.primary, isA<Color>());
      expect(dark.onPrimary, isA<Color>());
      expect(dark.appBackground, isA<Color>());
      expect(dark.surface, isA<Color>());
      expect(dark.textPrimary, isA<Color>());
      expect(dark.textSecondary, isA<Color>());
      expect(dark.error, isA<Color>());
    });

    test('copyWith produces a new instance with patched fields', () {
      const light = AppColorsExtension.light;
      final patched = light.copyWith(primary: const Color(0xFF112233)) as AppColorsExtension;
      expect(patched.primary, const Color(0xFF112233));
      // Untouched fields remain unchanged.
      expect(patched.appBackground, light.appBackground);
      expect(patched.textPrimary, light.textPrimary);
    });

    test('lerp at t=1.0 returns the second palette', () {
      final light = AppColorsExtension.light;
      final dark = AppColorsExtension.dark;
      // lerp's declared return type is ThemeExtension<AppColorsExtension>;
      // cast to the concrete type to access extension fields.
      final lerped = light.lerp(dark, 1.0) as AppColorsExtension;
      expect(lerped.primary, dark.primary);
      expect(lerped.textPrimary, dark.textPrimary);
    });
  });
}
