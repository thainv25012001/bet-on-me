import 'package:flutter/material.dart';
import 'package:bet_on_me/core/constants/app_status.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'package:bet_on_me/core/widgets/app_dialog.dart';
import 'package:bet_on_me/core/widgets/task_detail_sheet.dart';
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
    this.status = TaskStatus.pending,
  });

  bool get isDone => status == TaskStatus.success;
  bool get isFailed => status == TaskStatus.failed;
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
  State<DailyTasksPage> createState() => DailyTasksPageState();
}

class DailyTasksPageState extends State<DailyTasksPage> {
  final _goalService = GoalService();

  List<_GoalDay> _goalDays = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void reload() => _load();

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
          status: t['status'] as String? ?? TaskStatus.pending,
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
    setState(() => task.status = TaskStatus.success);
    try {
      final result =
          await _goalService.updateTaskStatus(task.id, TaskStatus.success);
      final dayComplete = result['day_complete'] as bool? ?? false;
      final rewardMap = result['daily_reward'] as Map<String, dynamic>?;
      if (dayComplete && rewardMap != null && mounted) {
        _showDayCompleteSheet(
          rewardId: rewardMap['id'] as String,
          amount: (rewardMap['amount'] as num).toInt(),
        );
      }
    } catch (e) {
      setState(() => task.status = prev);
      if (mounted) {
        showErrorDialog(context, 'Could not update task. Please try again.');
      }
    }
  }

  void _showDayCompleteSheet({
    required String rewardId,
    required int amount,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.of(context).surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _DayCompleteSheet(
        rewardId: rewardId,
        amount: amount,
        goalService: _goalService,
      ),
    );
  }

  void _showTaskDetail(BuildContext context, _TaskItem task) {
    final c = AppThemeColors.of(context);
    final taskMap = <String, dynamic>{
      'title': task.title,
      'description': task.description,
      'explanation': task.explanation,
      'estimated_minutes': task.estimatedMinutes,
      'status': task.status,
      'guide': task.guide
          .map((s) => {
                'step': s.step,
                'action': s.action,
                'example': s.example,
              })
          .toList(),
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TaskDetailSheet(
        task: taskMap,
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
              child: TaskStatusIcon(status: task.status),
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

// ── Day complete / claim sheet ────────────────────────────────────────────────

class _DayCompleteSheet extends StatefulWidget {
  const _DayCompleteSheet({
    required this.rewardId,
    required this.amount,
    required this.goalService,
  });

  final String rewardId;
  final int amount;
  final GoalService goalService;

  @override
  State<_DayCompleteSheet> createState() => _DayCompleteSheetState();
}

class _DayCompleteSheetState extends State<_DayCompleteSheet> {
  bool _claiming = false;
  bool _claimed = false;

  Future<void> _claim() async {
    setState(() => _claiming = true);
    try {
      await widget.goalService.claimDailyReward(widget.rewardId);
      if (mounted) setState(() => _claimed = true);
    } catch (_) {
      if (mounted) {
        setState(() => _claiming = false);
        showErrorDialog(context, 'Could not claim reward. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Day Complete!',
              style: TextStyle(
                color: c.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You finished all tasks for today.',
              style: TextStyle(color: c.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.goldDim,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withAlpha(120)),
              ),
              child: Column(
                children: [
                  Text(
                    'Your stake for today',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${widget.amount}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'is yours to claim back',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _claimed
                  ? FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: const Text(
                        'Claimed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : FilledButton(
                      onPressed: _claiming ? null : _claim,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _claiming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Claim \$${widget.amount} back',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
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
