import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/dashboard_cards.dart';
import '../../widgets/common/primary_button.dart';

class BuyerOrderEvaluateScreen extends StatefulWidget {
  final String vendorId;
  final String itemId;
  final String itemName;
  final double price;

  const BuyerOrderEvaluateScreen({
    super.key,
    required this.vendorId,
    required this.itemId,
    required this.itemName,
    required this.price,
  });

  @override
  State<BuyerOrderEvaluateScreen> createState() =>
      _BuyerOrderEvaluateScreenState();
}

class _BuyerOrderEvaluateScreenState extends State<BuyerOrderEvaluateScreen> {
  final _quantityController = TextEditingController(text: "1");

  bool _evaluating = false;
  bool _placing = false;
  String? _error;

  // Result of /orders/evaluate
  Map<String, dynamic>? _evaluation;

  // Result of /orders (after placing)
  Map<String, dynamic>? _placedOrder;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double get _expectedAmount {
    final qty = int.tryParse(_quantityController.text.trim()) ?? 1;
    return widget.price * qty;
  }

  Future<void> _evaluate() async {
    final qty = int.tryParse(_quantityController.text.trim());
    if (qty == null || qty < 1) return;

    setState(() {
      _evaluating = true;
      _error = null;
      _evaluation = null;
      _placedOrder = null;
    });

    try {
      final res = await ApiService.instance.post(
        ApiConstants.buyerEvaluate,
        body: {
          "vendorId": widget.vendorId,
          "itemId": widget.itemId,
          "quantity": qty,
          "expectedAmount": _expectedAmount,
        },
        auth: AuthMode.apiKey,
      );
      setState(() => _evaluation = (res["data"] ?? res) as Map<String, dynamic>);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't reach the risk engine.");
    } finally {
      setState(() => _evaluating = false);
    }
  }

  Future<void> _placeOrder() async {
    final evaluationId = _evaluation?["evaluationId"]?.toString();
    if (evaluationId == null) return;

    setState(() {
      _placing = true;
      _error = null;
    });

    try {
      // placeOrder expects { evaluationId, totalAmount } — not quantity —
      // and only ever succeeds if the evaluation's decision was
      // AUTO_APPROVE, so the button above is disabled otherwise.
      final res = await ApiService.instance.post(
        ApiConstants.buyerPlaceOrder,
        body: {"evaluationId": evaluationId, "totalAmount": _expectedAmount},
        auth: AuthMode.apiKey,
      );
      setState(() => _placedOrder = res);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't place the order.");
    } finally {
      setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decision = _evaluation?["decision"]?.toString();
    // Your placeOrder controller only accepts AUTO_APPROVE evaluations —
    // REQUIRES_PERMISSION and BLOCKED both 403 there — so only enable
    // the button for the one decision that will actually go through.
    final canPlace = decision == "AUTO_APPROVE";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.itemName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                      child: const Icon(Icons.category_outlined,
                          color: AppColors.buyerAccent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.itemName,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.5)),
                          const SizedBox(height: 3),
                          Text("₹${widget.price.toStringAsFixed(0)} / unit",
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: "Quantity",
                controller: _quantityController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.numbers_rounded,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Total: ₹${_expectedAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: "Is this safe?",
                isLoading: _evaluating,
                color: AppColors.buyerAccent,
                onPressed: _placedOrder != null ? null : _evaluate,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 12.5)),
              ],
              if (_evaluation != null) ...[
                const SizedBox(height: 24),
                _EvaluationResult(evaluation: _evaluation!),
                const SizedBox(height: 20),
                if (_placedOrder == null)
                  PrimaryButton(
                    label: canPlace
                        ? "Place Order"
                        : decision == "REQUIRES_PERMISSION"
                            ? "Needs reviewer approval first"
                            : "Blocked — can't place order",
                    isLoading: _placing,
                    color: AppColors.success,
                    onPressed: canPlace ? _placeOrder : null,
                  ),
              ],
              if (_placedOrder != null) ...[
                const SizedBox(height: 20),
                _OrderPlacedCard(order: _placedOrder!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EvaluationResult extends StatelessWidget {
  final Map<String, dynamic> evaluation;
  const _EvaluationResult({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final decision = evaluation["decision"]?.toString() ?? "-";
    final riskScore = evaluation["riskScore"];
    final escrowPlan = evaluation["escrowPlan"] as Map<String, dynamic>?;
    final reasons = (evaluation["reasons"] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Decision",
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5)),
              const Spacer(),
              StatusPill.forDecision(decision),
            ],
          ),
          if (riskScore != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Text("Risk score",
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5)),
                const Spacer(),
                Text("$riskScore / 100",
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ],
          if (escrowPlan != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Text("Escrow plan",
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5)),
                const Spacer(),
                Text(
                  "${escrowPlan["advancePct"]}% advance · "
                  "${escrowPlan["tranches"]} tranches",
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ],
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const Text("Why",
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    "•  $r",
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _OrderPlacedCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderPlacedCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final state = order["state"]?.toString() ?? "ADVANCE_LOCKED";
    final txnId = order["transactionId"]?.toString() ?? "";
    final advance = order["advanceAmount"];
    final balance = order["balanceAmount"];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Order placed — advance locked",
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      txnId,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text("Advance locked",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              const Spacer(),
              Text("₹$advance",
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text("Balance in escrow",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              const Spacer(),
              Text("₹$balance",
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text("State",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              const Spacer(),
              StatusPill.forDecision(state),
            ],
          ),
        ],
      ),
    );
  }
}
