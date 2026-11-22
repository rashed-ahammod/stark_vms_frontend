import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'config/app_colors.dart';
import 'providers/auth_providers.dart';
import 'providers/theme_providers.dart';
import 'repositories/prefs_store.dart';
import 'repositories/session_store.dart';
import 'screens/login_screen.dart';
import 'screens/vehicle_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The session box holds the Bearer token so a page refresh does not sign the
  // user out. It is opened before the app starts so the first frame already
  // knows whether a session exists.
  await Hive.initFlutter();
  final sessionBox = await Hive.openBox<dynamic>(SessionStore.boxName);
  // Appearance is read before the first frame so the app never flashes the
  // wrong theme on start-up.
  final prefsBox = await Hive.openBox<dynamic>(PrefsStore.boxName);

  runApp(
    ProviderScope(
      overrides: [
        sessionBoxProvider.overrideWithValue(sessionBox),
        prefsBoxProvider.overrideWithValue(prefsBox),
      ],
      child: const StarkVmsApp(),
    ),
  );
}

class StarkVmsApp extends ConsumerWidget {
  const StarkVmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShadApp(
      title: 'Stark Group VMS',
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(themeModeProvider),
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        // Slate dark uses one near-black for both card and background, which
        // would leave every panel flush with the page; lifting card a step
        // keeps the same layering the light theme has.
        colorScheme: const ShadSlateColorScheme.dark(
          card: AppSurface.darkCard,
          popover: AppSurface.darkCard,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Chooses between the login screen and the fleet screens based on the session.
///
/// Every route into the app goes through here, so a 401 anywhere — which clears
/// the stored token — lands the user back on login without any screen having to
/// navigate manually.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return switch (auth.status) {
      AuthStatus.checking => const _SessionCheckScreen(),
      AuthStatus.authenticated => const VehicleListScreen(),
      AuthStatus.unauthenticated => LoginScreen(
        sessionExpired: auth.sessionExpired,
      ),
    };
  }
}

/// Shown for the moment a restored token is validated against `/auth/me`.
class _SessionCheckScreen extends StatelessWidget {
  const _SessionCheckScreen();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: AppSurface.of(context).page,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.truck,
                size: 24,
                color: theme.colorScheme.primaryForeground,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 16),
            Text('Restoring your session', style: theme.textTheme.muted),
          ],
        ),
      ),
    );
  }
}
