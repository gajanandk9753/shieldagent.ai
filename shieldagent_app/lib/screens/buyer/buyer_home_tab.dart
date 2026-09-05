import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/threat_log_store.dart';
import '../../widgets/common/dashboard_cards.dart';
import '../../widgets/common/donut_chart.dart';
import '../../widgets/common/primary_button.dart';
import '../shared/threat_log_screen.dart';

class BuyerHomeTab extends StatefulWidget {
  const BuyerHomeTab({super.key});

  @override
  State<BuyerHomeTab> createState() => _BuyerHomeTabState();
}

class _BuyerHomeTabState extends State<BuyerHomeTab> {
  bool _loading = true;
  bool _reactivating = false;
  String? _error;

  double _budgetLimit = 0;
  double _budgetSpent = 0;
  double _budgetRemainingPct = 0;
  String _riskStatus = "ACTIVE";
  int _flagCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    ThreatLogStore.instance.addListener(_onThreatLog);
  }

  @override
  void dispose() {
    ThreatLogStore.instance.removeListener(_onThreatLog);
    super.dispose();
  }

  void _onThreatLog() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final budgetRes = await ApiService.instance
          .get(ApiConstants.buyerBudget, auth: AuthMode.jwt);
      final riskRes = await ApiService.instance
          .get(ApiConstants.buyerDashboardRiskStatus, auth: AuthMode.jwt);

      setState(() {
        _budgetLimit = (budgetRes["budgetLimit"] ?? 0).toDouble();
        _budgetSpent = (budgetRes["budgetSpent"] ?? 0).toDouble();
        _budgetRemainingPct = (budgetRes["budgetRemainingPct"] ?? 0).toDouble();
        _riskStatus = riskRes["status"]?.toString() ?? "ACTIVE";
        _flagCount = (riskRes["flagCountInWindow"] ?? 0) as int;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't load dashboard. Pull to retry.");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _reactivate() async {
    final agentId = await StorageService.instance.getAgentId();
    if (agentId == null) return;

    setState(() => _reactivating = true);
    try {
      await ApiService.instance.post(
        ApiConstants.buyerReactivate(agentId),
        auth: AuthMode.jwt,
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _reactivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = ThreatLogStore.instance.events;
    final sybilEvents =
    allEvents.where((e) => e.type == ThreatType.sybilCollusion).toList();

    return RefreshIndicator(
      onRefresh: _load,
      backgroundColor: AppColors.surface,
      color: AppColors.buyerAccent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Command Center",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Autonomous Risk Telemetry",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.shield_moon_outlined,
                    color: AppColors.buyerAccent),
                tooltip: "Threat Log",
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ThreatLogScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.buyerAccent)),
            )
          else if (_error != null)
            EmptyState(
              icon: Icons.wifi_off_rounded,
              title: "Couldn't reach ShieldAgent",
              subtitle: _error!,
            )
          else ...[
              // ---- Circuit Breaker Banner ----
              _RiskBanner(status: _riskStatus, flagCount: _flagCount),
              if (_riskStatus.toUpperCase() == "SUSPENDED") ...[
                const SizedBox(height: 12),
                PrimaryButton(
                  label: "Review & Reactivate Agent",
                  isLoading: _reactivating,
                  color: AppColors.danger,
                  onPressed: _reactivate,
                ),
              ],

              const SizedBox(height: 16),

              // ---- System Health Matrix (New UI component) ----
              const _SecurityHealthGrid(),

              // ---- Sybil Shield warnings ----
              if (sybilEvents.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SybilCard(count: sybilEvents.length, latest: sybilEvents.first),
              ],

              const SizedBox(height: 20),

              // ---- Budget Telemetry Container ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Capital Utilization & Escrow",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DonutChart(
                      percentSpent: _budgetLimit > 0
                          ? (_budgetSpent / _budgetLimit) * 100
                          : 0,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: "Total Limit",
                            value: "₹${_budgetLimit.toStringAsFixed(0)}",
                          ),
                        ),
                        Container(
                            width: 1, height: 30, color: AppColors.surfaceBorder),
                        Expanded(
                          child: _MiniStat(
                            label: "Committed",
                            value: "₹${_budgetSpent.toStringAsFixed(0)}",
                          ),
                        ),
                        Container(
                            width: 1, height: 30, color: AppColors.surfaceBorder),
                        Expanded(
                          child: _MiniStat(
                            label: "Remaining",
                            value: "${_budgetRemainingPct.toStringAsFixed(0)}%",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---- Recent Live Threat Stream (New Section) ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Threat Stream",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ThreatLogScreen()),
                    ),
                    child: const Text("View All",
                        style: TextStyle(color: AppColors.buyerAccent, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (allEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: const Row(
                      children: [
                        Icon(Icons.security_rounded, color: AppColors.success, size: 20),
                        SizedBox(width: 12),
                        Text(
                          "No security anomalies intercepted this session.",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...allEvents.take(3).map((event) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: AppColors.danger, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            ],
        ],
      ),
    );
  }
}

class _SecurityHealthGrid extends StatelessWidget {
  const _SecurityHealthGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: AppColors.buyerAccent, size: 16),
                    SizedBox(width: 6),
                    Text("Deterministic",
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 8),
                Text("Active Engine",
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: AppColors.success, size: 16),
                    SizedBox(width: 6),
                    Text("Gemini 2.5",
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 8),
                Text("Context Guard",
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _SybilCard extends StatelessWidget {
  final int count;
  final ThreatEvent latest;
  const _SybilCard({required this.count, required this.latest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hub_outlined, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sybil Shield — $count collusion alert${count > 1 ? 's' : ''}",
                  style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Text(
                  latest.detail,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBanner extends StatelessWidget {
  final String status;
  final int flagCount;
  const _RiskBanner({required this.status, required this.flagCount});

  @override
  Widget build(BuildContext context) {
    final suspended = status.toUpperCase() == "SUSPENDED";
    final color = suspended ? AppColors.danger : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            suspended ? Icons.block_rounded : Icons.verified_user_rounded,
            color: color,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suspended ? "Agent Suspended" : "Agent Active",
                  style: TextStyle(
                      color: color, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  suspended
                      ? "3+ flagged decisions tripped the circuit breaker."
                      : "$flagCount flag(s) in the current rolling window.",
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}