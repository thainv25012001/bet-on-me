import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';

/// Shows a modal error dialog with a single OK button.
Future<void> showErrorDialog(BuildContext context, String message) {
  final c = AppThemeColors.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.error_outline, color: AppColors.error, size: 36),
      title: Text(
        'Something went wrong',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: c.text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 44),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
