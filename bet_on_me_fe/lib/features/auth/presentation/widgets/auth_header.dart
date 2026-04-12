import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.hoverGray,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSecondary),
            ),
            child: Icon(Icons.bolt_rounded, color: c.text, size: 38),
          ),
          const SizedBox(height: 20),
          Text(
            'BET ON ME',
            style: TextStyle(
              color: c.text,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commit. Execute. Win.',
            style: TextStyle(
              color: c.textMuted,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
