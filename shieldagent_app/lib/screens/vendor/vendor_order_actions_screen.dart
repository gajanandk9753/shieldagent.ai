import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/dashboard_cards.dart';
import '../../widgets/common/primary_button.dart';

class VendorOrderActionsScreen extends StatefulWidget {
  const VendorOrderActionsScreen({super.key});

  @override
  State<VendorOrderActionsScreen> createState() =>
      _VendorOrderActionsScreenState();
}

class _VendorOrderActionsScreenState extends State<VendorOrderActionsScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await ApiService.instance.get(
        ApiConstants.vendorOrders,
        auth: AuthMode.apiKey,
      );
      setState(() {
        _orders = List<Map<String, dynamic>>.from(res["orders"] ?? []);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't fetch orders.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runAction(String orderId, Future<Map<String, dynamic>> Function() call) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.vendorAccent)),
    );

    try {
      await call();
      if (!mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action Successful")));
      _fetchOrders(); // Refresh the list
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong"), backgroundColor: AppColors.danger));
    }
  }

  Future<void> _confirmAdvance(String orderId) async {
    await _runAction(orderId, () => ApiService.instance.post(
      ApiConstants.vendorConfirmAdvance(orderId),
      auth: AuthMode.apiKey,
    ));
  }

  Future<void> _markDelivered(String orderId) async {
    await _runAction(orderId, () => ApiService.instance.post(
      ApiConstants.vendorDeliveryConfirmed(orderId),
      auth: AuthMode.apiKey,
    ));
  }

  Future<void> _showPriceChangeDialog(String orderId) async {
    final priceCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Report Price Change", style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "If the price shifts mid-order, this re-runs the risk check. Large jumps may freeze the order.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: "New Price (₹)",
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.currency_rupee_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              final newAmount = double.tryParse(priceCtrl.text.trim());
              if (newAmount != null) {
                Navigator.pop(context);
                _runAction(orderId, () => ApiService.instance.getWithBody(
                  ApiConstants.vendorReportPriceChange(orderId),
                  body: {"newAmount": newAmount},
                  auth: AuthMode.apiKey,
                ));
              }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Live Orders")),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchOrders,
          color: AppColors.vendorAccent,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.vendorAccent))
              : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
              : _orders.isEmpty
              ? ListView(
            children: const [
              SizedBox(height: 100),
              Center(child: Text("No orders found", style: TextStyle(color: AppColors.textSecondary))),
            ],
          )
              : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = _orders[index];
              final orderId = order["_id"] ?? "";
              final state = order["state"] ?? "UNKNOWN";

              return Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "ID: ${orderId.toString().substring(orderId.length - 6).toUpperCase()}",
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        StatusPill.forDecision(state),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text("Total: ₹${order["totalAmount"] ?? 0}", style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: "Confirm Advance",
                            color: AppColors.vendorAccent,
                            onPressed: () => _confirmAdvance(orderId),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PrimaryButton(
                            label: "Deliver",
                            outlined: true,
                            onPressed: () => _markDelivered(orderId),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: "Report Price Change",
                        color: AppColors.warning,
                        onPressed: () => _showPriceChangeDialog(orderId),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}