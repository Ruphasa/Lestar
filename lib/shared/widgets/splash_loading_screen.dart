import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// Layar splash/loading anggun dengan logo-full dan ornamen Art Nouveau.
class SplashLoadingScreen extends StatelessWidget {
  const SplashLoadingScreen({
    super.key,
    this.message = 'Setiap kilogram punya jalur nilai',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFEB),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Full Lestar
              Image.asset(
                'assets/logo-full.png',
                width: 240,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/logo.png',
                  width: 96,
                  height: 96,
                ),
              ),
              const SizedBox(height: 36),
              // Subtle circular loading in forest green
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E432A)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: LestarType.caption(
                  color: const Color(0xFF1E432A).withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
