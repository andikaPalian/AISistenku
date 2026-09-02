import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'pos/pos_screen.dart';
import 'stock/stock_screen.dart';
import 'finance/finance_screen.dart';
import 'ai_assistant/ai_assistant_screen.dart';
import '../widgets/app_bottom_nav.dart';

/// Shell screen wrapping all tab destinations with an IndexedStack
/// to preserve state across tab switches.
///
/// The center AI Assistant tab is special: it opens as a full-screen
/// modal overlay with a slide-up animation instead of embedding in
/// the IndexedStack, making it feel like the hero feature.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  // 5 screens matching the 5-button nav bar 1:1.
  // Index 2 is a lightweight placeholder — the real AI screen
  // opens as a full-screen modal overlay when tapped.
  final List<Widget> _screens = [
    const HomeScreen(),          // 0 = Home
    const PosScreen(),           // 1 = POS
    const SizedBox.shrink(),     // 2 = AI placeholder (opens as modal)
    const StockScreen(),         // 3 = Stock
    const FinanceScreen(),       // 4 = Finance
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      // ── Open AI Assistant as full-screen slide-up modal ──
      _openAiAssistantModal();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openAiAssistantModal() async {
    await Navigator.of(context).push(
      _AiAssistantModalRoute(
        builder: (context) => const AiAssistantScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

/// Custom [PageRoute] for the AI Assistant modal with:
/// - Slide-up from bottom with spring curve
/// - Concurrent fade-in
/// - Subtle scale from 95% → 100%
/// - Dark scrim backdrop
class _AiAssistantModalRoute extends PageRouteBuilder<void> {
  _AiAssistantModalRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          opaque: true,
          barrierColor: Colors.black54,
          fullscreenDialog: true,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            // Spring-like curve for the enter, smooth ease for exit
            final enterCurve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInQuad,
            );

            // Slide from bottom
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(enterCurve);

            // Fade in
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ));

            // Subtle scale
            final scaleAnimation = Tween<double>(
              begin: 0.96,
              end: 1.0,
            ).animate(enterCurve);

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
            );
          },
        );

  final WidgetBuilder builder;
}

/// Placeholder screen for tabs that haven't been implemented yet.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Segera hadir',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
