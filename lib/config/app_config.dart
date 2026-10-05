import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../data/sessions_api.dart';

enum Flavor { dev, prod }

/// Settings that differ between the dev and prod builds.
///
/// The flavor comes from `flutter run --flavor <name>`; the native app name
/// and bundle id are set per flavor in Gradle and Xcode.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.sessionsEndpoint,
  });

  final Flavor flavor;
  final String appName;
  final Uri sessionsEndpoint;

  bool get isDev => flavor == Flavor.dev;

  static final dev = AppConfig(
    flavor: Flavor.dev,
    appName: 'TechExpo Dev',
    sessionsEndpoint: SessionsApi.defaultEndpoint,
  );

  static final prod = AppConfig(
    flavor: Flavor.prod,
    appName: 'MunichTech EXPO',
    sessionsEndpoint: SessionsApi.defaultEndpoint,
  );

  /// Picks the config for Flutter's `appFlavor`. Unknown or missing values
  /// fall back to dev, so a misconfigured build never looks like prod.
  static AppConfig fromFlavorName(String? name) {
    switch (name) {
      case 'prod':
        return prod;
      case 'dev':
        return dev;
      default:
        developer.log('Unknown flavor "$name", using dev', name: 'AppConfig');
        return dev;
    }
  }

  /// Adds a "DEV" ribbon in dev builds; returns [child] unchanged in prod.
  Widget wrapWithBanner(Widget child) {
    if (!isDev) return child;
    return Banner(
      message: 'DEV',
      location: BannerLocation.topEnd,
      color: const Color(0xFFEA580C),
      child: child,
    );
  }
}
