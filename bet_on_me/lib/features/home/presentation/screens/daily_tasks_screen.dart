import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'package:bet_on_me/features/goals/data/goal_service.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _GuideStep {
  final int step;
  final String action;
  final String? example;

  const _GuideStep({
    required this.step,
    required this.action,
    this.example,
  });

  factory _GuideStep.fromMap(Map<String, dynamic> m) => _GuideStep(
        step: (m['step'] as num?)?.toInt() ?? 0,
        action: m['action'] as String? ?? '',
        example: m['example'] as String?,
      );
}

class _TaskItem {
  final String id;
  final String title;
  final String? description;
  final String? explanation;
  final List<_GuideStep> guide;
  final int? estimatedMinutes;
  String status;

  _TaskItem({
    required this.id,
    required this.title,
    this.description,
    this.explanation,
    this.guide = const [],
    this.estimatedMinutes,
    this.status = 'pending',
  });

  bool get isDone => status == 'success';
  bool get isFailed => status == 'failed';
}

class _GoalDay {
  final String goalId;
  final String goalTitle;
  final int dayNumber;
  final int totalDays;
  final List<_TaskItem> tasks;

  _GoalDay({
    required this.goalId,
    required this.goalTitle,
    required this.dayNumber,
    required this.totalDays,
    required this.tasks,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  final _goalService = GoalService();

  List<_GoalDay> _goalDays = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rawTasks = await _goalService.getTodayTasks();
      final Map<String, _GoalDay> byGoal = {};
      for (final t in rawTasks) {
        final goalId = t['goal_id'] as String;
        byGoal.putIfAbsent(
          goalId,
          () => _GoalDay(
            goalId: goalId,
            goalTitle: t['goal_title'] as String,
            dayNumber: (t['day_number'] as num?)?.toInt() ?? 0,
            totalDays: (t['total_days'] as num?)?.toInt() ?? 0,
            tasks: [],
          ),
        );
        final rawGuide = t['guide'] as List<dynamic>? ?? [];
        byGoal[goalId]!.tasks.add(_TaskItem(
          id: t['id'] as String,
          title: t['title'] as String? ?? 'Task',
          description: t['description'] as String?,
          explanation: t['explanation'] as String?,
          guide: rawGuide
              .map((s) => _GuideStep.fromMap(s as Map<String, dynamic>))
              .toList(),
          estimatedMinutes: (t['estimated_minutes'] as num?)?.toInt(),
          status: t['status'] as String? ?? 'pending',
        ));
      }
      setState(() {
        _goalDays = byGoal.values.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleTask(_TaskItem task) async {
    if (task.isDone) return;
    final prev = task.status;
    setState(() => task.status = 'success');
    try {
      await _goalService.updateTaskStatus(task.id, 'success');
    } catch (e) {
      setState(() => task.status = prev);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showTaskDetail(BuildContext context, _TaskItem task) {
    final c = AppThemeColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TaskDetailSheet(
        task: task,
        onMarkDone: task.isDone ? null : () => _toggleTask(task),
      ),
    );
  }

  int get _totalTasks => _goalDays.fold(0, (s, g) => s + g.tasks.length);
  int get _doneTasks =>
      _goalDays.fold(0, (s, g) => s + g.tasks.where((t) => t.isDone).length);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_error != null) return _ErrorState(onRetry: _load);
    if (_goalDays.isEmpty) return const _EmptyState();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.gold,
      backgroundColor: AppThemeColors.of(context).surface,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _DailyHeader()),
          SliverToBoxAdapter(
            child: _SummaryCard(
              total: _totalTasks,
              done: _doneTasks,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _GoalSection(
                goalDay: _goalDays[i],
                onTaskTap: (task) => _showTaskDetail(context, task),
                onTaskToggle: _toggleTask,
              ),
              childCount: _goalDays.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Daily header ──────────────────────────────────────────────────────────────

class _DailyHeader extends StatelessWidget {
  const _DailyHeader();

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
            style: TextStyle(
              color: c.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Today's Tasks",
            style: TextStyle(
              color: c.text,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    final allDone = total > 0 && done == total;

    final String message;
    if (allDone) {
      message = 'You crushed it today! 🎉';
    } else if (done == 0) {
      message = "Let's crush it today — start your first task!";
    } else if (progress >= 0.5) {
      message = 'More than halfway — keep going! 💪';
    } else {
      message = 'Great start! Momentum is everything.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allDone ? AppColors.successDim : AppColors.goldDim,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: allDone ? AppColors.success : AppColors.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(allDone ? '🎉' : '⚡',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: allDone ? AppColors.success : AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$done / $total',
                style: TextStyle(
                  color: allDone ? AppColors.success : AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppThemeColors.of(context).border,
                valueColor: AlwaysStoppedAnimation<Color>(
                    allDone ? AppColors.success : AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Goal section ──────────────────────────────────────────────────────────────

class _GoalSection extends StatelessWidget {
  const _GoalSection({
    required this.goalDay,
    required this.onTaskTap,
    required this.onTaskToggle,
  });

  final _GoalDay goalDay;
  final void Function(_TaskItem) onTaskTap;
  final void Function(_TaskItem) onTaskToggle;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final done = goalDay.tasks.where((t) => t.isDone).length;
    final total = goalDay.tasks.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goalDay.goalTitle,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: Text(
                  'Day ${goalDay.dayNumber} / ${goalDay.totalDays}',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: c.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 10),
          ...goalDay.tasks.map(
            (task) => _TaskCard(
              task: task,
              onTap: () => onTaskTap(task),
              onToggle: () => onTaskToggle(task),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  final _TaskItem task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: task.isDone
              ? AppColors.successDim
              : task.isFailed
                  ? const Color(0x22EF4444)
                  : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: task.isDone
                ? AppColors.success
                : task.isFailed
                    ? AppColors.error
                    : c.border,
          ),
          boxShadow: (c.isDark || task.isDone || task.isFailed)
              ? null
              : [
                  BoxShadow(
                    color: c.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onToggle,
              child: _StatusIcon(status: task.status),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: task.isDone
                          ? c.textMuted
                          : task.isFailed
                              ? AppColors.error
                              : c.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: c.textMuted,
                    ),
                  ),
                  if (task.explanation != null &&
                      task.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.explanation!,
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (task.estimatedMinutes != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: task.isDone
                          ? Colors.transparent
                          : AppColors.goldDim,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${task.estimatedMinutes}m',
                      style: TextStyle(
                        color: task.isDone
                            ? c.textMuted
                            : AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (task.guide.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.list_alt_outlined,
                          color: c.textMuted, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'Guide',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.goldDim,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.task_alt_outlined,
                  color: AppColors.gold, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Nothing scheduled today',
              style: TextStyle(
                  color: c.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a goal and let AI plan your daily tasks — '
              'then come back here each day to check them off.',
              style: TextStyle(
                  color: c.textMuted, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, color: c.textMuted, size: 48),
          const SizedBox(height: 16),
          Text('Could not load tasks',
              style: TextStyle(color: c.text, fontSize: 16)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

// ── Task detail bottom sheet ──────────────────────────────────────────────────

class _TaskDetailSheet extends StatelessWidget {
  final _TaskItem task;
  final VoidCallback? onMarkDone;

  const _TaskDetailSheet({required this.task, this.onMarkDone});

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
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
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusIcon(status: task.status),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: task.isDone ? c.textMuted : c.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: c.textMuted,
                        ),
                      ),
                    ),
                    if (task.estimatedMinutes != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldDim,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${task.estimatedMinutes}m',
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

                // Description
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    task.description!,
                    style: TextStyle(
                      color: c.text.withAlpha(178),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],

                // Explanation
                if (task.explanation != null &&
                    task.explanation!.isNotEmpty) ...[
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
                      task.explanation!,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                // Guide
                if (task.guide.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel(
                    icon: Icons.route_outlined,
                    label: 'Step-by-step guide',
                  ),
                  const SizedBox(height: 10),
                  ...task.guide.map((s) => _GuideStepCard(step: s)),
                ],

                // Mark done button
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

// ── Guide step card ───────────────────────────────────────────────────────────

class _GuideStepCard extends StatelessWidget {
  final _GuideStep step;
  const _GuideStepCard({required this.step});

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
              border: Border.all(color: AppColors.gold.withAlpha(80)),
            ),
            child: Center(
              child: Text(
                '${step.step}',
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
                  step.action,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                if (step.example != null && step.example!.isNotEmpty) ...[
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
                            step.example!,
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

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

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

class _StatusIcon extends StatelessWidget {
  final String status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'success';
    final isFailed = status == 'failed';
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
