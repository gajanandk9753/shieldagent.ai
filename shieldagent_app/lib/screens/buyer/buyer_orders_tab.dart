import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/common/dashboard_cards.dart';
import '../shared/incident_review_screen.dart';

class BuyerOrdersTab extends StatefulWidget {
  const BuyerOrdersTab({super.key});

  @override
  State<BuyerOrdersTab> createState() => _BuyerOrdersTabState();
}

class _BuyerOrdersTabState extends State<BuyerOrdersTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

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
      final res =
          await ApiService.instance.get(ApiConstants.buyerOrders, auth: AuthMode.jwt);
      final list = (res["transactions"] ?? []) as List<dynamic>;
      setState(() {
        _orders = list.map((e) => e as Map<String, dynamic>).toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't load orders.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      backgroundColor: AppColors.surface,
      color: AppColors.buyerAccent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          const Text(
            "Live Transaction Feed",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Tap any order for the full decision trail.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.buyerAccent)),
            )
          else if (_error != null)
            EmptyState(
              icon: Icons.error_outline_rounded,
              title: "Couldn't load orders",
              subtitle: _error!,
            )
          else if (_orders.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: "No orders yet",
              subtitle: "Orders placed via the risk engine will show up here.",
            )
          else
            ..._orders.map((order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderTile(
                    order: order,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => IncidentReviewScreen(order: order),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  const _OrderTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final state = order["state"]?.toString() ?? "ADVANCE_LOCKED";
    final advance = (order["advanceAmount"] ?? 0);
    final balance = (order["balanceAmount"] ?? 0);
    final total = (advance is num ? advance : 0) + (balance is num ? balance : 0);

    // riskScore/decision aren't on Transaction yet (see backend-gaps note) —
    // this degrades to just the state pill until placeOrder copies them over.
    final riskScore = order["riskScore"];
    final decision = order["decision"]?.toString();

    final vendor = order["vendorId"];
    final vendorName =
        (vendor is Map) ? (vendor["companyName"]?.toString() ?? "Vendor") : "Vendor";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendorName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹$total total  ·  ₹$advance advance",
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                StatusPill.forDecision(decision ?? state),
              ],
            ),
            if (riskScore != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.speed_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text("Score: $riskScore/100",
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.textMuted),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
