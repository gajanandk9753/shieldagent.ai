import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/common/dashboard_cards.dart';
import '../../widgets/common/primary_button.dart';

class VendorOrdersTab extends StatefulWidget {
  const VendorOrdersTab({super.key});

  @override
  State<VendorOrdersTab> createState() => _VendorOrdersTabState();
}

class _VendorOrdersTabState extends State<VendorOrdersTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  String? _resolvingId;

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
      setState(() {
        _orders = list.map((e) => e as Map<String, dynamic>).toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't load flagged orders.");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resolve(String orderId, String decision) async {
    setState(() => _resolvingId = orderId);
    try {
      await ApiService.instance.post(
        ApiConstants.vendorResolveOrder(orderId),
        body: {"decision": decision},
        auth: AuthMode.jwt,
      );
      setState(() => _orders.removeWhere((o) => o["_id"] == orderId));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _resolvingId = null);
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
          const Text(
            "Flagged Orders",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Orders ShieldAgent froze — approve or reject.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.vendorAccent)),
            )
          else if (_error != null)
            EmptyState(
              icon: Icons.error_outline_rounded,
              title: "Couldn't load orders",
              subtitle: _error!,
            )
          else if (_orders.isEmpty)
            const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: "Nothing frozen right now",
              subtitle: "Flagged orders will show up here for review.",
            )
          else
            ..._orders.map((order) {
              final id = order["_id"]?.toString() ?? "";
              final busy = _resolvingId == id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              id,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          const StatusPill(text: "FROZEN", color: AppColors.danger),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order["reason"]?.toString() ??
                            "Risk score exceeded the freeze threshold.",
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: "Approve",
                              isLoading: busy,
                              color: AppColors.success,
                              onPressed: () => _resolve(id, "APPROVE"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryButton(
                              label: "Reject",
                              outlined: true,
                              isLoading: false,
                              onPressed:
                                  busy ? null : () => _resolve(id, "REJECT"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
