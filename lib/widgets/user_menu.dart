import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/auth_models.dart';

/// Initials badge + popover holding the account details and Sign out.
///
/// The top bar previously carried the user icon, the name and a separate
/// logout button inline, which left little room for the primary actions.
/// Collapsing them into one avatar keeps the bar readable at every width.
class UserMenu extends StatefulWidget {
  const UserMenu({super.key, required this.user, required this.onLogout});

  final AuthUser user;
  final VoidCallback onLogout;

  @override
  State<UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<UserMenu> {
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
