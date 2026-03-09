import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';

class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.g_mobiledata_rounded, size: 26, color: Colors.white),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
