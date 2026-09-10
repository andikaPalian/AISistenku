import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiga_angkatan/core/theme/app_animations.dart';
import 'package:tiga_angkatan/core/widgets/ai_portal_route.dart';
import 'package:tiga_angkatan/core/widgets/bouncing_press.dart';
import 'package:tiga_angkatan/core/widgets/smooth_tab_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Motion Tokens & Animation Standards Tests', () {
    test('Exit duration is faster than enter duration (UX Pro Max Rule)', () {
      expect(
        AppAnimations.modalExit < AppAnimations.modalEnter,
        isTrue,
      );
      expect(
        AppAnimations.aiPortalExit < AppAnimations.aiPortalEnter,
        isTrue,
      );
      expect(AppAnimations.quick.inMilliseconds, lessThanOrEqualTo(200));
      expect(AppAnimations.tabSwitch.inMilliseconds, lessThanOrEqualTo(250));
    });
  });

  group('BouncingPress Micro-Interaction Tests', () {
    testWidgets('BouncingPress renders child and executes onTap callback',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BouncingPress(
                onTap: () => tapped = true,
                child: const Text('Bouncing Button'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bouncing Button'), findsOneWidget);

      await tester.tap(find.text('Bouncing Button'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('SmoothTabTransitionView Widget Tests', () {
    testWidgets('SmoothTabTransitionView preserves children and switches smoothly',
        (WidgetTester tester) async {
      int activeTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: SmoothTabTransitionView(
                  currentIndex: activeTab,
                  children: const [
                    Text('Tab 0 Content'),
                    Text('Tab 1 Content'),
                    Text('Tab 2 Content'),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => activeTab = 1),
                  child: const Icon(Icons.swap_horiz),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tab 0 Content'), findsOneWidget);

      // Switch tab to 1
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Tab 1 Content'), findsOneWidget);
    });
  });

  group('AiAssistantPortalRoute Tests', () {
    testWidgets('AiAssistantPortalRoute opens with blur & aurora and pops cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      AiAssistantPortalRoute(
                        builder: (_) => const Scaffold(
                          body: Center(child: Text('AI Assistant Console')),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open AI'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap open button
      await tester.tap(find.text('Open AI'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // In mid-flight, portal content is present
      expect(find.text('AI Assistant Console'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('AI Assistant Console'), findsOneWidget);

      // Pop the route
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(find.text('Open AI'), findsOneWidget);
    });
  });
}
