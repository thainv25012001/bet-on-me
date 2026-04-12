import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'package:bet_on_me/core/widgets/app_dialog.dart';
import 'package:bet_on_me/features/subscription/data/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _service = SubscriptionService();

  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _activeSub;
  bool _loading = true;
  String? _subscribingTier;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.listPlans(),
        _service.getActiveSubscription(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<Map<String, dynamic>>;
        _activeSub = results[1] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e, s) {
      developer.log('Failed to load subscriptions', error: e, stackTrace: s);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _subscribe(String tier) async {
    setState(() => _subscribingTier = tier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.subscribe(tier);
      await _load();
      messenger.showSnackBar(
        const SnackBar(content: Text('Subscription activated!')),
      );
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    } finally {
      if (mounted) setState(() => _subscribingTier = null);
    }
  }

  Future<void> _cancel() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _CancelDialog(),
    );
    if (confirmed != true) return;
    try {
      await _service.cancelSubscription();
      await _load();
      messenger.showSnackBar(
        const SnackBar(content: Text('Subscription cancelled.')),
      );
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  String? get _activeTier =>
      _activeSub?['plan']?['tier'] as String?;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(c),
      ),
    );
  }

  Widget _buildContent(AppThemeColors c) {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(c),
          if (_activeSub != null) _buildActiveBanner(c),
          _buildSectionTitle('Choose your plan', c),
          _buildPlanList(c),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(AppThemeColors c) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription',
              style: TextStyle(
                color: c.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Unlock more days, more goals, more growth.',
              style: TextStyle(color: c.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildActiveBanner(AppThemeColors c) {
    final plan = _activeSub!['plan'] as Map<String, dynamic>?;
    final tier = plan?['tier'] as String? ?? '';
    final expiresAt = _activeSub!['expires_at'] as String? ?? '';
    final status = _activeSub!['status'] as String? ?? '';
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, color: AppColors.successGreen, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active: ${_tierLabel(tier)}',
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Expires $expiresAt  •  ${status.toUpperCase()}',
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _cancel,
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.nikeRed, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionTitle(String title, AppThemeColors c) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(
          title,
          style: TextStyle(
            color: c.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  SliverList _buildPlanList(AppThemeColors c) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _PlanCard(
          plan: _plans[i],
          isActive: _plans[i]['tier'] == _activeTier,
          isLoading: _subscribingTier == _plans[i]['tier'],
          onSubscribe: () => _subscribe(_plans[i]['tier'] as String),
        ),
        childCount: _plans.length,
      ),
    );
  }

  String _tierLabel(String tier) => switch (tier) {
        'free' => 'Free',
        'pro' => 'Pro',
        'advanced' => 'Advanced',
        _ => tier,
      };
}

// ── Plan Card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isActive,
    required this.isLoading,
    required this.onSubscribe,
  });

  final Map<String, dynamic> plan;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final tier = plan['tier'] as String? ?? '';
    final name = plan['name'] as String? ?? tier;
    final description = plan['description'] as String? ?? '';
    final priceCents = plan['price_cents'] as int? ?? 0;
    final discountedCents = plan['discounted_price_cents'] as int?;
    final discountPct = plan['discount_percent'] as num?;
    final maxDays = plan['max_plan_days'] as int? ?? 0;
    final features = (plan['features'] as List<dynamic>? ?? [])
        .cast<String>();

    final isPro = tier == 'pro';
    final isAdvanced = tier == 'advanced';
    final accentColor =
        isAdvanced ? AppColors.streakOrange : (isPro ? c.text : c.textMuted);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? (c.isDark ? AppColors.white : AppColors.nikeBlack)
              : isAdvanced
                  ? AppColors.streakOrange.withAlpha(100)
                  : c.border,
          width: isActive ? 2 : 1,
        ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              name: name,
              tier: tier,
              isActive: isActive,
              accentColor: accentColor,
              maxDays: maxDays,
              c: c,
            ),
            const SizedBox(height: 12),
            _PriceRow(
              priceCents: priceCents,
              discountedCents: discountedCents,
              discountPct: discountPct,
              c: c,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.5),
            ),
            if (features.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...features.map((f) => _FeatureRow(feature: f, c: c)),
            ],
            const SizedBox(height: 16),
            _SubscribeButton(
              isActive: isActive,
              isLoading: isLoading,
              accentColor: accentColor,
              onSubscribe: onSubscribe,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.name,
    required this.tier,
    required this.isActive,
    required this.accentColor,
    required this.maxDays,
    required this.c,
  });

  final String name;
  final String tier;
  final bool isActive;
  final Color accentColor;
  final int maxDays;
  final AppThemeColors c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            name.toUpperCase(),
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: c.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$maxDays days',
            style: TextStyle(
              color: c.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isActive) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.hoverGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: AppColors.successGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.priceCents,
    required this.discountedCents,
    required this.discountPct,
    required this.c,
  });

  final int priceCents;
  final int? discountedCents;
  final num? discountPct;
  final AppThemeColors c;

  String _fmt(int cents) =>
      cents == 0 ? 'Free' : '\$${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discountedCents != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          hasDiscount ? _fmt(discountedCents!) : _fmt(priceCents),
          style: TextStyle(
            color: c.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (priceCents > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: Text(
              '/mo',
              style: TextStyle(color: c.textMuted, fontSize: 13),
            ),
          ),
        if (hasDiscount) ...[
          const SizedBox(width: 10),
          Text(
            _fmt(priceCents),
            style: TextStyle(
              color: c.textMuted,
              fontSize: 14,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.hoverGray,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-${discountPct!.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: AppColors.successGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.c});

  final String feature;
  final AppThemeColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.successGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(color: c.text, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({
    required this.isActive,
    required this.isLoading,
    required this.accentColor,
    required this.onSubscribe,
  });

  final bool isActive;
  final bool isLoading;
  final Color accentColor;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.successGreen),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            'Current Plan',
            style: TextStyle(color: AppColors.successGreen),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubscribe,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Text(
                'Subscribe',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

// ── Cancel Dialog ─────────────────────────────────────────────────────────────

class _CancelDialog extends StatelessWidget {
  const _CancelDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel subscription?'),
      content: const Text(
        'Your plan will remain active until the expiry date, '
        'then revert to Free.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep plan'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.nikeRed),
          child: const Text('Cancel plan'),
        ),
      ],
    );
  }
}
