import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'screens/vehicle_list_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: StarkVmsApp(),
    ),
  );
}

class StarkVmsApp extends StatelessWidget {
  const StarkVmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Stark Group VMS',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(),
      ),
      home: const VehicleListScreen(),
    );
  }
}
