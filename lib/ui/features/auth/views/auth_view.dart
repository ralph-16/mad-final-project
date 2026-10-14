import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

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
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
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
                      obscureText: _obscure,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) =>
                          (v == null || v.length < 6)
                              ? 'Password must be at least 6 characters.'
                              : null,
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
                          : () => setState(() {
                                _isSignup = !_isSignup;
                              }),
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
}
