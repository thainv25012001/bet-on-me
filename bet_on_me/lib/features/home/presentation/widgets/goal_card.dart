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
    final completed = tasks.where((t) => t.isComplete).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldDim,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completed/$total',
                  style: const TextStyle(
                    color: AppColors.gold,
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
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.gold),
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
