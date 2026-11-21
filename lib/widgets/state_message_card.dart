import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// How the icon badge at the top of a [StateMessageCard] is tinted.
enum StateTone { neutral, destructive, progress }

/// A centred card used for every "nothing here yet / something went wrong /
/// loading" state.
///
/// The fleet and form screens each had their own near-identical version of
/// this; sharing one keeps the icon size, spacing and button row identical
/// whichever state the user lands on.
class StateMessageCard extends StatelessWidget {
  const StateMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = StateTone.neutral,
    this.actions = const [],
    this.maxWidth = 460,
  });

  /// Shown inside the tinted badge. Ignored when [tone] is
  /// [StateTone.progress], which shows a spinner instead.
  final IconData icon;
  final String title;
  final String message;
  final StateTone tone;

  /// Buttons laid out in a centred, wrapping row beneath the message.
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDestructive = tone == StateTone.destructive;

    final badgeColor = isDestructive
        ? theme.colorScheme.destructive.withValues(alpha: 0.1)
        : theme.colorScheme.secondary;
    final iconColor = isDestructive
        ? theme.colorScheme.destructive
        : theme.colorScheme.mutedForeground;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ShadCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: tone == StateTone.progress
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Icon(icon, size: 26, color: iconColor),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: theme.textTheme.h4,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.muted,
                  textAlign: TextAlign.center,
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
