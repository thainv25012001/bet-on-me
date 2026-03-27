import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bet_on_me/core/constants/app_status.dart';
import 'package:bet_on_me/core/errors/app_error_messages.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'package:bet_on_me/core/widgets/app_dialog.dart';
import 'package:bet_on_me/features/goals/data/goal_service.dart';

enum _PlanMode { deadline, freeTime }

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stakeController = TextEditingController();
  final _hoursController = TextEditingController();
  final _goalService = GoalService();

  _PlanMode _mode = _PlanMode.deadline;
  DateTime _startDate = DateTime.now();
  String? _startDateError;
  DateTime? _targetDate;
  String? _dateError;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stakeController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickStartDate() async {
    final c = AppThemeColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate:
          _targetDate ?? DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: c.isDark
              ? const ColorScheme.dark(
                  primary: AppColors.gold, onPrimary: Colors.black)
              : const ColorScheme.light(
                  primary: AppColors.gold, onPrimary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTargetDate() async {
    final c = AppThemeColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: c.isDark
              ? const ColorScheme.dark(
                  primary: AppColors.gold, onPrimary: Colors.black)
              : const ColorScheme.light(
                  primary: AppColors.gold, onPrimary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  // ── Stake info ────────────────────────────────────────────────────────────

  void _showStakeInfo() {
    final c = AppThemeColors.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Daily Stake',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
        content: Text(
          "Your daily stake is the amount you commit per day toward this goal.\n\n"
          "We never take this money — it's held as a commitment and returned in "
          "full once you complete your daily tasks. Think of it as a bet on "
          "yourself: finish your tasks, keep your money.",
          style: TextStyle(color: c.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            child: const Text('Got it',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Validate dates.
    setState(() {
      _startDateError = null;
      _dateError = null;
    });

    if (_mode == _PlanMode.deadline) {
      if (_targetDate == null) {
        setState(() => _dateError = 'Please pick a target date');
        return;
      }
      if (!_startDate.isBefore(_targetDate!)) {
        setState(() => _startDateError = 'Start date must be before target date');
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Step 1: save basic goal info immediately.
      final goal = await _goalService.createGoal(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: _startDate,
        targetDate: _mode == _PlanMode.deadline ? _targetDate : null,
        stakePerDay: int.parse(_stakeController.text),
      );

      // Step 2: enqueue AI plan generation.
      final goalId = goal['id'] as String;
      final job = await _goalService.generateGoal(
        goalId,
        hoursPerDay: double.parse(_hoursController.text),
        mode: _mode == _PlanMode.deadline ? PlanMode.duration : PlanMode.hours,
      );

      if (!mounted) return;

      Navigator.pop(context, {
        ...job,
        'goal_id': goalId,
        'title': _titleController.text.trim(),
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorDialog(context, AppErrorMessages.fromException(e));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.text, size: 20),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'New Goal',
          style: TextStyle(
              color: c.text, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Mode selector ─────────────────────────────────────────
                _ModeToggle(
                  c: c,
                  selected: _mode,
                  enabled: !_isLoading,
                  onChanged: (m) => setState(() {
                    _mode = m;
                    _dateError = null;
                    _startDateError = null;
                  }),
                ),

                const SizedBox(height: 24),

                // ── Mode description ──────────────────────────────────────
                _ModeHint(c: c, mode: _mode),

                const SizedBox(height: 24),

                // ── Title ────────────────────────────────────────────────
                _label(c, 'What is your goal?'),
                const SizedBox(height: 8),
                _field(
                  c: c,
                  controller: _titleController,
                  hint: 'e.g. Run a marathon',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),

                const SizedBox(height: 24),

                // ── Description ──────────────────────────────────────────
                _label(c, 'Description', optional: true),
                const SizedBox(height: 8),
                _field(
                  c: c,
                  controller: _descriptionController,
                  hint: 'Why is this goal important to you?',
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                // ── Start date ───────────────────────────────────────────
                _label(c, 'Start date'),
                const SizedBox(height: 8),
                _DatePickerRow(
                  c: c,
                  label:
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                  onTap: _isLoading ? null : _pickStartDate,
                ),
                if (_startDateError != null) _ErrorHint(_startDateError!),

                // ── Target date (deadline mode only) ─────────────────────
                if (_mode == _PlanMode.deadline) ...[
                  const SizedBox(height: 24),
                  _label(c, 'Target date'),
                  const SizedBox(height: 8),
                  _DatePickerRow(
                    c: c,
                    label: _targetDate == null
                        ? 'Pick a date'
                        : '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                    placeholder: _targetDate == null,
                    onTap: _isLoading ? null : _pickTargetDate,
                    onClear: _targetDate != null && !_isLoading
                        ? () => setState(() => _targetDate = null)
                        : null,
                  ),
                  if (_dateError != null) _ErrorHint(_dateError!),
                ],

                const SizedBox(height: 24),

                // ── Hours per day ─────────────────────────────────────────
                _label(c, 'Hours per day'),
                const SizedBox(height: 8),
                _field(
                  c: c,
                  controller: _hoursController,
                  hint: 'e.g. 2.5',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Hours per day is required';
                    }
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Enter a positive number';
                    if (n > 24) return 'Cannot exceed 24 hours';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── Stake per day ─────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Daily stake (\$)',
                      style: TextStyle(
                          color: c.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.info_outline,
                          color: c.textMuted, size: 18),
                      onPressed: _isLoading ? null : _showStakeInfo,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _field(
                  c: c,
                  controller: _stakeController,
                  hint: 'e.g. 5',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Daily stake is required';
                    }
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Enter a positive amount';
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // ── Submit ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppColors.gold.withAlpha(120),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Create Goal',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5),
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(AppThemeColors c, String text, {bool optional = false}) {
    return Row(
      children: [
        Text(text,
            style: TextStyle(
                color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
        if (optional) ...[
          const SizedBox(width: 6),
          Text('optional', style: TextStyle(color: c.textMuted, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _field({
    required AppThemeColors c,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      enabled: !_isLoading,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [],
      style: TextStyle(color: c.text, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
        filled: true,
        fillColor: c.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade700),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade700),
        ),
      ),
    );
  }
}

// ── Mode toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.c,
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  final AppThemeColors c;
  final _PlanMode selected;
  final ValueChanged<_PlanMode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ModeTab(
            c: c,
            icon: Icons.flag_outlined,
            label: 'I have a deadline',
            active: selected == _PlanMode.deadline,
            enabled: enabled,
            onTap: () => onChanged(_PlanMode.deadline),
          ),
          _ModeTab(
            c: c,
            icon: Icons.schedule_outlined,
            label: 'I have free time',
            active: selected == _PlanMode.freeTime,
            enabled: enabled,
            onTap: () => onChanged(_PlanMode.freeTime),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.c,
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final AppThemeColors c;
  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.black : c.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? Colors.black : c.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mode hint ─────────────────────────────────────────────────────────────────

class _ModeHint extends StatelessWidget {
  const _ModeHint({required this.c, required this.mode});

  final AppThemeColors c;
  final _PlanMode mode;

  @override
  Widget build(BuildContext context) {
    final isDeadline = mode == _PlanMode.deadline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDeadline ? Icons.flag_outlined : Icons.auto_awesome_outlined,
            color: AppColors.gold,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isDeadline
                  ? 'You pick a finish date. AI builds a daily plan that fits your schedule and gets you there on time.'
                  : 'You set how many hours you can spare each day. AI estimates how long it will take and plans every day for you.',
              style: TextStyle(
                color: c.text,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date picker row ───────────────────────────────────────────────────────────

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.c,
    required this.label,
    required this.onTap,
    this.placeholder = false,
    this.onClear,
  });

  final AppThemeColors c;
  final String label;
  final bool placeholder;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
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
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: c.textMuted, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                  color: placeholder ? c.textMuted : c.text, fontSize: 15),
            ),
            if (onClear != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, color: c.textMuted, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error hint ────────────────────────────────────────────────────────────────

class _ErrorHint extends StatelessWidget {
  const _ErrorHint(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(message,
          style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
    );
  }
}
