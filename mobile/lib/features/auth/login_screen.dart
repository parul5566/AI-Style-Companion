import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onRegisterTap;
  const LoginScreen({super.key, this.onRegisterTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final success = await provider.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!success && mounted) {
      showAppSnackBar(context, provider.errorMessage ?? 'Login failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / Hero
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text('Welcome Back', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text('Sign in to your AI Style Companion',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textSecondary),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit
                Consumer<AuthProvider>(
                  builder: (_, auth, __) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign In'),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium),
                    GestureDetector(
                      onTap: widget.onRegisterTap,
                      child: const Text('Sign Up',
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
