import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_trial/config/app_config.dart';
import 'package:flutter_trial/data/bookmarks_storage.dart';
import 'package:flutter_trial/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late int systemPops;

  setUp(() {
    systemPops = 0;
    SharedPreferences.setMockInitialValues({
      SharedPrefsBookmarksStorage.storageKey: jsonEncode([
        {
          'id': '1',
          'title': 'Saved Session',
          'startTime': '2026-10-14T10:30:00',
        },
      ]),
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemNavigator.pop') systemPops++;
          return null;
        });
  });

  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  bool onTab(WidgetTester tester, String label) {
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    const labels = ['Sessions', 'Bookmarks', 'Info'];
    return labels[bar.selectedIndex] == label;
  }

  testWidgets('detail -> Bookmarks -> Sessions -> exit', (tester) async {
    await tester.pumpWidget(TechExpoApp(config: AppConfig.prod));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bookmarks').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved Session'));
    await tester.pumpAndSettle();
    expect(find.text('Session Details'), findsOneWidget);

    await pressBack(tester);
    expect(find.text('Session Details'), findsNothing);
    expect(onTab(tester, 'Bookmarks'), isTrue);

    await pressBack(tester);
    expect(onTab(tester, 'Sessions'), isTrue);
    expect(systemPops, 0);

    await pressBack(tester);
    expect(systemPops, 1);
  });

  testWidgets('Info -> Sessions -> exit', (tester) async {
    await tester.pumpWidget(TechExpoApp(config: AppConfig.prod));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Info').last);
    await tester.pumpAndSettle();

    await pressBack(tester);
    expect(onTab(tester, 'Sessions'), isTrue);
    expect(systemPops, 0);

    await pressBack(tester);
    expect(systemPops, 1);
  });
}
