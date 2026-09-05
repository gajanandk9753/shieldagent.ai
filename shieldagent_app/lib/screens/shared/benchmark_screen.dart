import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/dashboard_cards.dart';
import '../../widgets/common/primary_button.dart';

class _Scenario {
  final String type;
  final int qty;
  final double amount;
  final String expected;
  const _Scenario(this.type, this.qty, this.amount, this.expected);
}

class _ScenarioResult {
  final _Scenario scenario;
  final String actual;
  final int latencyMs;
  final bool correct;
  _ScenarioResult(this.scenario, this.actual, this.latencyMs, this.correct);
}

/// Same 6 scenarios as your standalone benchmark.js, run against the
/// live /orders/evaluate endpoint from inside the app — so judges watch
/// accuracy and latency appear on screen instead of reading a terminal.
class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  final _vendorIdController = TextEditingController();
  final _itemIdController = TextEditingController();

  bool _running = false;
  int _completed = 0;
  final List<_ScenarioResult> _results = [];

  static const _scenarios = [
    _Scenario("LEGITIMATE", 10, 500, "AUTO_APPROVE"),
    _Scenario("LEGITIMATE", 25, 1250, "AUTO_APPROVE"),
    _Scenario("HIGH_VOLUME", 150, 7500, "REQUIRES_PERMISSION"),
    _Scenario("BUDGET_BREACH", 10, 9999999, "BLOCKED"),
    _Scenario("PRICE_TAMPER", 10, 100, "BLOCKED"),
    _Scenario("LEGITIMATE", 5, 250, "AUTO_APPROVE"),
  ];

  @override
  void dispose() {
    _vendorIdController.dispose();
    _itemIdController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final vendorId = _vendorIdController.text.trim();
    final itemId = _itemIdController.text.trim();
    if (vendorId.isEmpty || itemId.isEmpty) return;

    setState(() {
      _running = true;
      _completed = 0;
      _results.clear();
    });

    for (final scenario in _scenarios) {
      final start = DateTime.now();
      String actual;
      try {
        final res = await ApiService.instance.post(
          ApiConstants.buyerEvaluate,
          body: {
            "vendorId": vendorId,
            "itemId": itemId,
            "quantity": scenario.qty,
            "expectedAmount": scenario.amount,
          },
          auth: AuthMode.apiKey,
        );
        actual = res["decision"]?.toString() ?? "BLOCKED";
      } catch (_) {
        actual = "BLOCKED";
      }
      final latency = DateTime.now().difference(start).inMilliseconds;

      // Same true/false positive logic as your Node benchmark: anything
      // that isn't AUTO_APPROVE counts as "flagged".
      final isFraudScenario = scenario.expected != "AUTO_APPROVE";
      final didFlag = actual != "AUTO_APPROVE";
      final correct = isFraudScenario == didFlag;

      setState(() {
        _results.add(_ScenarioResult(scenario, actual, latency, correct));
        _completed++;
      });

      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = _results.isEmpty
        ? 0.0
        : (_results.where((r) => r.correct).length / _results.length) * 100;
    final avgLatency = _results.isEmpty
        ? 0
        : _results.map((r) => r.latencyMs).reduce((a, b) => a + b) ~/
            _results.length;
    final falsePositives = _results
        .where((r) =>
            r.scenario.expected == "AUTO_APPROVE" && r.actual != "AUTO_APPROVE")
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Risk Engine Benchmark")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "Runs the same 6 scenarios as your benchmark.js — "
              "legitimate orders, a high-volume flag, a budget breach, and "
              "a tampered price — live against this build.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: "Vendor ID",
              controller: _vendorIdController,
              prefixIcon: Icons.storefront_outlined,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Item ID",
              controller: _itemIdController,
              prefixIcon: Icons.category_outlined,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: _running
                  ? "Running $_completed/${_scenarios.length}..."
                  : "Run Benchmark",
              isLoading: _running,
              color: AppColors.accent,
              onPressed: _run,
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: "Accuracy",
                      value: "${accuracy.toStringAsFixed(0)}%",
                      icon: Icons.gps_fixed_rounded,
                      accent: accuracy >= 80 ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: "Avg Latency",
                      value: "${avgLatency}ms",
                      icon: Icons.speed_rounded,
                      accent: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: "False Positives",
                      value: "$falsePositives",
                      icon: Icons.error_outline_rounded,
                      accent: falsePositives == 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ..._results.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: r.correct
                              ? AppColors.surfaceBorder
                              : AppColors.danger.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            r.correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: r.correct ? AppColors.success : AppColors.danger,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.scenario.type,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(
                                  "expected ${r.scenario.expected} · got ${r.actual}",
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          Text("${r.latencyMs}ms",
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
