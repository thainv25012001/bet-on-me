import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'task_item.dart';

class GoalCard extends StatelessWidget {
  final String emoji;
  final String title;
  final List<GoalTask> tasks;

  const GoalCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final completed = tasks.where((t) => t.isComplete).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Streak-orange badge — the gamification "product color"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.hoverGray,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$completed/$total',
                  style: const TextStyle(
                    color: AppColors.streakOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: c.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.streakOrange,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Task list
          ...tasks.map((task) => TaskItem(task: task)),
        ],
      ),
    );
  }
}
