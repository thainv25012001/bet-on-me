import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(color: c.textMuted, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: c.border)),
      ],
    );
  }
}
