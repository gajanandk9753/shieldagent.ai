import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/threat_log_store.dart';
import '../../widgets/common/dashboard_cards.dart';

class ThreatLogScreen extends StatefulWidget {
  const ThreatLogScreen({super.key});

  @override
  State<ThreatLogScreen> createState() => _ThreatLogScreenState();
}

class _ThreatLogScreenState extends State<ThreatLogScreen> {
  @override
  void initState() {
    super.initState();
    ThreatLogStore.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    ThreatLogStore.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final events = ThreatLogStore.instance.events;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Adversarial Threat Log")),
      body: SafeArea(
        child: events.isEmpty
            ? const EmptyState(
                icon: Icons.security_outlined,
                title: "No threats caught yet",
                subtitle:
                    "Try submitting a catalog item with a prompt-injection "
                    "payload, or trigger a Sybil collusion pattern — "
                    "anything ShieldAgent's AI firewall blocks shows up here.",
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ThreatTile(event: events[index]),
              ),
      ),
    );
  }
}

class _ThreatTile extends StatelessWidget {
  final ThreatEvent event;
  const _ThreatTile({required this.event});

  String get _typeLabel {
    switch (event.type) {
      case ThreatType.promptInjection:
        return "Prompt Injection";
      case ThreatType.sybilCollusion:
        return "Sybil Collusion";
      case ThreatType.priceFreeze:
        return "Price Tamper";
    }
  }

  IconData get _icon {
    switch (event.type) {
      case ThreatType.promptInjection:
        return Icons.terminal_rounded;
      case ThreatType.sybilCollusion:
        return Icons.hub_outlined;
      case ThreatType.priceFreeze:
        return Icons.price_change_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              StatusPill(text: _typeLabel, color: AppColors.danger),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              event.detail,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontFamily: "monospace",
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat("MMM d, h:mm:ss a").format(event.at),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
