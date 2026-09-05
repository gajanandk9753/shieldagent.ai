import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/threat_log_store.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/dashboard_cards.dart';
import '../../widgets/common/primary_button.dart';

class VendorCatalogTab extends StatefulWidget {
  const VendorCatalogTab({super.key});

  @override
  State<VendorCatalogTab> createState() => _VendorCatalogTabState();
}

class _VendorCatalogTabState extends State<VendorCatalogTab> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  List<Map<String, dynamic>> _catalogItems = [];
  bool _isLoading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchCatalog() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService.instance.get(
        ApiConstants.vendorGetCatalog,
        auth: AuthMode.apiKey,
      );

      final List<dynamic> rawCatalog = res["catalog"] ?? [];
      setState(() {
        _catalogItems = rawCatalog.map((e) => Map<String, dynamic>.from(e)).toList().reversed.toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Unable to load catalog items.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    if (name.isEmpty || price == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final res = await ApiService.instance.post(
        ApiConstants.vendorSaveCatalog,
        body: {"name": name, "price": price},
        auth: AuthMode.apiKey,
      );
      final saved = (res["item"] as Map<String, dynamic>?) ??
          {"name": name, "price": price};

      setState(() {
        _catalogItems.insert(0, saved);
        _nameController.clear();
        _priceController.clear();
      });
    } on ApiException catch (e) {
      final details = e.body?["securityDetails"] as Map<String, dynamic>?;
      if (details != null) {
        ThreatLogStore.instance.add(ThreatEvent(
          type: ThreatType.promptInjection,
          title: details["threatType"]?.toString() ?? "Prompt Injection",
          detail: 'Payload: "$name"\nReason: ${details["reason"] ?? "—"}',
        ));
        if (mounted) await _showFirewallAlert(details, name);
      }
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't save that item.");
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _showFirewallAlert(
      Map<String, dynamic> details, String payload) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.danger.withOpacity(0.4)),
        ),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad_rounded, color: AppColors.danger),
            SizedBox(width: 10),
            Text("Firewall Blocked This",
                style: TextStyle(color: AppColors.danger, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              details["threatType"]?.toString() ?? "Prompt Injection",
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              details["reason"]?.toString() ?? "",
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            const Text("Your account has been suspended.",
                style: TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchCatalog,
      color: AppColors.vendorAccent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Catalog",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Each item saves instantly — buyer agents see it right away.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    label: "Item name",
                    controller: _nameController,
                    hint: "Steel Sheets",
                    prefixIcon: Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: "Price (₹)",
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: "Add Item",
              isLoading: _saving,
              color: AppColors.vendorAccent,
              onPressed: _addItem,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Saved Catalog Items",
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  "${_catalogItems.length} items",
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.vendorAccent,
                ),
              )
                  : _catalogItems.isEmpty
                  ? const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: "No catalog items found",
                subtitle: "Items you add above will be stored in your catalog.",
              )
                  : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: _catalogItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _catalogItems[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["name"]?.toString() ?? "",
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (item["itemId"] != null)
                                Text(
                                  item["itemId"].toString(),
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          "₹${item["price"]}",
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}