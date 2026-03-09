import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
