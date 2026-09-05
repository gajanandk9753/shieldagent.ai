import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/common/dashboard_cards.dart';
import '../../widgets/common/primary_button.dart';
import 'vendor_order_actions_screen.dart';
import '../shared/threat_log_screen.dart';

class VendorHomeTab extends StatefulWidget {
  const VendorHomeTab({super.key});

  @override
  State<VendorHomeTab> createState() => _VendorHomeTabState();
}

class _VendorHomeTabState extends State<VendorHomeTab> {
  bool _loading = true;
  String? _error;
  int _frozenCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.instance
          .get(ApiConstants.vendorFrozenOrders, auth: AuthMode.jwt);
      final list = (res["transactions"] ?? []) as List<dynamic>;
      setState(() => _frozenCount = list.length);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't load dashboard. Pull to retry.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      backgroundColor: AppColors.surface,
      color: AppColors.vendorAccent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Dashboard",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.shield_moon_outlined,
                    color: AppColors.textSecondary),
                tooltip: "Threat Log",
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ThreatLogScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "SteelWorks' live status",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 22),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.vendorAccent)),
            )
          else if (_error != null)
            EmptyState(
              icon: Icons.wifi_off_rounded,
              title: "Couldn't reach ShieldAgent",
              subtitle: _error!,
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: "Flagged Orders",
                    value: "$_frozenCount",
                    icon: Icons.flag_rounded,
                    accent: _frozenCount > 0
                        ? AppColors.danger
                        : AppColors.vendorAccent,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: StatCard(
                    label: "Escrow model",
                    value: "Milestone",
                    icon: Icons.account_balance_rounded,
                    accent: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: "Manage an Order",
              color: AppColors.vendorAccent,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const VendorOrderActionsScreen()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
