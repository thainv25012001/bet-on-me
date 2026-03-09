import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.goldDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withAlpha(80), width: 1),
            ),
            child: const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 38),
          ),
          const SizedBox(height: 20),
          const Text(
            'BET ON ME',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Commit. Execute. Win.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
