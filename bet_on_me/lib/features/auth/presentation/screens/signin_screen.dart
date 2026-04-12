import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_colors.dart';
import 'package:bet_on_me/core/services/api_client.dart';
import 'package:bet_on_me/core/widgets/app_dialog.dart';
import 'package:bet_on_me/features/auth/data/auth_service.dart';
import 'package:bet_on_me/features/auth/presentation/widgets/auth_header.dart';
import 'package:bet_on_me/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:bet_on_me/features/auth/presentation/widgets/or_divider.dart';
import 'package:bet_on_me/features/auth/presentation/widgets/social_sign_in_button.dart';
import 'package:bet_on_me/features/home/presentation/screens/home_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              // ── Header ───────────────────────────────────────────────
              const AuthHeader(),

              const SizedBox(height: 52),

              // ── Form label ───────────────────────────────────────────
              Text(
                'Welcome back',
                style: TextStyle(
                  color: c.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to continue your streak.',
                style: TextStyle(
                  color: c.textMuted,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 28),

              // ── Form ─────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your email';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),
                  ],
                ),
              ),

              // ── Forgot Password ──────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: c.text,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── CTA Button ───────────────────────────────────────────
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          try {
                            await _authService.login(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            );
                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (_) => false,
                            );
                          } on ApiException catch (e) {
                            if (!mounted) return;
                            showErrorDialog(context, e.message);
                          } catch (_) {
                            if (!mounted) return;
                            showErrorDialog(
                              context,
                              'Network error. Please try again.',
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      },
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: c.ctaFg,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('SIGN IN'),
              ),

              const SizedBox(height: 24),

              // ── Divider ──────────────────────────────────────────────
              const OrDivider(),

              const SizedBox(height: 24),

              // ── Google Sign-In ────────────────────────────────────────
              SocialSignInButton(
                onPressed: () {
                  // TODO: Google sign-in
                },
              ),

              const SizedBox(height: 36),

              // ── Sign Up link ─────────────────────────────────────────
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: c.textMuted, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: c.text,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
