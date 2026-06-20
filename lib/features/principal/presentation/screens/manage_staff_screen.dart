import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/core/widgets/section_scaffold.dart';
import 'package:bantay_eskwela/core/enums/user_role.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';
import 'package:bantay_eskwela/features/principal/presentation/providers/staff_providers.dart';

class ManageStaffScreen extends ConsumerStatefulWidget {
  const ManageStaffScreen({super.key});
  @override
  ConsumerState<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends ConsumerState<ManageStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.guidance;
  bool _isCreating = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);
    try {
      await ref.read(staffRepositoryProvider).createStaffAccount(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _nameController.text,
            role: _role,
          );
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _toast('Staff account created!');
    } catch (e) {
      _toast(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _handleDelete(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff Account'),
        content: Text(
            'Permanently delete $name? They will immediately lose all access. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(staffRepositoryProvider).deleteStaff(uid);
      _toast('Staff account deleted.');
    } catch (e) {
      _toast('Delete failed: $e', error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppTheme.forest));
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffStreamProvider);

    return CenteredColumn(
      children: [
        FormCard(
          icon: Icons.person_add,
          title: 'Create Staff Account',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z .,'-]")),
                    LengthLimitingTextInputFormatter(100),
                  ],
                  decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder()),
                  validator: InputValidators.validateName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder()),
                  validator: InputValidators.validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Temporary Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: InputValidators.validatePassword,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: _role,
                  decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: UserRole.guidance, child: Text('Guidance')),
                    DropdownMenuItem(
                        value: UserRole.guard, child: Text('Guard')),
                  ],
                  onChanged: (v) =>
                      setState(() => _role = v ?? UserRole.guidance),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isCreating ? null : _handleCreate,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.person_add),
                  label: Text(_isCreating ? 'Creating...' : 'Create Account'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const SectionTitle('Staff Accounts'),
        staffAsync.when(
          data: (staff) {
            if (staff.isEmpty) {
              return const Card(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No staff accounts yet.'))));
            }
            return Column(
              children: staff.map((s) {
                final role = s['role'] as String? ?? '';
                final isGuidance = role == 'guidance';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isGuidance
                              ? AppTheme.forest
                              : AppTheme.gold)
                          .withOpacity(0.15),
                      child: Icon(
                          isGuidance ? Icons.support_agent : Icons.security,
                          color: isGuidance ? AppTheme.forest : AppTheme.gold),
                    ),
                    title: Text(s['fullName'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s['email']} • ${role.toUpperCase()}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _handleDelete(s['id'] as String,
                          s['fullName'] as String? ?? 'this staff'),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}
