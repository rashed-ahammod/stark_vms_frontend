import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../config/app_colors.dart';
import '../providers/auth_providers.dart';
import '../providers/theme_providers.dart';

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
    // Below this width the brand panel is dropped and the form takes the full
    // screen with its own compact header.
    final isWide = MediaQuery.sizeOf(context).width >= 920;
    final theme = ShadTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppSurface.of(context).page,
      // Stacked so the appearance toggle can sit in the corner without
      // disturbing the centred form.
      body: Stack(
        children: [
          Positioned.fill(
            child: isWide
                ? Row(
                    children: [
                      const Expanded(flex: 5, child: _BrandPanel()),
                      Expanded(
                        flex: 4,
                        child: _buildFormArea(showBrand: false),
                      ),
                    ],
                  )
                : _buildFormArea(showBrand: true),
          ),
          Positioned(
            top: 12,
            right: 16,
            child: SafeArea(
              child: ShadTooltip(
                builder: (_) => Text(
                  isDark ? 'Switch to light mode' : 'Switch to dark mode',
                ),
                child: ShadIconButton.ghost(
                  onPressed: () => ref
                      .read(themeModeProvider.notifier)
                      .toggle(theme.brightness),
                  icon: Icon(
                    isDark ? LucideIcons.sun : LucideIcons.moon,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormArea({required bool showBrand}) {
    final theme = ShadTheme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBrand) ...[
                // Narrow layout has no brand panel, so the mark goes here.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _BrandMark(size: 40, iconSize: 20),
                    const SizedBox(width: 12),
                    // Flexible so a larger OS text scale shrinks the title
                    // instead of overflowing the 400px column.
                    Flexible(
                      child: Text(
                        'Stark Group VMS',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.h3.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              Text(
                'Sign in',
                style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.w700),
                textAlign: showBrand ? TextAlign.center : TextAlign.start,
              ),
              const SizedBox(height: 6),
              Text(
                'Use your administrator account to manage the fleet.',
                style: theme.textTheme.muted,
                textAlign: showBrand ? TextAlign.center : TextAlign.start,
              ),
              const SizedBox(height: 24),
              _buildFormCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final theme = ShadTheme.of(context);
    final formState = ref.watch(loginFormProvider);

    return ShadCard(
      padding: const EdgeInsets.all(26),
      child: ShadForm(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // An expired session is informational; a failed attempt replaces
            // it, so only one banner is ever shown.
            if (widget.sessionExpired && formState.generalError == null) ...[
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
              enabled: !formState.isSubmitting,
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
              enabled: !formState.isSubmitting,
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
              trailing: ShadTooltip(
                builder: (_) => Text(
                  _obscurePassword ? 'Show password' : 'Hide password',
                ),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 15,
                    color: theme.colorScheme.mutedForeground,
                  ),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.logIn, size: 16),
              child: Text(
                formState.isSubmitting ? 'Signing in...' : 'Sign In',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rounded square holding the fleet icon, reused by the login header and
/// the brand panel.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size, required this.iconSize});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(size / 3.6),
      ),
      child: Icon(
        LucideIcons.truck,
        size: iconSize,
        color: theme.colorScheme.primaryForeground,
      ),
    );
  }
}

/// Dark panel shown beside the sign-in form on wide screens.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Deliberately the same dark gradient in both themes: it is a branded
      // panel, not a themed surface. In light mode it anchors the page; in
      // dark it sits a step above the near-black background.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.truck,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Stark Group VMS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                const Text(
                  'Vehicle Management System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Fleet registry, driver assignment and operational status '
                  'for the whole Stark Group fleet.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                const _BrandFeature(
                  icon: LucideIcons.clipboardList,
                  title: 'Fleet registry',
                  subtitle: 'Plates, specifications and fuel in one record.',
                ),
                const SizedBox(height: 22),
                const _BrandFeature(
                  icon: LucideIcons.userCheck,
                  title: 'Driver assignment',
                  subtitle: 'Keep the assigned driver and contact up to date.',
                ),
                const SizedBox(height: 22),
                const _BrandFeature(
                  icon: LucideIcons.activity,
                  title: 'Operational status',
                  subtitle: 'Availability, active use and maintenance at a glance.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandFeature extends StatelessWidget {
  const _BrandFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
