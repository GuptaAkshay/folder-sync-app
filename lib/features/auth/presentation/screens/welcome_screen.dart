import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/providers/app_providers.dart';

/// Welcome / Onboarding screen (FR-0).
///
/// Shown to first-time users or users with no Google account connected.
/// Displays app branding, value proposition, and "Connect with Google" CTA.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: const Icon(
                  Icons.sync_alt,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // App name
              Text(
                'FolderSync',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),

              // Welcome heading
              Text(
                'Welcome to FolderSync',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Keep your folders perfectly in sync between Google Drive '
                'and your Android device, effortlessly. Simple setup, '
                'secure transfers.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Connect with Google button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          try {
                            await ref.read(authStateProvider.notifier).signIn();
                            // Auth guard will redirect to dashboard
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Sign-in failed: ${e.toString()}',
                                  ),
                                  backgroundColor: AppTheme.statusError,
                                ),
                              );
                            }
                          }
                        },
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textOnPrimary,
                          ),
                        )
                      : const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(
                    isLoading ? 'Connecting...' : 'Connect with Google',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Terms and privacy
              Text(
                'By connecting, you agree to our Terms of Service '
                'and Privacy Policy.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Privacy link
              TextButton.icon(
                onPressed: () {
                  // TODO: Open privacy info
                },
                icon: const Icon(Icons.shield_outlined, size: 16),
                label: const Text('Learn more about privacy and security'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Tagline
              Text(
                'Seamless • Secure • Fast',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
