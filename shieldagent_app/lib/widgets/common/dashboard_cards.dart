import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A stat tile — e.g. "Budget Remaining: 82%".
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Small colored pill for statuses like AUTO_APPROVE / FROZEN / SUSPENDED.
class StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const StatusPill({super.key, required this.text, required this.color});

  /// Matches your actual enums:
  /// Evaluation.decision: AUTO_APPROVE | REQUIRES_PERMISSION | BLOCKED
  /// Transaction.state: ADVANCE_LOCKED | ADVANCE_RELEASED | BALANCE_RELEASED
  ///                    | FROZEN | CANCELLED
  /// Agent.status: ACTIVE | SUSPENDED
  factory StatusPill.forDecision(String decision) {
    switch (decision.toUpperCase()) {
      case "AUTO_APPROVE":
      case "ACTIVE":
      case "BALANCE_RELEASED": // fully settled — nothing left in escrow
        return StatusPill(text: decision, color: AppColors.success);
      case "REQUIRES_PERMISSION":
      case "ADVANCE_LOCKED": // in-flight, waiting on the next step
        return StatusPill(text: decision, color: AppColors.warning);
      case "ADVANCE_RELEASED": // advance out, balance still in escrow
        return StatusPill(text: decision, color: AppColors.info);
      case "BLOCKED":
      case "FROZEN":
      case "SUSPENDED":
      case "CANCELLED":
        return StatusPill(text: decision, color: AppColors.danger);
      default:
        return StatusPill(text: decision, color: AppColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Empty-state placeholder used across list tabs before real data loads.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
