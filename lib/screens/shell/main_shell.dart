import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../campaign/new_campaign_screen.dart';
import '../deadlines/deadlines_screen.dart';
import '../finance/dashboard_screen.dart';
import '../grocery/grocery_screen.dart';

/// Contenedor con las 4 pestañas del diseño y la barra de navegación inferior.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    (
      Icons.account_balance_wallet_outlined,
      'Finanzas',
      AppColors.secondaryFixedDim,
    ),
    (Icons.campaign_outlined, 'Campaña', AppColors.onTertiaryContainer),
    (Icons.shopping_bag_outlined, 'Súper', AppColors.secondaryFixedDim),
    (Icons.event_outlined, 'Deadlines', AppColors.onTertiaryContainer),
  ];

  void goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onNewCampaign: () => goTo(1)),
      NewCampaignScreen(onSaved: () => goTo(0)),
      const GroceryScreen(),
      const DeadlinesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  _NavItem(
                    icon: _tabs[i].$1,
                    label: _tabs[i].$2,
                    dot: _tabs[i].$3,
                    active: _index == i,
                    onTap: () => goTo(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.dot,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color dot;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: color),
                Positioned(
                  top: -2,
                  right: -4,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: active ? 1 : 0,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppText.labelSm.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
