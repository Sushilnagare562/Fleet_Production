import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/fleet_logo.dart';
import '../admin/admin_home_screen.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _licenseController = TextEditingController();
  bool _obscurePassword = true;

  // 'ADMIN' | 'DRIVER' | 'COMPANY_EMPLOYEE'
  String _selectedRole = 'DRIVER';

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _vehicleController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      companyName: _companyController.text.trim(),
      role: _selectedRole,
      vehicleNumber: _vehicleController.text.trim().isEmpty ? null : _vehicleController.text.trim(),
      licenseNumber: _licenseController.text.trim().isEmpty ? null : _licenseController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => auth.isAdmin ? const AdminHomeScreen() : const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(auth.error ?? context.l10n.registrationFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;
    final isDriver = _selectedRole == 'DRIVER';

    return Scaffold(
      backgroundColor: context.fleet.background,
      appBar: AppBar(title: Text(l10n.createYourAccount)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 8),
                    const Center(child: LogisticFleetLogo(size: 60, showPin: false)),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        l10n.setUpYourCompany,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.fleet.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        l10n.accountSetupMinute,
                        style: TextStyle(color: context.fleet.textSecondary, fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // --- Company / transport name -----------------------------------
                    _SectionLabel(text: l10n.sectionCompany),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: l10n.companyTransport,
                        prefixIcon: const Icon(Icons.apartment_rounded),
                        helperText: l10n.companyNameHint,
                        helperMaxLines: 2,
                      ),
                      validator: (v) => Validators.required(v, message: l10n.enterCompanyName),
                    ),
                    const SizedBox(height: 20),

                    // --- Role selector -------------------------------------------------
                    _SectionLabel(text: l10n.sectionYourRole),
                    const SizedBox(height: 8),
                    _RoleSelector(
                      selected: _selectedRole,
                      onChanged: (role) => setState(() => _selectedRole = role),
                    ),
                    const SizedBox(height: 20),

                    _SectionLabel(text: l10n.sectionYourDetails),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: l10n.fullName, prefixIcon: const Icon(Icons.badge_outlined)),
                      validator: (v) => Validators.required(v, message: l10n.enterFullName),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.mail_outline_rounded)),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: l10n.phoneNumber, prefixIcon: const Icon(Icons.call_outlined)),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        helperText: l10n.passwordRule,
                        helperMaxLines: 2,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    if (isDriver) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vehicleController,
                        decoration: InputDecoration(
                            labelText: l10n.vehicleNumberOpt, prefixIcon: const Icon(Icons.local_shipping_outlined)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _licenseController,
                        decoration:
                            InputDecoration(labelText: l10n.licenseNumberOpt, prefixIcon: const Icon(Icons.badge_outlined)),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.loading ? null : _submit,
                        child: auth.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(l10n.createAccount, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: context.fleet.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Two/three-way role picker rendered as tappable cards rather than a plain
/// dropdown, so the choice that decides tenant permissions is unmistakable
/// at a glance.
class _RoleSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roles = [
      (value: 'ADMIN', label: l10n.roleAdmin, subtitle: l10n.roleAdminSub, icon: Icons.admin_panel_settings_rounded),
      (value: 'DRIVER', label: l10n.roleDriver, subtitle: l10n.roleDriverSub, icon: Icons.local_shipping_rounded),
      (value: 'COMPANY_EMPLOYEE', label: l10n.roleEmployee, subtitle: l10n.roleEmployeeSub, icon: Icons.badge_rounded),
    ];
    return Row(
      children: roles.map((role) {
        final isSelected = selected == role.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: role.value == roles.last.value ? 0 : 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onChanged(role.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : context.fleet.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColors.primary : context.fleet.divider),
                  boxShadow: isSelected ? AppShadows.brand : null,
                ),
                child: Column(
                  children: [
                    Icon(role.icon, size: 22, color: isSelected ? Colors.white : AppColors.primary),
                    const SizedBox(height: 6),
                    Text(
                      role.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : context.fleet.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isSelected ? Colors.white70 : context.fleet.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
