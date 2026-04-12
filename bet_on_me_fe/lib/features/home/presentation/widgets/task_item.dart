import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';

class GoalTask {
  final String title;
  final bool isComplete;
  const GoalTask({required this.title, required this.isComplete});
}

class TaskItem extends StatelessWidget {
  final GoalTask task;
  const TaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            task.isComplete ? Icons.check_circle : Icons.cancel,
            color: task.isComplete
                ? AppColors.successGreen
                : AppColors.nikeRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                color: task.isComplete ? c.textMuted : c.text,
                fontSize: 13,
                decoration: task.isComplete
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: c.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
