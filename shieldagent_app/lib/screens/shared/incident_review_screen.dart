import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/dashboard_cards.dart';
import '../../widgets/common/primary_button.dart';

class IncidentReviewScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const IncidentReviewScreen({super.key, required this.order});

  @override
  State<IncidentReviewScreen> createState() => _IncidentReviewScreenState();
}

class _IncidentReviewScreenState extends State<IncidentReviewScreen> {
  late Map<String, dynamic> _order = widget.order;
  bool _refreshing = false;

  String get _id => _order["_id"]?.toString() ?? "";

  Future<void> _refreshStatus() async {
    setState(() => _refreshing = true);
    try {
      final role = await StorageService.instance.getRole();
      final res = role == AgentRole.vendor
          ? await ApiService.instance
              .get(ApiConstants.vendorOrderStatus(_id), auth: AuthMode.apiKey)
          : await ApiService.instance
              .get(ApiConstants.buyerOrderStatus(_id), auth: AuthMode.apiKey);
      setState(() => _order = {..._order, ...res});
    } catch (_) {
      // keep showing what we already had
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_id.isEmpty ? "Incident" : "#${_id.substring(_id.length - 6)}"),
          actions: [
            IconButton(
              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              onPressed: _refreshing ? null : _refreshStatus,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: "AI Reasoning"),
              Tab(text: "Escrow Tracker"),
              Tab(text: "Visual Proof"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AiReasoningTab(order: _order),
            _EscrowTrackerTab(order: _order),
            _VisualProofTab(
              order: _order,
              onVerified: (updated) {
                setState(() => _order = {..._order, ...updated});
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// TAB 1 — AI Reasoning
// ---------------------------------------------------------------------
class _AiReasoningTab extends StatelessWidget {
  final Map<String, dynamic> order;
  const _AiReasoningTab({required this.order});

  @override
  Widget build(BuildContext context) {
    final decision = order["decision"]?.toString();
    final riskScore = order["riskScore"];
    final aiReasoning = order["aiReasoning"]?.toString();
    final checks = order["checks"] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
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
                    const Text("Decision",
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11.5)),
                    const SizedBox(height: 8),
                    decision != null
                        ? StatusPill.forDecision(decision)
                        : const Text("—",
                            style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                    const Text("Risk Score",
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11.5)),
                    const SizedBox(height: 8),
                    Text(
                      riskScore != null ? "$riskScore / 100" : "—",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Deterministic checklist — only renders if the backend actually
        // sends a `checks` object (it doesn't yet; see backend-gaps note).
        if (checks != null) ...[
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
                const Text("Deterministic Checks",
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...checks.entries.map((e) => _CheckRow(
                      label: e.key,
                      passed: e.value.toString().toUpperCase() == "PASS",
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // The Gemini contextual reasoning string.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.12),
                AppColors.accent.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: AppColors.accent, size: 18),
                  SizedBox(width: 8),
                  Text("Gemini Context Check",
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                aiReasoning ??
                    "Not available yet — evaluateOrder computes this but "
                    "doesn't return or persist it. Add `aiReasoning` to the "
                    "response and the Evaluation schema to light this up.",
                style: TextStyle(
                  color: aiReasoning != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 13,
                  height: 1.5,
                  fontStyle:
                      aiReasoning != null ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool passed;
  const _CheckRow({required this.label, required this.passed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: passed ? AppColors.success : AppColors.danger,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13)),
          const Spacer(),
          Text(passed ? "Pass" : "Fail",
              style: TextStyle(
                  color: passed ? AppColors.success : AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// TAB 2 — Adaptive Escrow Tracker
// ---------------------------------------------------------------------
class _EscrowTrackerTab extends StatelessWidget {
  final Map<String, dynamic> order;
  const _EscrowTrackerTab({required this.order});

  @override
  Widget build(BuildContext context) {
    final tranches = order["tranches"] as List<dynamic>?;
    final state = order["state"]?.toString() ?? "ADVANCE_LOCKED";

    // Adaptive path: real tranche array from the backend (once claimTranche
    // + the schema fields exist).
    if (tranches != null && tranches.isNotEmpty) {
      final steps = tranches.map((t) {
        final m = t as Map<String, dynamic>;
        final released = m["status"]?.toString() == "RELEASED";
        return Step(
          title: Text(m["milestone"]?.toString() ?? "Milestone",
              style: const TextStyle(color: AppColors.textPrimary)),
          content: Text("₹${m["amount"] ?? '-'}",
              style: const TextStyle(color: AppColors.textSecondary)),
          isActive: true,
          state: released ? StepState.complete : StepState.indexed,
        );
      }).toList();

      final firstPending =
          steps.indexWhere((s) => s.state != StepState.complete);

      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.buyerAccent),
        ),
        child: Stepper(
          currentStep:
              firstPending == -1 ? steps.length - 1 : firstPending,
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: steps,
        ),
      );
    }

    // Fallback path: today's actual 2-stage flow, derived from `state`.
    final advanceDone = ["ADVANCE_RELEASED", "BALANCE_RELEASED"].contains(state);
    final balanceDone = state == "BALANCE_RELEASED";
    final frozen = state == "FROZEN" || state == "CANCELLED";

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "No adaptive tranche data on this transaction yet — showing "
            "the standard advance/balance flow instead.",
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: AppColors.buyerAccent),
          ),
          child: Stepper(
            currentStep: frozen ? 0 : (balanceDone ? 1 : (advanceDone ? 1 : 0)),
            controlsBuilder: (context, details) => const SizedBox.shrink(),
            steps: [
              Step(
                title: const Text("Advance",
                    style: TextStyle(color: AppColors.textPrimary)),
                content: Text("₹${order["advanceAmount"] ?? '-'} locked & released",
                    style: const TextStyle(color: AppColors.textSecondary)),
                isActive: true,
                state: advanceDone ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text("Balance",
                    style: TextStyle(color: AppColors.textPrimary)),
                content: Text("₹${order["balanceAmount"] ?? '-'} released on delivery",
                    style: const TextStyle(color: AppColors.textSecondary)),
                isActive: advanceDone,
                state: balanceDone ? StepState.complete : StepState.indexed,
              ),
            ],
          ),
        ),
        if (frozen)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              "This transaction is frozen — funds stay locked until a "
              "human reviewer resolves it.",
              style: TextStyle(color: AppColors.danger, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// TAB 3 — Visual Proof (waybill upload + Gemini OCR result)
// ---------------------------------------------------------------------
class _VisualProofTab extends StatefulWidget {
  final Map<String, dynamic> order;
  final void Function(Map<String, dynamic>) onVerified;
  const _VisualProofTab({required this.order, required this.onVerified});

  @override
  State<_VisualProofTab> createState() => _VisualProofTabState();
}

class _VisualProofTabState extends State<_VisualProofTab> {
  XFile? _picked;
  bool _uploading = false;
  String? _error;
  Map<String, dynamic>? _extracted;

  Future<void> _pickAndVerify() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;

    setState(() {
      _picked = file;
      _uploading = true;
      _error = null;
      _extracted = null;
    });

    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final id = widget.order["_id"]?.toString() ?? "";

      final res = await ApiService.instance.post(
        ApiConstants.vendorVerifyWaybill(id),
        body: {"imageBase64": base64Image, "mimeType": "image/jpeg"},
        auth: AuthMode.apiKey,
      );

      setState(() => _extracted = res["extractedData"] as Map<String, dynamic>?);
      widget.onVerified(res);
    } on ApiException catch (e) {
      // A failed verification still returns extractedData — show it even
      // though the transaction just got frozen.
      final data = e.body?["extractedData"] as Map<String, dynamic>?;
      setState(() {
        _error = e.message;
        _extracted = data;
      });
      if (e.body?["newState"] != null) {
        widget.onVerified({"state": e.body!["newState"]});
      }
    } catch (_) {
      setState(() => _error = "Couldn't verify the waybill.");
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: StorageService.instance.getRole(),
      builder: (context, snapshot) {
        final isVendor = snapshot.data == AgentRole.vendor;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!isVendor)
              const EmptyState(
                icon: Icons.local_shipping_outlined,
                title: "Waiting on the vendor",
                subtitle: "Only the vendor agent can upload dispatch proof — "
                    "you'll see it here once they do.",
              )
            else ...[
              if (_picked != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_picked!.path),
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.textMuted),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: "Upload Waybill",
                isLoading: _uploading,
                color: AppColors.vendorAccent,
                onPressed: _pickAndVerify,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ],
              if (_extracted != null) ...[
                const SizedBox(height: 20),
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
                      const Text("Gemini OCR Extraction",
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      ..._extracted!.entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Text(e.key,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12)),
                                ),
                                Expanded(
                                  child: Text("${e.value}",
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12.5)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
