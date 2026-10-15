import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../../../core/theme_controller.dart';

/// Login + signup in one screen (toggle), email/password only per spec.
/// Labels stay visible; errors render inline under the form.
class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignup = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          icon: Icon(context
                              .watch<ThemeController>()
                              .toggleIcon),
                          tooltip: context
                              .watch<ThemeController>()
                              .toggleTooltip,
                          onPressed: () => context
                              .read<ThemeController>()
                              .toggle(),
                        ),
                      ],
                    ),
                    const Icon(Icons.event_outlined,
                        size: 56, semanticLabel: 'EventHub logo'),
                    const SizedBox(height: 12),
                    Text('EventHub',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text(
                      'Find school events. Register. Get reminded.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@school.edu',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      enabled: !vm.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      onChanged: (_) => vm.clearError(),
                      validator: (v) =>
                          (v == null || !v.contains('@') || !v.contains('.'))
                              ? 'Enter a valid email address.'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText:
                            _isSignup ? 'At least 6 characters' : 'Your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          tooltip:
                              _obscure ? 'Show password' : 'Hide password',
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      enabled: !vm.isLoading,
                      obscureText: _obscure,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.password],
                      onChanged: (_) => vm.clearError(),
                      validator: (v) =>
                          (v == null || v.length < 6)
                              ? 'Password must be at least 6 characters.'
                              : null,
                    ),
                    if (!_isSignup)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: vm.isLoading
                              ? null
                              : () => _openResetDialog(context),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: vm.isLoading
                          ? null
                          : () => _submit(context, vm),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        child: vm.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : Text(_isSignup
                                ? 'Create account'
                                : 'Log in'),
                      ),
                    ),
                    TextButton(
                      onPressed: vm.isLoading
                          ? null
                          : () {
                                vm.clearError();
                                setState(() {
                                  _isSignup = !_isSignup;
                                });
                              },
                      child: Text(_isSignup
                          ? 'Already have an account? Log in'
                          : 'New here? Create an account'),
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

  Future<void> _submit(BuildContext context, AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = _isSignup
        ? await vm.signUp(_email.text, _password.text)
        : await vm.signIn(_email.text, _password.text);
    if (ok && context.mounted) {
      TextInput.finishAutofillContext();
    }
  }

  Future<void> _openResetDialog(BuildContext context) async {
    context.read<AuthViewModel>().clearResetMessages();
    await showDialog<void>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(initialEmail: _email.text),
    );
    if (context.mounted) {
      context.read<AuthViewModel>().clearResetMessages();
    }
  }
}

/// Forgot-password dialog: confirm the account email, request the reset
/// link, and report success/failure inline without leaving login.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});
  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final sent = vm.resetInfo != null;
    return AlertDialog(
      title: const Text('Reset password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!sent)
              const Text(
                'Enter your account email and we will send a reset link.',
              ),
            if (!sent) const SizedBox(height: 12),
            if (!sent)
              TextFormField(
                controller: _email,
                enabled: !vm.isLoading,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@school.edu',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofocus: true,
                validator: (v) =>
                    (v == null || !v.contains('@') || !v.contains('.'))
                        ? 'Enter a valid email address.'
                        : null,
              ),
            if (vm.resetError != null) ...[
              const SizedBox(height: 8),
              Text(
                vm.resetError!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (sent) ...[
              const SizedBox(height: 4),
              Text(vm.resetInfo!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(sent ? 'Done' : 'Cancel'),
        ),
        if (!sent)
          FilledButton(
            onPressed: vm.isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    await vm.sendPasswordReset(_email.text);
                  },
            child: vm.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : const Text('Send reset link'),
          ),
      ],
    );
  }
}
