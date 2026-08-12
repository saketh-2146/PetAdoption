import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petconnect/l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  String? _selectedRole; // 'user' or 'admin'

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedRole == null) {
      setState(() => _error = l10n.selectRoleError);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRole == 'admin' && _email.text.trim().toLowerCase() != 'admin2026@petconnect.com') {
      setState(() => _error = l10n.adminAccessDenied);
      return;
    }
    
    // Save selected role in AppState before authenticating
    context.read<AppState>().loginRole = _selectedRole;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signIn(email: _email.text, password: _password.text, role: _selectedRole);
      // AuthGate listens to authStateChanges and will navigate automatically.
    } catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (_email.text.trim().isEmpty) {
      setState(() => _error = l10n.enterEmailFirst);
      return;
    }
    try {
      await _auth.sendPasswordReset(_email.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.passwordResetSent)),
        );
      }
    } catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    }
  }

  Future<void> _signInWithGoogle() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedRole == null) {
      setState(() => _error = l10n.selectRoleFirst);
      return;
    }

    if (_selectedRole == 'admin') {
      setState(() => _error = l10n.adminEmailOnly);
      return;
    }

    context.read<AppState>().loginRole = _selectedRole;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signInWithGoogle(role: _selectedRole);
      // AuthGate will navigate
    } catch (e) {
      final msg = AuthService.friendlyError(e);
      setState(() => _error = msg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.pets, size: 32, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(l10n.loginTitle, style: nunito(size: 26, weight: FontWeight.w900, color: textColor)),
                const SizedBox(height: 4),
                Text(l10n.loginSubtitle,
                    style: outfit(size: 14, color: AppColors.muted)),
                const SizedBox(height: 24),
                
                // Role Selector
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard(
                        role: 'user',
                        title: l10n.userRole,
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoleCard(
                        role: 'seller',
                        title: l10n.sellerRole,
                        icon: Icons.storefront_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoleCard(
                        role: 'admin',
                        title: l10n.adminRole,
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.emailLabel, prefixIcon: const Icon(Icons.mail_outline)),
                  validator: (v) => (v == null || !v.contains('@')) ? l10n.invalidEmail : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? l10n.invalidPassword : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text(l10n.forgotPassword, style: nunito(size: 14, weight: FontWeight.w700, color: AppColors.secondary)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: outfit(size: 13, color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: l10n.signInButton,
                    onPressed: _submit,
                    isLoading: _loading,
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.warmBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(l10n.orOption, style: outfit(size: 14, color: AppColors.muted)),
                    ),
                    const Expanded(child: Divider(color: AppColors.warmBorder)),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithGoogle,
                    icon: _loading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', width: 24, height: 24),
                    label: Text(_loading ? l10n.signingIn : l10n.continueGoogle, style: nunito(size: 16, weight: FontWeight.w800, color: AppColors.dark)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.warmBorder, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(l10n.noAccountText, style: outfit(size: 14, color: AppColors.muted)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        ),
                        child: Text(l10n.signUpText, style: nunito(size: 14, weight: FontWeight.w800, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({required String role, required String title, required IconData icon}) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          if (_error == AppLocalizations.of(context)!.selectRoleError) {
            _error = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.warmBorder,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? Colors.white : AppColors.muted),
            const SizedBox(height: 8),
            Text(
              title, 
              style: nunito(size: 14, weight: FontWeight.w800, color: isSelected ? Colors.white : AppColors.darkMid),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
