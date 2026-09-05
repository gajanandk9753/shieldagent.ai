import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/animated_bottom_nav.dart';
import 'buyer_home_tab.dart';
import 'buyer_catalog_tab.dart';
import 'buyer_orders_tab.dart';
import 'buyer_profile_tab.dart';

class BuyerShell extends StatefulWidget {
  const BuyerShell({super.key});

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
  int _index = 0;

  final _tabs = const [
    BuyerHomeTab(),
    BuyerCatalogTab(),
    BuyerOrdersTab(),
    BuyerProfileTab(),
  ];

  final _items = const [
    NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: "Home"),
    NavItem(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront_rounded,
        label: "Catalog"),
    NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: "Orders"),
    NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _tabs[_index],
          ),
        ),
      ),
      bottomNavigationBar: AnimatedBottomNav(
        items: _items,
        currentIndex: _index,
        accent: AppColors.buyerAccent,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
