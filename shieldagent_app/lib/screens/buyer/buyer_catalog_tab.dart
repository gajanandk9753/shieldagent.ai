import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/common/dashboard_cards.dart';
import 'buyer_order_evaluate_screen.dart';

class BuyerCatalogTab extends StatefulWidget {
  const BuyerCatalogTab({super.key});

  @override
  State<BuyerCatalogTab> createState() => _BuyerCatalogTabState();
}

class _BuyerCatalogTabState extends State<BuyerCatalogTab> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _catalogItems = [];
  Map<String, dynamic>? _selectedVendor;

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  Future<void> _fetchVendors() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedVendor = null;
      _catalogItems = [];
    });
    try {
      final res = await ApiService.instance.get(
        ApiConstants.buyerVendors,
        auth: AuthMode.apiKey,
      );
      final list = (res["vendors"] ?? []) as List<dynamic>;
      setState(() {
        _vendors = list.map((e) => e as Map<String, dynamic>).toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't load vendors.");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchCatalog(Map<String, dynamic> vendor) async {
    final vendorId = vendor["_id"]?.toString() ?? "";
    if (vendorId.isEmpty) return;

    setState(() {
      _selectedVendor = vendor;
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.instance.get(
        "${ApiConstants.buyerCatalog}?vendorId=$vendorId",
        auth: AuthMode.apiKey,
      );
      final list = (res["catalog"] ?? []) as List<dynamic>;
      setState(() {
        _catalogItems = list.map((e) => e as Map<String, dynamic>).toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't load the catalog.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_selectedVendor != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 22),
                    onPressed: () {
                      setState(() {
                        _selectedVendor = null;
                        _catalogItems = [];
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedVendor == null ? "Browse Vendors" : (_selectedVendor!["companyName"] ?? "Vendor Catalog"),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedVendor == null
                          ? "Select a vendor to view their catalog."
                          : "Reputation Score: ${_selectedVendor!["reputationScore"] ?? "-"}",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.buyerAccent))
                : _error != null
                ? EmptyState(icon: Icons.error_outline_rounded, title: "Error", subtitle: _error!)
                : _selectedVendor == null
                ? _buildVendorList()
                : _buildCatalogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorList() {
    if (_vendors.isEmpty) {
      return const EmptyState(icon: Icons.storefront_outlined, title: "No Vendors", subtitle: "No vendors are registered yet.");
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _vendors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final vendor = _vendors[index];
        final isSuspended = vendor["status"] == "SUSPENDED";

        return GestureDetector(
          onTap: isSuspended ? null : () => _fetchCatalog(vendor),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSuspended ? AppColors.danger.withOpacity(0.5) : AppColors.surfaceBorder),

            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isSuspended ? AppColors.danger : AppColors.buyerAccent).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.storefront_outlined, color: isSuspended ? AppColors.danger : AppColors.buyerAccent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor["companyName"]?.toString() ?? "Vendor",
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isSuspended ? "SUSPENDED" : "Trust Score: ${vendor["reputationScore"] ?? 0}",
                        style: TextStyle(color: isSuspended ? AppColors.danger : AppColors.textSecondary, fontSize: 12.5, fontWeight: isSuspended ? FontWeight.bold : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                if (!isSuspended)
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCatalogList() {
    if (_catalogItems.isEmpty) {
      return const EmptyState(icon: Icons.inventory_2_outlined, title: "Empty Catalog", subtitle: "This vendor hasn't added any items yet.");
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _catalogItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _catalogItems[index];
        final price = (item["price"] ?? 0).toDouble();
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BuyerOrderEvaluateScreen(
                  vendorId: _selectedVendor!["_id"]?.toString() ?? "",
                  itemId: item["itemId"]?.toString() ?? "",
                  itemName: item["name"]?.toString() ?? "Item",
                  price: price,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.buyerAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.category_outlined, color: AppColors.buyerAccent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["name"]?.toString() ?? "Item",
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                      const SizedBox(height: 3),
                      Text("₹${price.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}