import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bet_on_me/core/constants/app_status.dart';
import 'package:bet_on_me/core/errors/app_error_messages.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'package:bet_on_me/features/auth/data/auth_service.dart';
import 'package:bet_on_me/features/auth/presentation/screens/change_password_screen.dart';
import 'package:bet_on_me/features/auth/presentation/screens/signin_screen.dart';
import 'package:bet_on_me/features/goals/data/goal_service.dart';
import 'package:bet_on_me/features/goals/data/goal_ws_service.dart';
import 'package:bet_on_me/features/goals/presentation/screens/create_goal_screen.dart';
import 'package:bet_on_me/features/goals/presentation/screens/goal_detail_screen.dart';
import 'package:bet_on_me/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:bet_on_me/main.dart';
import 'daily_tasks_screen.dart';

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _dailyTasksKey = GlobalKey<DailyTasksPageState>();
  final _authService = AuthService();
  final _goalService = GoalService();
  final _wsService = GoalWsService();
  String _userName = '';
  List<Map<String, dynamic>> _goals = [];
  bool _goalsLoading = true;

  Map<String, dynamic>? _pendingJob;
  int _pendingElapsed = 0;
  String? _pendingJobError;
  StreamSubscription<Map<String, dynamic>>? _jobSub;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadGoals();
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    _elapsedTimer?.cancel();
    _wsService.close();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final data = await _authService.getMe();
      if (mounted) {
        setState(() {
          _userName = (data['name'] as String?) ??
              (data['email'] as String? ?? '');
        });
      }
    } catch (_) {}
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await _goalService.listGoals();
      if (mounted) {
        setState(() {
          _goals = goals;
          _goalsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _goalsLoading = false);
    }
  }

  String get _displayName =>
      _userName.isNotEmpty ? _userName.split(' ').first : '…';
  String get _initial =>
      _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _openCreateGoal() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => CreateGoalScreen(key: UniqueKey())),
    );
    if (result != null && mounted) {
      _startJobWatch(result);
    }
  }

  Future<void> _retryFailedJob() async {
    if (_pendingJob == null) return;
    final goalId = _pendingJob!['goal_id'] as String? ?? '';
    final hoursPerDay =
        (_pendingJob!['hours_per_day'] as num?)?.toDouble() ?? 1.0;
    final mode = _pendingJob!['mode'] as String? ?? 'duration';
    final title = _pendingJob!['title'] as String? ?? 'Goal';

    setState(() => _pendingJobError = null);
    try {
      final job = await _goalService.generateGoal(
        goalId,
        hoursPerDay: hoursPerDay,
        mode: mode,
      );
      if (!mounted) return;
      _startJobWatch({
        ...job,
        'goal_id': goalId,
        'title': title,
        'hours_per_day': hoursPerDay,
        'mode': mode,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingJobError = 'Could not retry. Please try again.');
    }
  }

  Future<void> _startJobWatch(Map<String, dynamic> job) async {
    final jobId = job['job_id'] as String? ?? '';
    setState(() {
      _pendingJob = job;
      _pendingElapsed = 0;
      _pendingJobError = null;
    });

    // Tick elapsed time locally so the progress bar moves smoothly.
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _pendingJob != null) {
        setState(() => _pendingElapsed++);
      }
    });

    try {
      final stream = await _wsService.watchJob(jobId);
      _jobSub = stream.listen(
        _onJobMessage,
        onError: (_) => _fallbackPoll(jobId),
        cancelOnError: true,
      );
    } catch (_) {
      // WS connect failed immediately — fall back to a single HTTP poll.
      _fallbackPoll(jobId);
    }
  }

  void _onJobMessage(Map<String, dynamic> payload) {
    _jobSub?.cancel();
    _elapsedTimer?.cancel();
    _wsService.close();
    if (!mounted) return;

    final status = payload['status'] as String? ?? '';
    if (status == JobStatus.success) {
      // Plan is ready — goal is now locked, awaiting user commitment.
      setState(() {
        _pendingJob = null;
        _pendingJobError = null;
      });
      _loadGoals();
    } else {
      final errorCode = payload['error_code'] as String?;
      setState(() {
        _pendingJobError = AppErrorMessages.fromCode(errorCode);
      });
    }
  }

  Future<void> _fallbackPoll(String jobId) async {
    try {
      final status = await _goalService.pollJob(jobId);
      if (!mounted) return;
      final jobStatus = status['status'] as String? ?? JobStatus.pending;
      if (jobStatus == JobStatus.success) {
        _elapsedTimer?.cancel();
        setState(() {
          _pendingJob = null;
          _pendingJobError = null;
        });
        await _loadGoals();
      } else if (jobStatus == JobStatus.failed) {
        _elapsedTimer?.cancel();
        final errorCode = status['error_code'] as String?;
        setState(() {
          _pendingElapsed = status['elapsed_seconds'] as int? ?? _pendingElapsed;
          _pendingJobError = AppErrorMessages.fromCode(errorCode);
        });
      }
      // If still pending, leave the card showing — user can dismiss manually.
    } catch (_) {}
  }

  Future<void> _openGoalDetail(Map<String, dynamic> goal) async {
    final id = goal['id'] as String? ?? '';
    final title = goal['title'] as String? ?? 'Untitled';
    final startDate = goal['start_date'] as String?;
    final goalStatus = goal['status'] as String?;
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => GoalDetailScreen(
          goalId: id,
          goalTitle: title,
          startDate: startDate,
          goalStatus: goalStatus,
        ),
      ),
    );
    if (result == 'deleted' || result == 'unlocked') {
      setState(() => _goalsLoading = true);
      await _loadGoals();
      _dailyTasksKey.currentState?.reload();
    }
  }

  Future<void> _logout() async {
    await _authService.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      endDrawer: _buildDrawer(c),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(c),
          DailyTasksPage(key: _dailyTasksKey),
          const SubscriptionScreen(),
        ],
      ),
      bottomNavigationBar: _AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────────

  Widget _buildDrawer(AppThemeColors c) {
    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.hoverGray,
                    child: Text(
                      _initial,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName.isNotEmpty ? _userName : '…',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stay consistent 🔥',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.lock_reset,
                color: c.text.withAlpha(180),
                size: 20,
              ),
              title: Text(
                'Change Password',
                style: TextStyle(
                  color: c.text.withAlpha(180),
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (_, mode, _) {
                final isLight = mode == ThemeMode.light;
                return ListTile(
                  leading: Icon(
                    isLight
                        ? Icons.wb_sunny_outlined
                        : Icons.nightlight_outlined,
                    color: c.textMuted,
                    size: 20,
                  ),
                  title: Text(
                    'Appearance',
                    style: TextStyle(
                      color: c.text.withAlpha(180),
                      fontSize: 14,
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: isLight,
                    onChanged: (v) {
                      themeModeNotifier.value =
                          v ? ThemeMode.light : ThemeMode.dark;
                    },
                    activeThumbColor: c.text,
                    activeTrackColor: AppColors.hoverGray,
                  ),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.nikeRed,
                size: 20,
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.nikeRed,
                  fontSize: 14,
                ),
              ),
              onTap: _logout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Dashboard ──────────────────────────────────────────────────────────────

  Widget _buildDashboard(AppThemeColors c) {
    final activeGoals = _goals
        .where((g) => (g['status'] as String?) == GoalStatus.inProgress)
        .toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadGoals,
        color: c.isDark ? AppColors.white : AppColors.nikeBlack,
        backgroundColor: c.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goals',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_greeting, $_displayName',
                            style: TextStyle(
                              color: c.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _DateBadge(colors: c),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (ctx) => _MenuButton(
                            colors: c,
                            onTap: () =>
                                Scaffold.of(ctx).openEndDrawer(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Today's Focus ─────────────────────────────────
              if (!_goalsLoading && activeGoals.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: _TodayFocusCard(
                    activeCount: activeGoals.length,
                    onTap: () =>
                        setState(() => _selectedIndex = 1),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Stats ─────────────────────────────────────────
              if (!_goalsLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StatsRow(
                    total: _goals.length,
                    inProgress: _goals
                        .where((g) => g['status'] == GoalStatus.inProgress)
                        .length,
                    success: _goals
                        .where((g) => g['status'] == GoalStatus.success)
                        .length,
                    failed: _goals
                        .where((g) => g['status'] == GoalStatus.failed)
                        .length,
                  ),
                ),

              const SizedBox(height: 28),

              // ── Section header ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Goals',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    _NewGoalButton(onTap: _openCreateGoal),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Goal list ─────────────────────────────────────
              if (_goalsLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: const CircularProgressIndicator(),
                  ),
                )
              else ...[
                if (_pendingJob != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: _GoalCreatingCard(
                      title: _pendingJob!['title'] as String? ??
                          'New Goal',
                      estimatedSeconds: _pendingJob![
                              'estimated_seconds'] as int? ??
                          30,
                      elapsedSeconds: _pendingElapsed,
                      errorMessage: _pendingJobError,
                      onDismiss: () => setState(() {
                        _pendingJob = null;
                        _pendingJobError = null;
                      }),
                      onRetry: _pendingJobError != null
                          ? _retryFailedJob
                          : null,
                    ),
                  ),
                if (_goals.isEmpty && _pendingJob == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: _EmptyGoalsCard(
                      colors: c,
                      onTap: _openCreateGoal,
                    ),
                  )
                else if (_goals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: _goals.length,
                      itemBuilder: (_, i) => _GoalListItem(
                        goal: _goals[i],
                        onTap: () => _openGoalDetail(_goals[i]),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Goal Creating Card ────────────────────────────────────────────────────────

class _GoalCreatingCard extends StatelessWidget {
  const _GoalCreatingCard({
    required this.title,
    required this.estimatedSeconds,
    required this.elapsedSeconds,
    required this.onDismiss,
    this.errorMessage,
    this.onRetry,
  });

  final String title;
  final int estimatedSeconds;
  final int elapsedSeconds;
  final String? errorMessage;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final isFailed = errorMessage != null;
    final progress = estimatedSeconds > 0
        ? (elapsedSeconds / estimatedSeconds).clamp(0.0, 1.0)
        : 0.0;
    final remaining =
        (estimatedSeconds - elapsedSeconds).clamp(0, estimatedSeconds);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFailed ? AppColors.nikeRed : c.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFailed
                      ? AppColors.nikeRed.withAlpha(30)
                      : AppColors.hoverGray,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isFailed ? 'Failed' : 'Creating…',
                  style: TextStyle(
                    color: isFailed ? AppColors.nikeRed : AppColors.streakOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isFailed) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: c.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.streakOrange),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              remaining > 0
                  ? 'AI is building your plan — ~${remaining}s remaining'
                  : 'Almost done…',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
          ] else ...[
            Text(
              errorMessage!,
              style: TextStyle(
                  color: AppColors.nikeRed, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (onRetry != null) ...[
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.hoverGray,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSecondary),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          color: AppColors.nikeBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.border.withAlpha(80),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Date Badge ────────────────────────────────────────────────────────────────

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.colors});

  final AppThemeColors colors;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${now.day}',
            style: TextStyle(
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _months[now.month - 1],
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu Button ───────────────────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.colors, required this.onTap});

  final AppThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Icon(Icons.menu, color: colors.text, size: 20),
      ),
    );
  }
}

// ── New Goal Button ───────────────────────────────────────────────────────────

class _NewGoalButton extends StatelessWidget {
  const _NewGoalButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.hoverGray,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: AppColors.nikeBlack, size: 14),
            SizedBox(width: 4),
            Text(
              'New goal',
              style: TextStyle(
                color: AppColors.nikeBlack,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today's Focus Card ────────────────────────────────────────────────────────

class _TodayFocusCard extends StatelessWidget {
  const _TodayFocusCard({
    required this.activeCount,
    required this.onTap,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.hoverGray,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.bolt,
                color: AppColors.streakOrange,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TODAY'S FOCUS",
                    style: TextStyle(
                      color: AppColors.streakOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$activeCount active goal${activeCount == 1 ? '' : 's'} — see your tasks',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.hoverGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: c.text,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Goals Card ──────────────────────────────────────────────────────────

class _EmptyGoalsCard extends StatelessWidget {
  const _EmptyGoalsCard({
    required this.colors,
    required this.onTap,
  });

  final AppThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.hoverGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: colors.text,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first goal',
              style: TextStyle(
                color: colors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'AI will build your daily plan instantly.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal List Item ────────────────────────────────────────────────────────────

class _GoalListItem extends StatelessWidget {
  const _GoalListItem({
    required this.goal,
    required this.onTap,
  });

  final Map<String, dynamic> goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final title = goal['title'] as String? ?? 'Untitled';
    final status = goal['status'] as String? ?? GoalStatus.inProgress;
    final startDateStr = goal['start_date'] as String?;
    final targetDateStr = goal['target_date'] as String?;

    double progress = 0;
    int currentDay = 0;
    int totalDays = 0;

    if (startDateStr != null && targetDateStr != null) {
      final start = DateTime.parse(startDateStr);
      final target = DateTime.parse(targetDateStr);
      final today = DateTime.now();
      totalDays = target.difference(start).inDays;
      final passed =
          today.difference(start).inDays.clamp(0, totalDays);
      currentDay = passed + 1;
      progress = totalDays > 0 ? passed / totalDays : 0;
    }

    final isCompleted = status == GoalStatus.success;
    final isLocked = status == GoalStatus.locked;
    final isDraft = status == GoalStatus.draft;
    final isFailed = status == GoalStatus.failed;
    final statusColor = isCompleted
        ? AppColors.successGreen
        : isFailed
            ? AppColors.nikeRed
            : AppColors.streakOrange;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isCompleted)
                  _StatusBadge(
                    label: 'Done',
                    color: AppColors.successGreen,
                    bgColor: AppColors.hoverGray,
                  )
                else if (isFailed)
                  _StatusBadge(
                    label: 'Failed',
                    color: AppColors.nikeRed,
                    bgColor: AppColors.nikeRed.withAlpha(30),
                  )
                else if (isLocked)
                  _StatusBadge(
                    label: 'Locked',
                    color: AppColors.textSecondary,
                    bgColor: AppColors.hoverGray,
                  )
                else if (isDraft)
                  _StatusBadge(
                    label: 'Generating…',
                    color: c.textMuted,
                    bgColor: c.border,
                  )
                else if (totalDays > 0)
                  Text(
                    'Day $currentDay / $totalDays',
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: c.textMuted,
                  size: 18,
                ),
              ],
            ),
            if (totalDays > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: c.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      statusColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.inProgress,
    required this.success,
    required this.failed,
  });

  final int total;
  final int inProgress;
  final int success;
  final int failed;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(value: '$total', label: 'Total', color: c.text),
            _VerticalDivider(color: c.border),
            _StatCell(
                value: '$inProgress',
                label: 'In Progress',
                color: AppColors.streakOrange),
            _VerticalDivider(color: c.border),
            _StatCell(
                value: '$success',
                label: 'Success',
                color: AppColors.successGreen),
            _VerticalDivider(color: c.border),
            _StatCell(
                value: '$failed', label: 'Failed', color: AppColors.nikeRed),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vertical Divider ─────────────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 12),
        color: color,
      );
}

// ── App Bottom Nav ────────────────────────────────────────────────────────────

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.border, width: 0.5),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.rocket_launch_outlined),
            selectedIcon: Icon(Icons.rocket_launch),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Plans',
          ),
        ],
      ),
    );
  }
}

