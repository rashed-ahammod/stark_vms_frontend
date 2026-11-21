import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.sessionExpired = false});

  /// `true` when the user landed here because their token was rejected.
  final bool sessionExpired;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(loginFormProvider.notifier).clearErrors();

    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }

    // The password goes straight into the request and is never stored.
    await ref.read(loginFormProvider.notifier).submit(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
    // On success AuthNotifier flips the gate to the vehicle list, so there is
    // nothing to navigate here.
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final formState = ref.watch(loginFormProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.truck,
                        size: 20,
                        color: theme.colorScheme.primaryForeground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Stark Group VMS',
                      style: theme.textTheme.h3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to manage the vehicle fleet',
                  style: theme.textTheme.muted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ShadCard(
                  padding: const EdgeInsets.all(28),
                  child: ShadForm(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.sessionExpired &&
                            formState.generalError == null) ...[
                          const ShadAlert(
                            icon: Icon(LucideIcons.clock),
                            title: Text('Session expired'),
                            description: Text(
                              'Your session is no longer valid. Please sign in again.',
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (formState.generalError != null) ...[
                          ShadAlert.destructive(
                            icon: const Icon(LucideIcons.circleAlert),
                            title: const Text('Could not sign in'),
                            description: Text(formState.generalError!),
                          ),
                          const SizedBox(height: 20),
                        ],
                        ShadInputFormField(
                          id: 'username',
                          controller: _usernameController,
                          label: const Text('Username'),
                          placeholder: const Text('e.g. admin'),
                          forceErrorText: formState.fieldErrors['username'],
                          onChanged: (_) => ref
                              .read(loginFormProvider.notifier)
                              .clearFieldError('username'),
                          leading: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              LucideIcons.user,
                              size: 15,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v.trim().isEmpty) {
                              return 'Username is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ShadInputFormField(
                          id: 'password',
                          controller: _passwordController,
                          label: const Text('Password'),
                          placeholder: const Text('Enter your password'),
                          obscureText: _obscurePassword,
                          forceErrorText: formState.fieldErrors['password'],
                          onChanged: (_) => ref
                              .read(loginFormProvider.notifier)
                              .clearFieldError('password'),
                          leading: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              LucideIcons.lock,
                              size: 15,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            child: Icon(
                              _obscurePassword
                                  ? LucideIcons.eye
                                  : LucideIcons.eyeOff,
                              size: 15,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!formState.isSubmitting) {
                              _submit();
                            }
                          },
                          validator: (v) {
                            if (v.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ShadButton(
                          onPressed: formState.isSubmitting ? null : _submit,
                          leading: formState.isSubmitting
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.logIn, size: 16),
                          child: Text(
                            formState.isSubmitting
                                ? 'Signing in...'
                                : 'Sign In',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
