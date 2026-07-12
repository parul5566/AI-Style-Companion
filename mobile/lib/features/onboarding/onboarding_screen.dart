/// Onboarding flow — multi-step profile setup.
/// Steps: Gender → Age Range → Style Preferences → Preferred Colors → Budget → Occasions
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/widgets/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final int _totalSteps = 5;

  // State
  String? _gender;
  String? _ageRange;
  final List<String> _selectedStyles = [];
  final List<String> _selectedColors = [];
  double _budgetMin = 50;
  double _budgetMax = 200;
  final List<String> _selectedOccasions = [];
  String? _bodyType;

  static const _genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  static const _ageRanges = ['18-24', '25-34', '35-44', '45-54', '55+'];
  static const _styles = [
    'Minimalist', 'Streetwear', 'Classic', 'Bohemian', 'Smart Casual',
    'Athleisure', 'Vintage', 'Preppy', 'Edgy', 'Luxury', 'Sustainable',
  ];
  static const _colors = [
    'Black', 'White', 'Navy', 'Gray', 'Beige', 'Earth Tones',
    'Pastels', 'Bold Colors', 'Jewel Tones', 'Monochrome', 'Neutrals',
  ];
  static const _occasions = [
    'Work', 'Casual', 'Date Night', 'Workout', 'Travel',
    'Parties', 'Formal Events', 'Everyday', 'Weekend',
  ];
  static const _bodyTypes = ['Slim', 'Athletic', 'Average', 'Curvy', 'Tall', 'Petite'];

  void _next() {
    if (_step < _totalSteps) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _finish() async {
    final provider = context.read<AuthProvider>();
    final success = await provider.completeOnboarding({
      'gender': _gender,
      'age_range': _ageRange,
      'style_preferences': _selectedStyles,
      'preferred_colors': _selectedColors,
      'favorite_occasions': _selectedOccasions,
      'budget_min': _budgetMin.round(),
      'budget_max': _budgetMax.round(),
      'body_type': _bodyType,
    });
    if (!success && mounted) {
      showAppSnackBar(context, provider.errorMessage ?? 'Failed to save', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_step + 1} of ${_totalSteps + 1}'),
        actions: [
          if (_step > 0)
            TextButton(onPressed: _back, child: const Text('Back')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_step + 1) / (_totalSteps + 1),
              backgroundColor: AppTheme.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              minHeight: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStep(),
              ),
            ),
            // Bottom nav
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canProceed() ? _next : null,
                      child: Text(_step == _totalSteps ? 'Finish' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_step) {
      case 0: return _gender != null && _ageRange != null;
      case 1: return _selectedStyles.isNotEmpty;
      case 2: return _selectedColors.isNotEmpty;
      case 3: return true; // Budget always valid
      case 4: return _selectedOccasions.isNotEmpty;
      case 5: return true; // Body type optional
      default: return false;
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildGenderAgeStep();
      case 1: return _buildStylesStep();
      case 2: return _buildColorsStep();
      case 3: return _buildBudgetStep();
      case 4: return _buildOccasionsStep();
      case 5: return _buildBodyTypeStep();
      default: return const SizedBox();
    }
  }

  // ─── Step: Gender + Age ──────────────────────────
  Widget _buildGenderAgeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Let\'s get to know you', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Tell us about yourself so we can personalize your experience.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 32),

        Text('Gender', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genders.map((g) {
            final isSelected = _gender == g;
            return ChoiceChip(
              label: Text(g),
              selected: isSelected,
              onSelected: (_) => setState(() => _gender = g),
              selectedColor: AppTheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        Text('Age Range', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ageRanges.map((a) {
            final isSelected = _ageRange == a;
            return ChoiceChip(
              label: Text(a),
              selected: isSelected,
              onSelected: (_) => setState(() => _ageRange = a),
              selectedColor: AppTheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Step: Styles ────────────────────────────────
  Widget _buildStylesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Style', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Select all styles that resonate with you.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        ChipSelector(
          options: _styles,
          selected: _selectedStyles,
          onToggle: (s) => setState(() {
            if (_selectedStyles.contains(s)) {
              _selectedStyles.remove(s);
            } else {
              _selectedStyles.add(s);
            }
          }),
        ),
      ],
    );
  }

  // ─── Step: Colors ────────────────────────────────
  Widget _buildColorsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color Preferences', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('What colors do you love wearing?',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        ChipSelector(
          options: _colors,
          selected: _selectedColors,
          onToggle: (c) => setState(() {
            if (_selectedColors.contains(c)) {
              _selectedColors.remove(c);
            } else {
              _selectedColors.add(c);
            }
          }),
        ),
      ],
    );
  }

  // ─── Step: Budget ────────────────────────────────
  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Budget', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Help us recommend pieces within your range.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 32),

        GlassCard(
          child: Column(
            children: [
              Text('\$${_budgetMin.round()} — \$${_budgetMax.round()}',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              Text('Min per item', style: Theme.of(context).textTheme.bodySmall),
              Slider(
                value: _budgetMin,
                min: 0, max: 500,
                divisions: 10,
                activeColor: AppTheme.primary,
                label: '\$${_budgetMin.round()}',
                onChanged: (v) => setState(() {
                  _budgetMin = v;
                  if (_budgetMin > _budgetMax) _budgetMax = _budgetMin;
                }),
              ),
              const SizedBox(height: 16),
              Text('Max per item', style: Theme.of(context).textTheme.bodySmall),
              Slider(
                value: _budgetMax,
                min: 50, max: 1000,
                divisions: 19,
                activeColor: AppTheme.accent,
                label: '\$${_budgetMax.round()}',
                onChanged: (v) => setState(() {
                  _budgetMax = v;
                  if (_budgetMax < _budgetMin) _budgetMin = _budgetMax;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Step: Occasions ─────────────────────────────
  Widget _buildOccasionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Lifestyle', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('What occasions do you dress for?',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        ChipSelector(
          options: _occasions,
          selected: _selectedOccasions,
          onToggle: (o) => setState(() {
            if (_selectedOccasions.contains(o)) {
              _selectedOccasions.remove(o);
            } else {
              _selectedOccasions.add(o);
            }
          }),
        ),
      ],
    );
  }

  // ─── Step: Body Type ─────────────────────────────
  Widget _buildBodyTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Body Type (Optional)', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Helps us suggest better fits.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bodyTypes.map((b) {
            final isSelected = _bodyType == b;
            return ChoiceChip(
              label: Text(b),
              selected: isSelected,
              onSelected: (_) => setState(() => _bodyType = b),
              selectedColor: AppTheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text('You\'re all set! Tap Finish to start your style journey.',
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
