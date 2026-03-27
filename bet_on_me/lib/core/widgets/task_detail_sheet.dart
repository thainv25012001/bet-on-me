import 'package:flutter/material.dart';
import 'package:bet_on_me/core/constants/app_status.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';

/// Draggable bottom sheet that shows full task detail — description,
/// "why this matters" explanation, step-by-step guide, and optional
/// "Mark as done" button.
///
/// [task] is a raw API map (keys: title, description, explanation,
/// guide, estimated_minutes, status).
/// Supply [onMarkDone] to show the action button; omit it for read-only.
class TaskDetailSheet extends StatelessWidget {
  const TaskDetailSheet({
    super.key,
    required this.task,
    this.onMarkDone,
  });

  final Map<String, dynamic> task;
  final VoidCallback? onMarkDone;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final title = task['title'] as String? ?? 'Task';
    final description = task['description'] as String?;
    final explanation = task['explanation'] as String?;
    final minutes = (task['estimated_minutes'] as num?)?.toInt();
    final status = task['status'] as String? ?? TaskStatus.pending;
    final isDone = status == TaskStatus.success;
    final rawGuide = task['guide'] as List<dynamic>? ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                // ── Header ─────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TaskStatusIcon(status: status),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isDone ? c.textMuted : c.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: c.textMuted,
                        ),
                      ),
                    ),
                    if (minutes != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldDim,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${minutes}m',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // ── Description ────────────────────────────────────────────
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      color: c.text.withAlpha(178),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],

                // ── Why this matters ───────────────────────────────────────
                if (explanation != null && explanation.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel(
                    icon: Icons.lightbulb_outline,
                    label: 'Why this matters',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.goldDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.gold.withAlpha(60)),
                    ),
                    child: Text(
                      explanation,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                // ── Step-by-step guide ─────────────────────────────────────
                if (rawGuide.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel(
                    icon: Icons.route_outlined,
                    label: 'Step-by-step guide',
                  ),
                  const SizedBox(height: 10),
                  ...rawGuide.map((s) {
                    final sm = s as Map<String, dynamic>;
                    return _GuideStepCard(
                      step: (sm['step'] as num?)?.toInt() ?? 0,
                      action: sm['action'] as String? ?? '',
                      example: sm['example'] as String?,
                    );
                  }),
                ],

                // ── Mark done button ───────────────────────────────────────
                if (onMarkDone != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        onMarkDone!();
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: const Text(
                        'Mark as done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task status icon (reusable across list cards and the detail sheet) ─────────

class TaskStatusIcon extends StatelessWidget {
  const TaskStatusIcon({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDone = status == TaskStatus.success;
    final isFailed = status == TaskStatus.failed;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? AppColors.success
            : isFailed
                ? AppColors.error
                : Colors.transparent,
        border: Border.all(
          color: isDone
              ? AppColors.success
              : isFailed
                  ? AppColors.error
                  : AppThemeColors.of(context).textMuted,
          width: 2,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check, color: Colors.white, size: 13)
          : isFailed
              ? const Icon(Icons.close, color: Colors.white, size: 13)
              : null,
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  const _GuideStepCard({
    required this.step,
    required this.action,
    this.example,
  });

  final int step;
  final String action;
  final String? example;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.goldDim,
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.gold.withAlpha(80)),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                if (example != null && example!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'e.g. ',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            example!,
                            style: TextStyle(
                              color: c.textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
