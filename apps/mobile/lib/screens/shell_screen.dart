import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/ai_portal_route.dart';
import '../core/widgets/smooth_tab_view.dart';
import 'home/home_screen.dart';
import 'pos/pos_screen.dart';
import 'stock/stock_screen.dart';
import 'finance/finance_screen.dart';
import 'ai_assistant/ai_assistant_screen.dart';
import '../widgets/app_bottom_nav.dart';

/// Shell screen wrapping all tab destinations with [SmoothTabTransitionView]
/// for buttery smooth cross-fade motion while preserving tab states.
///
/// The center AI Assistant tab opens as the hero [AiAssistantPortalRoute],
/// an elastic bottom-center portal expansion with aurora ambient lighting.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  // 5 screens matching the 5-button nav bar 1:1.
  // Index 2 is a lightweight placeholder — the real AI screen
  // opens as the hero portal overlay when tapped.
  final List<Widget> _screens = [
    const HomeScreen(),          // 0 = Home
    const PosScreen(),           // 1 = POS
    const SizedBox.shrink(),     // 2 = AI placeholder (opens as portal)
    const StockScreen(),         // 3 = Stock
    const FinanceScreen(),       // 4 = Finance
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      // ── Open AI Assistant with Hero Portal Route ──
      _openAiAssistantPortal();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openAiAssistantPortal() async {
    await Navigator.of(context).push(
      AiAssistantPortalRoute(
        builder: (context) => const AiAssistantScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBody: true, // Allow content to flow under the floating bottom nav
      body: SmoothTabTransitionView(
        currentIndex: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

