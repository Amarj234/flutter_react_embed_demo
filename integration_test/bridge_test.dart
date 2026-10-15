import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:react_embed_demo/main.dart';

Future<void> pumpUntil(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 30)}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Dart <-> React bridge works with the CoreUI dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const DemoApp());
    await pumpUntil(tester, find.text('✅ React view ready'));

    // Dart -> JS call with a result.
    await tester.tap(find.text('Get info'));
    await pumpUntil(tester, find.textContaining('↩️ getInfo: #/dashboard'));

    // Dart -> JS call that changes the route; JS -> Dart route event.
    await tester.tap(find.text('Charts'));
    await pumpUntil(tester, find.textContaining('🧭 navigate → #/charts'));
    await pumpUntil(tester, find.textContaining('📩 route: {"hash":"#/charts"'));

    // Props update (theme) without reload.
    await tester.tap(find.byIcon(Icons.dark_mode));
    await pumpUntil(tester, find.byIcon(Icons.light_mode));
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Dart <-> React Native bridge works on the native screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.text('React Native'));
    await pumpUntil(tester, find.text('✅ React Native view ready'));
    // The JS bridge connected and the component mounted inside React Native.
    await pumpUntil(tester, find.textContaining('📩 mounted: {"viewId"'));

    // Dart -> JS call with a result.
    await tester.tap(find.text('Get info'));
    await pumpUntil(tester, find.textContaining('↩️ getInfo: react-native'));

    // Dart -> JS event; JS -> Dart event in reply.
    await tester.tap(find.text('Send toast'));
    await pumpUntil(tester, find.textContaining('📩 toastShown: {"message":"Hello from Flutter 👋"}'));

    // JS -> Dart call: JS awaits Dart's getFlutterInfo handler, then reports it.
    await tester.tap(find.text('JS → Dart call'));
    await pumpUntil(tester, find.textContaining('📩 flutterInfo: {"platform":'));

    // Props update (theme) re-renders React Native without a remount.
    await tester.tap(find.byIcon(Icons.dark_mode));
    await pumpUntil(tester, find.textContaining('📩 propsApplied: {"theme":"dark"}'));
    expect(find.textContaining('❌'), findsNothing);

    // Switching back to the web screen releases the native surface cleanly.
    await tester.tap(find.text('React Web'));
    await pumpUntil(tester, find.text('✅ React view ready'));
    await tester.pump(const Duration(seconds: 2));
  });
}
