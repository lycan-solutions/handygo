import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_text_field.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _forgotPasswordRequestProvider =
    AsyncNotifierProvider.autoDispose<_RequestNotifier, void>(
  _RequestNotifier.new,
);

class _RequestNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> request(String phone) async {
    state = const AsyncLoading();
    final result =
        await ref.read(authRepositoryProvider).forgotPasswordRequest(phone);
    return result.fold(
      (f) {
        state = AsyncError(f, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}

final _forgotPasswordResetProvider =
    AsyncNotifierProvider.autoDispose<_ResetNotifier, void>(
  _ResetNotifier.new,
);

class _ResetNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> reset({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).forgotPasswordReset(
          phone: phone,
          otp: otp,
          newPassword: newPassword,
        );
    return result.fold(
      (f) {
        state = AsyncError(f, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  static const _accent = Color(0xFFDB6234);
  static const _slate = Color(0xFF6B7280);

  final _phoneKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _onOtpStep = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _resendTimer?.cancel();
        }
      });
    });
  }

  Future<void> _sendCode() async {
    if (!_phoneKey.currentState!.validate()) return;
    final ok = await ref
        .read(_forgotPasswordRequestProvider.notifier)
        .request(_phoneCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _onOtpStep = true);
      _startResendTimer();
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    await ref
        .read(_forgotPasswordRequestProvider.notifier)
        .request(_phoneCtrl.text.trim());
    if (mounted) _startResendTimer();
  }

  Future<void> _resetPassword() async {
    if (!_resetKey.currentState!.validate()) return;
    final ok = await ref.read(_forgotPasswordResetProvider.notifier).reset(
          phone: _phoneCtrl.text.trim(),
          otp: _otpCtrl.text.trim(),
          newPassword: _newPasswordCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. Please log in.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/auth/login');
    }
  }

  String _errorMessage(Object? err) {
    if (err is Failure) return err.userMessage;
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final requestState = ref.watch(_forgotPasswordRequestProvider);
    final resetState = ref.watch(_forgotPasswordResetProvider);

    ref.listen(_forgotPasswordRequestProvider, (_, s) {
      if (s is AsyncError && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(_errorMessage(s.error)),
            behavior: SnackBarBehavior.floating,
          ));
      }
    });
    ref.listen(_forgotPasswordResetProvider, (_, s) {
      if (s is AsyncError && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(_errorMessage(s.error)),
            behavior: SnackBarBehavior.floating,
          ));
      }
    });

    final mq = MediaQuery.of(context);
    final viewInsets = mq.viewInsets.bottom;
    final isSmall = mq.size.height < 680;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(bottom: viewInsets + 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: isSmall ? 20 : 32),

                            // ── Back button ─────────────────────────────────
                            GestureDetector(
                              onTap: () {
                                if (_onOtpStep) {
                                  setState(() => _onOtpStep = false);
                                } else {
                                  context.pop();
                                }
                              },
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: Color(0xFF1A1A1A),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: isSmall ? 16 : 24),

                            // ── Header ──────────────────────────────────────
                            _AuthHeader(
                              title: _onOtpStep
                                  ? 'Reset\nPassword'
                                  : 'Forgot\nPassword?',
                              subtitle: _onOtpStep
                                  ? 'Enter the code sent to your number'
                                  : 'Code sent if this number is registered.',
                              isSmall: isSmall,
                            ),

                            SizedBox(height: isSmall ? 24 : 36),

                            // ── Step forms ───────────────────────────────────
                            if (!_onOtpStep)
                              _PhoneForm(
                                formKey: _phoneKey,
                                phoneCtrl: _phoneCtrl,
                                isLoading: requestState.isLoading,
                                onSend: _sendCode,
                              )
                            else
                              _OtpResetForm(
                                formKey: _resetKey,
                                otpCtrl: _otpCtrl,
                                newPasswordCtrl: _newPasswordCtrl,
                                confirmCtrl: _confirmCtrl,
                                isLoading: resetState.isLoading,
                                resendSeconds: _resendSeconds,
                                onReset: _resetPassword,
                                onResend: _resend,
                                accent: _accent,
                                slate: _slate,
                              ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Step 1: phone form ────────────────────────────────────────────────────────

class _PhoneForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtrl;
  final bool isLoading;
  final VoidCallback onSend;

  const _PhoneForm({
    required this.formKey,
    required this.phoneCtrl,
    required this.isLoading,
    required this.onSend,
  });

  static const _accent = Color(0xFFDB6234);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: phoneCtrl,
            label: 'Mobile Number',
            hint: '03XXXXXXXXX',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Phone number is required';
              if (!RegExp(r'^(\+92|0092|92|0)?[3][0-9]{9}$')
                  .hasMatch(v.trim())) {
                return 'Enter a valid Pakistani mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Send Reset Code',
            isLoading: isLoading,
            onPressed: onSend,
            accent: _accent,
          ),
        ],
      ),
    );
  }
}

// ── Step 2: OTP + new password form ──────────────────────────────────────────

class _OtpResetForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController otpCtrl;
  final TextEditingController newPasswordCtrl;
  final TextEditingController confirmCtrl;
  final bool isLoading;
  final int resendSeconds;
  final VoidCallback onReset;
  final VoidCallback onResend;
  final Color accent;
  final Color slate;

  const _OtpResetForm({
    required this.formKey,
    required this.otpCtrl,
    required this.newPasswordCtrl,
    required this.confirmCtrl,
    required this.isLoading,
    required this.resendSeconds,
    required this.onReset,
    required this.onResend,
    required this.accent,
    required this.slate,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: otpCtrl,
            label: 'Reset Code',
            hint: 'Enter code',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.lock_clock_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Code is required';
              if (!RegExp(r'^\d{4,10}$').hasMatch(v.trim())) {
                return 'Enter the numeric code sent to you';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: newPasswordCtrl,
            label: 'New Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: confirmCtrl,
            label: 'Confirm New Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != newPasswordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Reset Password',
            isLoading: isLoading,
            onPressed: onReset,
            accent: accent,
          ),
          const SizedBox(height: 18),
          Center(
            child: resendSeconds > 0
                ? Text(
                    'Resend code in ${resendSeconds}s',
                    style: TextStyle(fontSize: 13, color: slate),
                  )
                : GestureDetector(
                    onTap: onResend,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Resend code',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Shared header ─────────────────────────────────────────────────────────────

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSmall;

  const _AuthHeader({
    required this.title,
    required this.subtitle,
    required this.isSmall,
  });

  static const _accent = Color(0xFFDB6234);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isSmall ? 44 : 56,
          height: isSmall ? 44 : 56,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.home_repair_service_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        SizedBox(height: isSmall ? 16 : 24),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmall ? 30 : 36,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

// ── Primary button ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color accent;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: accent.withAlpha(150),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
