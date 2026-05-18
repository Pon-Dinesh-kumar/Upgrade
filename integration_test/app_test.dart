import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:upgrade/main.dart' as app;
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // This allows the test to run even if there are infinite animations
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('end-to-end test', () {
    testWidgets('Full onboarding and dashboard navigation', (tester) async {
      dev.log('Starting integration test...');
      app.main();
      
      // Wait for app to load
      await tester.pumpAndSettle();
      dev.log('App loaded');

      // 1. Welcome Screen
      // Since pumpAndSettle might timeout with infinite animations, 
      // we use pump with a duration.
      await tester.pump(const Duration(seconds: 2));
      dev.log('Checking for Welcome Screen');
      expect(find.text('UPGRADE'), findsOneWidget);

      // 2. Swipe up to Intro Screen
      dev.log('Attempting swipe up to Intro...');
      await tester.drag(find.byType(PageView), const Offset(0, -600));
      await tester.pumpAndSettle();
      
      dev.log('Checking for Intro Screen');
      expect(find.textContaining('How UPGRADE Works'), findsOneWidget);

      // 3. Swipe up to Create Upgrade Screen
      dev.log('Attempting swipe up to Create Upgrade...');
      await tester.drag(find.byType(PageView), const Offset(0, -600));
      await tester.pumpAndSettle();
      
      dev.log('Checking for Create Upgrade Screen');
      expect(find.text('Set your first goal'), findsOneWidget);
      
      // 4. Define Upgrade
      dev.log('Entering Upgrade Name');
      await tester.enterText(find.byType(TextField).first, 'Fitness Transformation');
      await tester.pumpAndSettle();
      
      dev.log('Tapping CONTINUE');
      // The button on this page is labeled "CONTINUE" inside _CreateUpgradePage
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      
      // 5. Add Habits Page
      dev.log('Adding a habit');
      expect(find.text('Build your Protocol'), findsOneWidget);
      await tester.tap(find.text('ADD A HABIT'));
      await tester.pumpAndSettle();
      
      // Fill habit details in bottom sheet
      dev.log('Filling habit details');
      final habitNameField = find.byType(TextField).last;
      await tester.enterText(habitNameField, 'Morning Run');
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('ADD HABIT'));
      await tester.pumpAndSettle();
      
      dev.log('Tapping CONTINUE to Profile');
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      
      // 6. Profile Page
      dev.log('Entering username');
      expect(find.text('Identify Yourself'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'JohnDoe');
      await tester.pumpAndSettle();
      
      dev.log('Tapping LAUNCH UPGRADE');
      await tester.tap(find.text('LAUNCH UPGRADE'));
      
      // Heavy launch logic
      dev.log('Waiting for Dashboard...');
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();

      // 7. Dashboard
      dev.log('Verifying Dashboard');
      expect(find.textContaining('Today\'s Habits'), findsOneWidget);
      expect(find.text('JohnDoe'), findsOneWidget);
      dev.log('Integration test completed successfully!');
    });
  });
}
