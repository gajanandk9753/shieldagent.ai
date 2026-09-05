import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/animated_bottom_nav.dart';
import 'vendor_home_tab.dart';
import 'vendor_catalog_tab.dart';
import 'vendor_orders_tab.dart';
import 'vendor_profile_tab.dart';

class VendorShell extends StatefulWidget {
  const VendorShell({super.key});

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  int _index = 0;

  final _tabs = const [
    VendorHomeTab(),
    VendorCatalogTab(),
    VendorOrdersTab(),
    VendorProfileTab(),
  ];

  final _items = const [
    NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: "Home"),
    NavItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        label: "Catalog"),
    NavItem(
        icon: Icons.local_shipping_outlined,
        activeIcon: Icons.local_shipping_rounded,
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
        accent: AppColors.vendorAccent,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
