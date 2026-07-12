/// Welcome/Splash screen — shown on first launch before auth.
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, size: 56, color: Colors.white),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'AI Style\nCompanion',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your personal AI stylist. Get outfit recommendations, discover missing pieces, and try on looks virtually.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
                ),

                const Spacer(flex: 2),

                // Features list
                _buildFeatureRow(Icons.checkroom, 'Smart Wardrobe', 'AI auto-tags your clothes'),
                const SizedBox(height: 16),
                _buildFeatureRow(Icons.auto_awesome, 'AI Outfit Engine', 'Personalized recommendations'),
                const SizedBox(height: 16),
                _buildFeatureRow(Icons.shopping_bag, 'Shop Missing Pieces', 'Fill your wardrobe gaps'),
                const SizedBox(height: 16),
                _buildFeatureRow(Icons.face, 'Virtual Try-On', 'See it before you buy'),

                const Spacer(flex: 2),

                // Buttons
                ElevatedButton(
                  onPressed: onGetStarted,
                  child: const Text('Get Started'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium),
                    GestureDetector(
                      onTap: onLogin,
                      child: const Text('Sign In',
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
