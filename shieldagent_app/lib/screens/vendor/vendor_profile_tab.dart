import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for Clipboard functionality
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/primary_button.dart';
import '../onboarding/welcome_screen.dart';

class VendorProfileTab extends StatefulWidget {
  const VendorProfileTab({super.key});

  @override
  State<VendorProfileTab> createState() => _VendorProfileTabState();
}

class _VendorProfileTabState extends State<VendorProfileTab> {
  String? _apiKey;
  String? _agentId;

  @override
  void initState() {
    super.initState();
    StorageService.instance.getApiKey().then((v) => setState(() => _apiKey = v));
    StorageService.instance.getAgentId().then((v) => setState(() => _agentId = v));
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
    );
  }

  // Helper method to copy text and show a snackbar
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Profile",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.vendorAccent,
                  child: Icon(Icons.storefront_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  auth.email ?? "Vendor Agent",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Vendor Agent",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_agentId != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Vendor ID (share with buyers)",
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _agentId!,
                          style: const TextStyle(
                            color: AppColors.vendorAccent,
                            fontSize: 13,
                            fontFamily: "monospace",
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.vendorAccent),
                        onPressed: () => _copyToClipboard(_agentId!, "Vendor ID"),
                        tooltip: 'Copy Vendor ID',
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_apiKey != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "API Key (for your vendor script)",
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _apiKey!,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontFamily: "monospace",
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.accent),
                        onPressed: () => _copyToClipboard(_apiKey!, "API Key"),
                        tooltip: 'Copy API Key',
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const Spacer(),
          PrimaryButton(
            label: "Log Out",
            outlined: true,
            onPressed: _logout,
          ),
        ],
      ),
    );
  }
}