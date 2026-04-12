import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'package:bet_on_me/core/services/api_client.dart';
import 'package:bet_on_me/core/widgets/app_dialog.dart';
import 'package:bet_on_me/features/auth/data/auth_service.dart';
import 'package:bet_on_me/features/auth/presentation/widgets/auth_text_field.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = await _authService.forgotPassword(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      final token = data['reset_token'] as String?;
      if (token != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: token),
          ),
        );
      } else {
        _showInfo('Check your email for a reset link.');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Network error.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) => showErrorDialog(context, message);

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.hoverGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.lock_reset, color: c.text, size: 28),
              ),

              const SizedBox(height: 24),

              Text(
                'Forgot Password?',
                style: TextStyle(
                  color: c.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your email and we'll send you a reset token.",
                style: TextStyle(
                  color: c.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: AuthTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: c.ctaFg,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('SEND RESET TOKEN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
