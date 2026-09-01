import 'package:flutter/widgets.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;

  const NavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
  });
}
