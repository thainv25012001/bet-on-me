import 'package:flutter/material.dart';
import 'package:bet_on_me/core/constants/app_status.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';

/// Returns a [BoxDecoration] styled for a task's status.
///
/// Pass [defaultColor] to control the neutral (pending) background;
/// defaults to [AppThemeColors.surface].
BoxDecoration taskStatusDecoration(
  String status,
  AppThemeColors c, {
  Color? defaultColor,
}) =>
    BoxDecoration(
      color: status == TaskStatus.success
          ? AppColors.successGreen.withAlpha(20)
          : status == TaskStatus.failed
              ? AppColors.nikeRed.withAlpha(15)
              : defaultColor ?? c.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: status == TaskStatus.success
            ? AppColors.successGreen.withAlpha(100)
            : status == TaskStatus.failed
                ? AppColors.nikeRed.withAlpha(80)
                : c.border,
      ),
    );

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
      initialChildSize: 0.75,
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
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.hoverGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${minutes}m',
                          style: TextStyle(
                            color: c.textMuted,
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
                  _SectionLabel(
                    icon: Icons.lightbulb_outline,
                    label: 'Why this matters',
                    color: c.text,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
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
                  _SectionLabel(
                    icon: Icons.route_outlined,
                    label: 'Step-by-step guide',
                    color: c.text,
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
                        backgroundColor: AppColors.successGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.white,
                      ),
                      label: const Text(
                        'Mark as done',
                        style: TextStyle(
                          color: AppColors.white,
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

// ── Task status icon ──────────────────────────────────────────────────────────

class TaskStatusIcon extends StatelessWidget {
  const TaskStatusIcon({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDone   = status == TaskStatus.success;
    final isFailed = status == TaskStatus.failed;
    final c = AppThemeColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? AppColors.successGreen
            : isFailed
                ? AppColors.nikeRed
                : Colors.transparent,
        border: Border.all(
          color: isDone
              ? AppColors.successGreen
              : isFailed
                  ? AppColors.nikeRed
                  : c.textMuted,
          width: 2,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check, color: AppColors.white, size: 13)
          : isFailed
              ? const Icon(Icons.close, color: AppColors.white, size: 13)
              : null,
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
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
              color: AppColors.hoverGray,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSecondary),
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: c.text,
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
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'e.g. ',
                          style: TextStyle(
                            color: c.textMuted,
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
