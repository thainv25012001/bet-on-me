import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'package:bet_on_me/features/auth/data/auth_service.dart';
import 'package:bet_on_me/features/auth/presentation/screens/signin_screen.dart';
import 'package:bet_on_me/features/home/presentation/widgets/goal_card.dart';
import 'package:bet_on_me/features/home/presentation/widgets/task_item.dart';

// ── Mock data models ─────────────────────────────────────────────────────────

class _Goal {
  final String emoji;
  final String title;
  final List<GoalTask> tasks;
  const _Goal({required this.emoji, required this.title, required this.tasks});
}

final _mockGoals = <_Goal>[
  _Goal(
    emoji: '🚀',
    title: 'Launch side project',
    tasks: const [
      GoalTask(title: 'Set up repo & CI/CD', isComplete: true),
      GoalTask(title: 'Build MVP landing page', isComplete: true),
      GoalTask(title: 'Write launch blog post', isComplete: false),
      GoalTask(title: 'Submit to Product Hunt', isComplete: false),
    ],
  ),
  _Goal(
    emoji: '💪',
    title: 'Get fit',
    tasks: const [
      GoalTask(title: 'Morning run – 5 km', isComplete: true),
      GoalTask(title: 'Strength training session', isComplete: false),
      GoalTask(title: 'Meal prep for the week', isComplete: false),
    ],
  ),
  _Goal(
    emoji: '📚',
    title: 'Read 12 books this year',
    tasks: const [
      GoalTask(title: 'Read 20 pages of current book', isComplete: true),
      GoalTask(title: 'Write chapter summary note', isComplete: true),
      GoalTask(title: 'Pick next book from reading list', isComplete: false),
    ],
  ),
];

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _authService = AuthService();

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
                    child: const Text(
                      'C',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Champ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
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
    final completedGoals = _mockGoals
        .where((g) => g.tasks.every((t) => t.isComplete))
        .length;
    final activeGoals = _mockGoals.length - completedGoals;

    final totalTasks =
        _mockGoals.fold<int>(0, (sum, g) => sum + g.tasks.length);
    final completedTasks = _mockGoals.fold<int>(
        0, (sum, g) => sum + g.tasks.where((t) => t.isComplete).length);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Greeting
            const Text(
              'Good morning, Champ 👋',
              style: TextStyle(
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
                _StatChip(label: '🔥 7-day streak', value: '7'),
                const SizedBox(width: 12),
                _StatChip(
                    label: 'Active goals', value: '$activeGoals'),
                const SizedBox(width: 12),
                _StatChip(
                    label: 'Tasks today',
                    value: '$completedTasks/$totalTasks'),
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

            // Goal cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockGoals.length,
              itemBuilder: (_, i) => GoalCard(
                emoji: _mockGoals[i].emoji,
                title: _mockGoals[i].title,
                tasks: _mockGoals[i].tasks,
              ),
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
