import 'dart:async';

import 'package:flutter/material.dart';
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
    if (status == 'success') {
      setState(() {
        _pendingJob = null;
        _pendingJobError = null;
      });
      _loadGoals();
    } else {
      setState(() {
        _pendingJobError =
            payload['error_message'] as String? ?? 'Goal creation failed.';
      });
    }
  }

  Future<void> _fallbackPoll(String jobId) async {
    try {
      final status = await _goalService.pollJob(jobId);
      if (!mounted) return;
      final jobStatus = status['status'] as String? ?? 'pending';
      if (jobStatus == 'success') {
        _elapsedTimer?.cancel();
        setState(() {
          _pendingJob = null;
          _pendingJobError = null;
        });
        await _loadGoals();
      } else if (jobStatus == 'failed') {
        _elapsedTimer?.cancel();
        setState(() {
          _pendingElapsed = status['elapsed_seconds'] as int? ?? _pendingElapsed;
          _pendingJobError =
              status['error_message'] as String? ?? 'Goal creation failed.';
        });
      }
      // If still pending, leave the card showing — user can dismiss manually.
    } catch (_) {}
  }

  Future<void> _openGoalDetail(Map<String, dynamic> goal) async {
    final id = goal['id'] as String? ?? '';
    final title = goal['title'] as String? ?? 'Untitled';
    final startDate = goal['start_date'] as String?;
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GoalDetailScreen(
          goalId: id,
          goalTitle: title,
          startDate: startDate,
        ),
      ),
    );
    if (deleted == true) {
      setState(() => _goalsLoading = true);
      await _loadGoals();
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
          const DailyTasksPage(),
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
                    backgroundColor: AppColors.goldDim,
                    child: Text(
                      _initial,
                      style: const TextStyle(
                        color: AppColors.gold,
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
                    activeThumbColor: AppColors.gold,
                    activeTrackColor: AppColors.goldDim,
                  ),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.error,
                size: 20,
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.error,
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
        .where((g) => (g['status'] as String?) == 'active')
        .toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadGoals,
        color: AppColors.gold,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Row(
                    children: [
                      _StatChip(
                        icon: '🎯',
                        label: 'Active',
                        value: '${activeGoals.length}',
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: '📋',
                        label: 'Total',
                        value: '${_goals.length}',
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: '✅',
                        label: 'Done',
                        value:
                            '${_goals.where((g) => g['status'] == 'completed').length}',
                      ),
                    ],
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
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                    ),
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
                          ? _openCreateGoal
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFailed
              ? AppColors.error.withAlpha(100)
              : AppColors.gold.withAlpha(100),
        ),
        boxShadow: c.isDark
            ? null
            : [
                BoxShadow(
                  color: c.cardShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
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
                      ? AppColors.error.withAlpha(30)
                      : AppColors.goldDim,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isFailed ? 'Failed' : 'Creating…',
                  style: TextStyle(
                    color: isFailed ? AppColors.error : AppColors.gold,
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
                    const AlwaysStoppedAnimation<Color>(AppColors.gold),
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
                  color: AppColors.error.withAlpha(200), fontSize: 12),
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
                        color: AppColors.goldDim,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.gold.withAlpha(80)),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          color: AppColors.gold,
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
        border: colors.isDark
            ? Border.all(color: colors.border)
            : null,
        boxShadow: colors.isDark
            ? null
            : [
                BoxShadow(
                  color: colors.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
          border: colors.isDark
              ? Border.all(color: colors.border)
              : null,
          boxShadow: colors.isDark
              ? null
              : [
                  BoxShadow(
                    color: colors.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
          color: AppColors.goldDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold.withAlpha(80),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: AppColors.gold, size: 14),
            SizedBox(width: 4),
            Text(
              'New goal',
              style: TextStyle(
                color: AppColors.gold,
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
          gradient: LinearGradient(
            colors: c.isDark
                ? [
                    const Color(0xFF1F1400),
                    const Color(0xFF0D0D1A),
                  ]
                : [
                    AppColors.gold.withAlpha(28),
                    AppColors.gold.withAlpha(8),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold
                .withAlpha(c.isDark ? 100 : 50),
          ),
          boxShadow: c.isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.gold.withAlpha(18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gold
                    .withAlpha(c.isDark ? 40 : 28),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.bolt,
                color: AppColors.gold,
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
                      color: AppColors.gold,
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
                color: AppColors.gold
                    .withAlpha(c.isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: AppColors.gold,
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
          border: colors.isDark
              ? Border.all(
                  color: AppColors.gold.withAlpha(50),
                )
              : null,
          boxShadow: colors.isDark
              ? null
              : [
                  BoxShadow(
                    color: colors.cardShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.goldDim,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: AppColors.gold,
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
    final status = goal['status'] as String? ?? 'active';
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

    final isCompleted = status == 'completed';
    final statusColor =
        isCompleted ? AppColors.success : AppColors.gold;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: c.isDark ? Border.all(color: c.border) : null,
          boxShadow: c.isDark
              ? null
              : [
                  BoxShadow(
                    color: c.cardShadow,
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successDim,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: c.isDark ? Border.all(color: c.border) : null,
          boxShadow: c.isDark
              ? null
              : [
                  BoxShadow(
                    color: c.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: c.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
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

