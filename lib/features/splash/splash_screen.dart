import 'package:datasolids_mobile/core/auth/token_manager.dart';
import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Warm auth state from secure storage. The router's `redirect`
    // listens to authStateProvider and will navigate accordingly on
    // the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(tokenManagerProvider).warmFromStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.navy900,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal500),
        ),
      ),
    );
  }
}
