import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_trial/config/app_config.dart';

void main() {
  group('AppConfig.fromFlavorName', () {
    test('returns prod for "prod"', () {
      final config = AppConfig.fromFlavorName('prod');
      expect(config.flavor, Flavor.prod);
      expect(config.appName, 'MunichTech EXPO');
    });

    test('returns dev for "dev"', () {
      final config = AppConfig.fromFlavorName('dev');
      expect(config.flavor, Flavor.dev);
      expect(config.appName, 'TechExpo Dev');
    });

    test('falls back to dev for a missing or unknown flavor', () {
      expect(AppConfig.fromFlavorName(null).flavor, Flavor.dev);
      expect(AppConfig.fromFlavorName('staging').flavor, Flavor.dev);
    });
  });

  group('AppConfig.wrapWithBanner', () {
    const child = SizedBox();

    test('adds a DEV banner in dev', () {
      final wrapped = AppConfig.dev.wrapWithBanner(child);
      expect(wrapped, isA<Banner>());
      expect((wrapped as Banner).message, 'DEV');
    });

    test('leaves prod untouched', () {
      expect(AppConfig.prod.wrapWithBanner(child), same(child));
    });
  });
}
