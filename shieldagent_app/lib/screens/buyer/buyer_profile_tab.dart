import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/primary_button.dart';
import '../onboarding/welcome_screen.dart';

class BuyerProfileTab extends StatefulWidget {
  const BuyerProfileTab({super.key});

  @override
  State<BuyerProfileTab> createState() => _BuyerProfileTabState();
}

class _BuyerProfileTabState extends State<BuyerProfileTab> {
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    StorageService.instance.getApiKey().then((v) => setState(() => _apiKey = v));
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
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
                  backgroundColor: AppColors.buyerAccent,
                  child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  auth.email ?? "Buyer Agent",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Buyer Agent",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                    "API Key (for procurebot.js)",
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
                        icon: const Icon(Icons.copy, color: AppColors.accent, size: 20),
                        tooltip: 'Copy API Key',
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: _apiKey!)); // Copies to clipboard
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('API Key copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
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