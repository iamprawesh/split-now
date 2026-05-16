import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_widgets.dart';
import '../main.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: authState.isLoading
                    ? AlwaysStoppedAnimation(0)
                    : AlwaysStoppedAnimation(0),
                builder: (context, child) => Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      size: 44, color: accent),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SplitEase',
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w700,
                  color: textPrimary, letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Split expenses with friends, easily.',
                style: TextStyle(fontSize: 15, color: textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: redAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(authState.error!,
                              style: const TextStyle(color: redAccent, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              LoadingButton(
                isLoading: authState.isLoading,
                label: 'Continue with Google',
                onPressed: ref.read(authProvider.notifier).signInWithGoogle,
                backgroundColor: Colors.white,
                foregroundColor: textPrimary,
              ),
              const SizedBox(height: 12),
              LoadingButton(
                isLoading: authState.isLoading,
                label: 'Continue with Apple',
                loadingLabel: 'Signing in...',
                onPressed: ref.read(authProvider.notifier).signInWithApple,
                backgroundColor: textPrimary,
                icon: Icons.apple,
              ),
              const Spacer(),
              Text(
                'By continuing, you agree to our Terms & Privacy Policy.',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
