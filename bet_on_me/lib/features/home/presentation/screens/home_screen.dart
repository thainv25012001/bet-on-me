import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'package:bet_on_me/features/auth/data/auth_service.dart';
import 'package:bet_on_me/features/auth/presentation/screens/signin_screen.dart';
import 'package:bet_on_me/features/goals/data/goal_service.dart';
import 'package:bet_on_me/features/goals/presentation/screens/create_goal_screen.dart';
import 'package:bet_on_me/features/goals/presentation/screens/goal_detail_screen.dart';

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
  String _userName = '';
  List<Map<String, dynamic>> _goals = [];
  bool _goalsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadGoals();
  }

  Future<void> _loadUser() async {
    try {
      final data = await _authService.getMe();
      if (mounted) {
        setState(() {
          _userName = (data['name'] as String?) ?? (data['email'] as String? ?? '');
        });
      }
    } catch (_) {
      // silently fail — name stays empty
    }
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

  String get _displayName => _userName.isNotEmpty ? _userName : '…';
  String get _initial => _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';

  Future<void> _openCreateGoal() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
    );
    if (created == true) {
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      endDrawer: _buildDrawer(),
      appBar: _buildAppBar(context),
      body: _selectedIndex == 0
          ? _buildDashboard()
          : Center(
              child: Text(
                _selectedIndex == 1 ? 'Daily Tasks' : 'Wallet',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Row(
        children: [
          Text('⚡', style: TextStyle(fontSize: 20)),
          SizedBox(width: 6),
          Text(
            'BET ON ME',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openEndDrawer(),
          ),
        ),
      ],
    );
  }

  // ── Drawer ──────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name
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
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Stay consistent 🔥',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: AppColors.border, height: 1),

            const Spacer(),

            // Logout tile
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Color(0xFFF44336), size: 20),
              title: const Text(
                'Log Out',
                style: TextStyle(color: Color(0xFFF44336), fontSize: 14),
              ),
              onTap: _logout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Dashboard body ──────────────────────────────────────────────────────

  Widget _buildDashboard() {
    final activeGoals = _goals
        .where((g) => (g['status'] as String?) == 'active')
        .length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Greeting
            Text(
              'Good morning, $_displayName 👋',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formattedDate(),
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),

            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                const _StatChip(label: '🔥 7-day streak', value: '7'),
                const SizedBox(width: 12),
                _StatChip(label: 'Active goals', value: '$activeGoals'),
                const SizedBox(width: 12),
                const _StatChip(label: 'Tasks today', value: '0/0'),
              ],
            ),

            const SizedBox(height: 28),

            // Section label
            const Text(
              'Your Goals',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            // Create new goal card
            _NewGoalCard(onTap: _openCreateGoal),

            const SizedBox(height: 16),

            // Goal list
            if (_goalsLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            else if (_goals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No goals yet. Create your first one!',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _goals.length,
                itemBuilder: (_, i) {
                  final goal = _goals[i];
                  final id = goal['id'] as String? ?? '';
                  final title = goal['title'] as String? ?? 'Untitled';
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GoalDetailScreen(
                          goalId: id,
                          goalTitle: title,
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav ──────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.textMuted,
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.rocket_launch_outlined),
          activeIcon: Icon(Icons.rocket_launch),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checklist_outlined),
          activeIcon: Icon(Icons.checklist),
          label: 'Daily Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Wallet',
        ),
      ],
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ── New goal card ─────────────────────────────────────────────────────────────

class _NewGoalCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NewGoalCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withAlpha(80),
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.gold, size: 40),
            SizedBox(height: 10),
            Text(
              'Create a new goal',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.goldDim,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
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
