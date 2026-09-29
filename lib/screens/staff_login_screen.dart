import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_store.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final theme = Theme.of(context);
    return Scaffold(
      // Cổng staff có địa chỉ riêng nên không còn trang nào để quay lại.
      appBar: AppBar(title: const Text('EmbraceAI Staff Portal')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.shield_outlined, size: 48),
                    Gap.m,
                    Text(
                      'Authorised staff only',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap.s,
                    Text(
                      'Staff accounts are provisioned by the project administrator.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Gap.xl,
                    TextFormField(
                      controller: _emailController,
                      enabled: !auth.isBusy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Staff email',
                        prefixIcon: Icon(Icons.mail_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter a valid staff email'
                          : null,
                    ),
                    Gap.m,
                    TextFormField(
                      controller: _passwordController,
                      enabled: !auth.isBusy,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password'
                          : null,
                      onFieldSubmitted: (_) => _submit(auth),
                    ),
                    if (auth.error case final error?) ...[
                      Gap.m,
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          error,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                    Gap.l,
                    FilledButton.icon(
                      onPressed: auth.isBusy ? null : () => _submit(auth),
                      icon: auth.isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(auth.isBusy ? 'Signing in...' : 'Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthStore auth) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await auth.signInStaff(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }
}
