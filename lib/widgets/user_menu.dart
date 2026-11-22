import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/auth_models.dart';
import '../providers/theme_providers.dart';

/// Initials badge + popover holding the account details and Sign out.
///
/// The top bar previously carried the user icon, the name and a separate
/// logout button inline, which left little room for the primary actions.
/// Collapsing them into one avatar keeps the bar readable at every width.
class UserMenu extends ConsumerStatefulWidget {
  const UserMenu({super.key, required this.user, required this.onLogout});

  final AuthUser user;
  final VoidCallback onLogout;

  @override
  ConsumerState<UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends ConsumerState<UserMenu> {
  final ShadPopoverController _controller = ShadPopoverController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Up to two initials from the display name, e.g. "Administrator" -> "A",
  /// "Rashed Ahammod" -> "RA".
  String get _initials {
    final parts = widget.user.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadPopover(
      controller: _controller,
      padding: const EdgeInsets.all(8),
      popover: (context) => SizedBox(
        width: 232,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.displayName,
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${widget.user.username}',
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const ShadSeparator.horizontal(margin: EdgeInsets.zero),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Text(
                'APPEARANCE',
                style: theme.textTheme.muted.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            _AppearanceChoices(
              selected: ref.watch(themeModeProvider),
              onSelected: (mode) =>
                  ref.read(themeModeProvider.notifier).setMode(mode),
            ),
            const SizedBox(height: 8),
            const ShadSeparator.horizontal(margin: EdgeInsets.zero),
            const SizedBox(height: 6),
            ShadButton.ghost(
              onPressed: () {
                _controller.hide();
                widget.onLogout();
              },
              mainAxisAlignment: MainAxisAlignment.start,
              leading: const Icon(LucideIcons.logOut, size: 15),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
      child: ShadTooltip(
        builder: (_) => const Text('Account'),
        child: ShadIconButton.ghost(
          onPressed: _controller.toggle,
          padding: EdgeInsets.zero,
          icon: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: Text(
              _initials,
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Light / Dark / System segmented choice inside the account menu.
class _AppearanceChoices extends StatelessWidget {
  const _AppearanceChoices({required this.selected, required this.onSelected});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;

  static const _options = <(ThemeMode, IconData, String)>[
    (ThemeMode.light, LucideIcons.sun, 'Light'),
    (ThemeMode.dark, LucideIcons.moon, 'Dark'),
    (ThemeMode.system, LucideIcons.monitor, 'Auto'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final (mode, icon, label) in _options) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: mode == selected
                        ? theme.colorScheme.secondary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: mode == selected
                          ? theme.colorScheme.border
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 15,
                        color: mode == selected
                            ? theme.colorScheme.foreground
                            : theme.colorScheme.mutedForeground,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: theme.textTheme.muted.copyWith(
                          fontSize: 11,
                          fontWeight: mode == selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (mode != _options.last.$1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
