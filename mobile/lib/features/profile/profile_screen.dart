/// Profile screen — view/edit user profile + logout.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_client.dart';
import '../../shared/widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final json = await ApiClient.getProfile();
      _profile = UserProfile.fromJson(json);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingSpinner()
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar + name
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Center(
                        child: Text(
                          (ApiClient.userName?.isNotEmpty == true ? ApiClient.userName![0] : 'U').toUpperCase(),
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(auth.fullName ?? ApiClient.userName ?? 'User',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(auth.email ?? ApiClient.userEmail ?? '',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),

                    if (_isEditing)
                      _buildEditForm()
                    else
                      _buildProfileInfo(),

                    const SizedBox(height: 32),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text('Are you sure you want to log out?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Logout', style: TextStyle(color: AppTheme.error)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await auth.logout();
                          }
                        },
                        icon: const Icon(Icons.logout, color: AppTheme.error),
                        label: const Text('Logout', style: TextStyle(color: AppTheme.error)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileInfo() {
    final p = _profile;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Gender', p?.gender),
          _buildInfoRow('Age Range', p?.ageRange),
          _buildInfoRow('Body Type', p?.bodyType),
          _buildInfoRow('Budget', p?.budgetMin != null && p?.budgetMax != null
              ? '\$${p!.budgetMin} - \$${p.budgetMax}' : null),
          if (p?.stylePreferences != null && p!.stylePreferences!.isNotEmpty)
            _buildInfoRow('Styles', p.stylePreferences!.join(', ')),
          if (p?.preferredColors != null && p!.preferredColors!.isNotEmpty)
            _buildInfoRow('Colors', p.preferredColors!.join(', ')),
          if (p?.favoriteOccasions != null && p!.favoriteOccasions!.isNotEmpty)
            _buildInfoRow('Occasions', p.favoriteOccasions!.join(', ')),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value ?? 'Not set',
                style: TextStyle(
                  color: value != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 14,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return _EditProfileForm(
      profile: _profile,
      onSaved: () {
        setState(() => _isEditing = false);
        _loadProfile();
      },
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  final UserProfile? profile;
  final VoidCallback onSaved;

  const _EditProfileForm({this.profile, required this.onSaved});

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  late TextEditingController _budgetMinCtrl;
  late TextEditingController _budgetMaxCtrl;
  String? _gender;
  String? _ageRange;
  String? _bodyType;
  final List<String> _styles = [];
  final List<String> _colors = [];
  bool _isSaving = false;

  static const _genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  static const _ageRanges = ['18-24', '25-34', '35-44', '45-54', '55+'];
  static const _bodyTypes = ['Slim', 'Athletic', 'Average', 'Curvy', 'Tall', 'Petite'];
  static const _styleOptions = ['Minimalist', 'Streetwear', 'Classic', 'Bohemian', 'Smart Casual',
    'Athleisure', 'Vintage', 'Preppy', 'Edgy', 'Luxury', 'Sustainable'];
  static const _colorOptions = ['Black', 'White', 'Navy', 'Gray', 'Beige', 'Earth Tones',
    'Pastels', 'Bold Colors', 'Jewel Tones', 'Monochrome', 'Neutrals'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _budgetMinCtrl = TextEditingController(text: p?.budgetMin?.toString() ?? '50');
    _budgetMaxCtrl = TextEditingController(text: p?.budgetMax?.toString() ?? '200');
    _gender = p?.gender;
    _ageRange = p?.ageRange;
    _bodyType = p?.bodyType;
    _styles.addAll(p?.stylePreferences ?? []);
    _colors.addAll(p?.preferredColors ?? []);
  }

  @override
  void dispose() {
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ApiClient.updateProfile({
        if (_gender != null) 'gender': _gender,
        if (_ageRange != null) 'age_range': _ageRange,
        if (_bodyType != null) 'body_type': _bodyType,
        'budget_min': int.tryParse(_budgetMinCtrl.text) ?? 50,
        'budget_max': int.tryParse(_budgetMaxCtrl.text) ?? 200,
        'style_preferences': _styles,
        'preferred_colors': _colors,
      });
      if (mounted) showAppSnackBar(context, 'Profile updated!');
      widget.onSaved();
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed to update', isError: true);
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gender
          DropdownButtonFormField<String?>(
            value: _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 12),
          // Age
          DropdownButtonFormField<String?>(
            value: _ageRange,
            decoration: const InputDecoration(labelText: 'Age Range'),
            items: _ageRanges.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (v) => setState(() => _ageRange = v),
          ),
          const SizedBox(height: 12),
          // Body Type
          DropdownButtonFormField<String?>(
            value: _bodyType,
            decoration: const InputDecoration(labelText: 'Body Type'),
            items: _bodyTypes.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) => setState(() => _bodyType = v),
          ),
          const SizedBox(height: 12),
          // Budget
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _budgetMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Budget Min'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _budgetMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Budget Max'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Styles
          Text('Style Preferences', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _styleOptions.map((s) {
              final sel = _styles.contains(s);
              return FilterChip(
                label: Text(s),
                selected: sel,
                onSelected: (_) => setState(() {
                  if (sel) {
                    _styles.remove(s);
                  } else {
                    _styles.add(s);
                  }
                }),
                selectedColor: AppTheme.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Colors
          Text('Preferred Colors', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _colorOptions.map((c) {
              final sel = _colors.contains(c);
              return FilterChip(
                label: Text(c),
                selected: sel,
                onSelected: (_) => setState(() {
                  if (sel) {
                    _colors.remove(c);
                  } else {
                    _colors.add(c);
                  }
                }),
                selectedColor: AppTheme.accent,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
