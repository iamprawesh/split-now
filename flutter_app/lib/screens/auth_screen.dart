import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_widgets.dart';
import '../main.dart';
import 'dashboard_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _dialogShowing = false;

  void _showLoadingDialog() {
    if (_dialogShowing) return;
    _dialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (_) => const SignInLoadingDialog(),
    ).then((_) => _dialogShowing = false);
  }

  void _dismissLoadingDialog() {
    if (_dialogShowing && mounted) {
      _dialogShowing = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? cardBgDark : Colors.white;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.isLoading == false && next.isLoading) {
        _showLoadingDialog();
      } else if (prev?.isLoading == true && !next.isLoading) {
        _dismissLoadingDialog();
        if (next.isAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else if (next.isAuthenticated) {
        _dismissLoadingDialog();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    surfaceBgDark,
                    surfaceBgDark,
                    cardBgDark,
                  ]
                : [
                    const Color(0xFFEEF0FF),
                    const Color(0xFFF8F9FA),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                left: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, Color(0xFF7C80F5)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Split Now',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: isDark ? textPrimaryDark : textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Split expenses with friends, easily.',
                      style: TextStyle(
                        fontSize: 14,
                        color: (isDark ? textSecondaryDark : textSecondary).withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (authState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: redAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: redAccent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 18, color: redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(authState.error!,
                                    style: const TextStyle(
                                        color: redAccent, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : ref.read(authProvider.notifier).signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cardColor,
                                foregroundColor: isDark ? textPrimaryDark : textPrimary,
                                elevation: 0,
                                disabledBackgroundColor: cardColor.withValues(alpha: 0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: isDark ? borderDark : Colors.black, width: 1.5),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata,
                                      size: 24, color: isDark ? textPrimaryDark : textPrimary),
                                  const SizedBox(width: 8),
                                  const Text('Continue with Google',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : ref.read(authProvider.notifier).signInWithApple,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : textPrimary,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                elevation: 0,
                                disabledBackgroundColor:
                                    (isDark ? Colors.white : textPrimary).withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.apple, size: 20),
                                  SizedBox(width: 8),
                                  Text('Continue with Apple',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'By continuing, you agree to our Terms & Privacy Policy.',
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? textSecondaryDark : textSecondary).withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
