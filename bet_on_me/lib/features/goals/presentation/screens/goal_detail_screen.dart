import 'package:flutter/material.dart';
import 'package:bet_on_me/core/constants/app_status.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'package:bet_on_me/core/widgets/app_dialog.dart';
import 'package:bet_on_me/core/widgets/task_detail_sheet.dart';
import 'package:bet_on_me/features/goals/data/goal_service.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({
    super.key,
    required this.goalId,
    required this.goalTitle,
    this.startDate,
    this.goalStatus,
  });

  final String goalId;
  final String goalTitle;
  final String? startDate;
  final String? goalStatus;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final _goalService = GoalService();
  bool _loading = true;
  bool _deleting = false;
  bool _unlocking = false;
  String? _error;
  int _totalDays = 0;
  String? _overview;
  double? _hoursPerDay;
  List<Map<String, dynamic>> _tasks = [];
  int _todayDayNumber = 0;
  String? _currentStatus;
  Map<String, dynamic>? _commitment;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.goalStatus;
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final futures = <Future>[
        _goalService.getGoalPlan(widget.goalId),
        if (_currentStatus == GoalStatus.locked)
          _goalService.getCommitment(widget.goalId),
      ];
      final results = await Future.wait(futures);
      final plan = results[0] as Map<String, dynamic>;
      final rawTasks = plan['tasks'] as List<dynamic>? ?? [];
      final totalDays = (plan['total_days'] as num?)?.toInt() ?? 0;
      setState(() {
        _totalDays = totalDays;
        _overview = plan['overview'] as String?;
        _hoursPerDay = (plan['hours_per_day'] as num?)?.toDouble();
        _tasks = rawTasks.cast<Map<String, dynamic>>();
        if (results.length > 1) {
          _commitment = results[1] as Map<String, dynamic>;
        }
        _loading = false;
      });
      _setTodayDay(widget.startDate);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _unlock() async {
    final totalCommitted =
        (_commitment?['total_committed'] as num?)?.toInt() ?? 0;
    final amountPerDay =
        (_commitment?['amount_per_day'] as num?)?.toInt() ?? 0;
    final planDays =
        (_commitment?['plan_total_days'] as num?)?.toInt() ?? _totalDays;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final c = AppThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Confirm Commitment',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.text,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CommitRow(
                label: 'Plan duration',
                value: '$planDays days',
                colors: c,
              ),
              const SizedBox(height: 10),
              _CommitRow(
                label: 'Daily stake',
                value: '\$$amountPerDay / day',
                colors: c,
              ),
              Divider(color: c.border, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total to commit',
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '\$$totalCommitted',
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You get this back when you complete all daily tasks.',
                style: TextStyle(
                  color: c.textMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textMuted,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.isDark ? AppColors.white : AppColors.nikeBlack,
                      foregroundColor: c.isDark ? AppColors.nikeBlack : AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Commit',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _unlocking = true);
    try {
      await _goalService.unlockGoal(widget.goalId);
      if (!mounted) return;
      Navigator.pop(context, 'unlocked');
    } catch (e) {
      if (!mounted) return;
      setState(() => _unlocking = false);
      showErrorDialog(context, 'Could not unlock goal. Please try again.');
    }
  }

  void _setTodayDay(String? startDateStr) {
    if (startDateStr == null) return;
    try {
      final start = DateTime.parse(startDateStr);
      final day = DateTime.now().difference(start).inDays + 1;
      _todayDayNumber = day.clamp(0, _totalDays);
    } catch (_) {}
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete goal?',
          style: TextStyle(
            color: AppThemeColors.of(ctx).text,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete the goal, its plan, '
          'all tasks and check-ins. This cannot be undone.',
          style: TextStyle(
            color: AppThemeColors.of(ctx).textMuted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppThemeColors.of(ctx).textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.nikeRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await _goalService.deleteGoal(widget.goalId);
      if (mounted) Navigator.pop(context, 'deleted');
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        showErrorDialog(context, 'Could not delete goal. Please try again.');
      }
    }
  }

  void _openTaskDetail(BuildContext context, Map<String, dynamic> task) {
    final c = AppThemeColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TaskDetailSheet(task: task),
    );
  }

  List<Map<String, dynamic>> _tasksForDay(int day) => _tasks
      .where((t) => (t['day_number'] as num?)?.toInt() == day)
      .toList();

  /// Returns 'success', 'failed', or 'empty' for a past day.
  String _pastDayStatus(int day) {
    final dayTasks = _tasksForDay(day);
    if (dayTasks.isEmpty) return 'empty';
    final allDone =
        dayTasks.every((t) => (t['status'] as String?) == TaskStatus.success);
    return allDone ? TaskStatus.success : TaskStatus.failed;
  }

  void _showDayTasks(BuildContext context, int dayNumber) {
    final c = AppThemeColors.of(context);
    final dayTasks = _tasksForDay(dayNumber);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Day $dayNumber',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (dayNumber == _todayDayNumber) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.streakOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${dayTasks.length} task${dayTasks.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: c.border, height: 1),
            Expanded(
              child: dayTasks.isEmpty
                  ? Center(
                      child: Text(
                        'Rest day — no tasks',
                        style: TextStyle(color: c.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      itemCount: dayTasks.length,
                      itemBuilder: (ctx, i) => _DayTaskCard(
                        task: dayTasks[i],
                        onTap: () => _openTaskDetail(
                            ctx, dayTasks[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.goalTitle,
          style: TextStyle(
            color: c.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_deleting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.nikeRed,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.nikeRed,
              ),
              tooltip: 'Delete goal',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: c.isDark ? AppColors.white : AppColors.nikeBlack,
              ),
            )
          : _currentStatus == GoalStatus.draft
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Your plan is being generated…\nCheck back soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                )
              : (_error != null || _totalDays == 0)
                  ? Center(
                      child: Text(
                        'No plan found for this goal.',
                        style: TextStyle(color: c.textMuted),
                      ),
                    )
                  : _buildPlanView(c),
    );
  }

  Widget _buildPlanView(AppThemeColors c) {
    final isLocked = _currentStatus == GoalStatus.locked;
    final progress =
        _todayDayNumber > 0 ? (_todayDayNumber - 1) / _totalDays : 0.0;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _totalDays + (isLocked ? 2 : 1),
      itemBuilder: (context, index) {
        if (isLocked && index == 0) return _buildUnlockCard(c);
        final adjustedIndex = isLocked ? index - 1 : index;
        if (adjustedIndex == 0) return _buildHeader(c, progress);
        final dayTasks = _tasksForDay(adjustedIndex);
        final execDate = dayTasks.isNotEmpty
            ? dayTasks.first['execution_date'] as String?
            : null;
        return _DayRow(
          day: adjustedIndex,
          todayDayNumber: _todayDayNumber,
          executionDate: execDate,
          tasksPreview: _buildDayPreview(adjustedIndex),
          pastStatus: adjustedIndex < _todayDayNumber
              ? _pastDayStatus(adjustedIndex)
              : '',
          onTap: () => _showDayTasks(context, adjustedIndex),
        );
      },
    );
  }

  String _buildDayPreview(int day) {
    final dayTasks = _tasksForDay(day);
    if (dayTasks.isEmpty) return 'Rest day';
    if (dayTasks.length == 1) {
      return dayTasks.first['title'] as String? ?? 'Task';
    }
    return '${dayTasks.length} tasks';
  }

  Widget _buildUnlockCard(AppThemeColors c) {
    final totalCommitted =
        (_commitment?['total_committed'] as num?)?.toInt() ?? 0;
    final amountPerDay =
        (_commitment?['amount_per_day'] as num?)?.toInt() ?? 0;
    final planDays =
        (_commitment?['plan_total_days'] as num?)?.toInt() ?? _totalDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: c.text, size: 18),
              const SizedBox(width: 8),
              Text(
                'Goal Locked',
                style: TextStyle(
                  color: c.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Commit \$$totalCommitted to unlock this goal.\n'
            '\$$amountPerDay/day × $planDays days.',
            style: TextStyle(
              color: c.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _unlocking ? null : _unlock,
              style: FilledButton.styleFrom(
                backgroundColor: c.isDark ? AppColors.white : AppColors.nikeBlack,
                foregroundColor: c.isDark ? AppColors.nikeBlack : AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _unlocking
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: c.isDark ? AppColors.nikeBlack : AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Commit & Unlock',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeColors c, double progress) {
    final hasOverview = _overview != null && _overview!.isNotEmpty;
    final hasHours = _hoursPerDay != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _todayDayNumber > 0
                        ? 'Day $_todayDayNumber of $_totalDays'
                        : '$_totalDays days total',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasHours)
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: AppColors.streakOrange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_hoursPerDay!.toStringAsFixed(_hoursPerDay! % 1 == 0 ? 0 : 1)} hrs/day',
                          style: const TextStyle(
                            color: AppColors.streakOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: progress.clamp(0.0, 1.0),
                  ),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (_, value, _) =>
                      LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: c.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                            AppColors.streakOrange),
                  ),
                ),
              ),
              if (_todayDayNumber > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${((progress) * 100).round()}% complete',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Overview card
        if (hasOverview)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: c.textMuted,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PLAN OVERVIEW',
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _overview!,
                  style: TextStyle(
                    color: c.text.withAlpha(200),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Commit Row ───────────────────────────────────────────────────────────────

class _CommitRow extends StatelessWidget {
  const _CommitRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Day Row ───────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.todayDayNumber,
    required this.executionDate,
    required this.tasksPreview,
    required this.pastStatus,
    required this.onTap,
  });

  final int day;
  final int todayDayNumber;
  final String? executionDate;
  final String tasksPreview;
  final String pastStatus;
  final VoidCallback onTap;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String? _formatDate(String? raw) {
    if (raw == null) return null;
    try {
      final d = DateTime.parse(raw);
      return '${_months[d.month - 1]} ${d.day}';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final isToday = day == todayDayNumber;
    final isPast = day < todayDayNumber;
    final isPastDone = pastStatus == TaskStatus.success;
    final isPastMissed = pastStatus == TaskStatus.failed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.streakOrange.withAlpha(15)
              : isPastMissed
                  ? AppColors.nikeRed.withAlpha(12)
                  : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday
                ? AppColors.streakOrange.withAlpha(160)
                : isPastDone
                    ? c.border.withAlpha(80)
                    : isPastMissed
                        ? AppColors.nikeRed.withAlpha(80)
                        : c.border,
          ),
        ),
        child: Row(
          children: [
            _DayBadge(
              day: day,
              isToday: isToday,
              isPastDone: isPastDone,
              isPastMissed: isPastMissed,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Day $day',
                        style: TextStyle(
                          color: isToday
                              ? AppColors.streakOrange
                              : isPastMissed
                                  ? AppColors.nikeRed
                                  : isPastDone
                                      ? c.textMuted
                                      : c.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.streakOrange,
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      if (_formatDate(executionDate) != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· ${_formatDate(executionDate)}',
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tasksPreview,
                    style: TextStyle(
                      color: isPast
                          ? c.textMuted.withAlpha(140)
                          : c.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isToday ? AppColors.streakOrange : c.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day Badge ─────────────────────────────────────────────────────────────────

class _DayBadge extends StatelessWidget {
  const _DayBadge({
    required this.day,
    required this.isToday,
    required this.isPastDone,
    required this.isPastMissed,
  });

  final int day;
  final bool isToday;
  final bool isPastDone;
  final bool isPastMissed;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.streakOrange
            : isPastDone
                ? AppColors.successGreen.withAlpha(20)
                : isPastMissed
                    ? AppColors.nikeRed.withAlpha(15)
                    : c.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday
              ? AppColors.streakOrange
              : isPastDone
                  ? AppColors.successGreen
                  : isPastMissed
                      ? AppColors.nikeRed
                      : c.border,
        ),
      ),
      child: Center(
        child: isPastDone
            ? const Icon(
                Icons.check,
                color: AppColors.successGreen,
                size: 16,
              )
            : isPastMissed
                ? const Icon(
                    Icons.close,
                    color: AppColors.nikeRed,
                    size: 16,
                  )
                : Text(
                    '$day',
                    style: TextStyle(
                      color: isToday ? AppColors.white : c.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
      ),
    );
  }
}

// ── Day Task Card ─────────────────────────────────────────────────────────────

class _DayTaskCard extends StatelessWidget {
  const _DayTaskCard({required this.task, required this.onTap});

  final Map<String, dynamic> task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final title = task['title'] as String? ?? 'Untitled';
    final explanation = task['explanation'] as String?;
    final minutes = (task['estimated_minutes'] as num?)?.toInt();
    final status = task['status'] as String? ?? TaskStatus.pending;
    final hasGuide =
        (task['guide'] as List<dynamic>? ?? []).isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: status == TaskStatus.success
              ? AppColors.successGreen.withAlpha(20)
              : status == TaskStatus.failed
                  ? AppColors.nikeRed.withAlpha(15)
                  : c.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: status == TaskStatus.success
                ? AppColors.successGreen.withAlpha(100)
                : status == TaskStatus.failed
                    ? AppColors.nikeRed.withAlpha(80)
                    : c.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskStatusIcon(status: status),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: status == TaskStatus.success
                          ? c.textMuted
                          : status == TaskStatus.failed
                              ? AppColors.nikeRed
                              : c.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: status == TaskStatus.success
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: c.textMuted,
                    ),
                  ),
                  if (explanation != null &&
                      explanation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      explanation,
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
                if (minutes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppThemeColors.of(context).surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${minutes}m',
                      style: TextStyle(
                        color: AppThemeColors.of(context).textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (hasGuide) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.list_alt_outlined,
                          color: c.textMuted, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'Guide',
                        style:
                            TextStyle(color: c.textMuted, fontSize: 10),
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
