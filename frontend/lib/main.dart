import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'screens/landing_screen.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const ProviderScope(child: ZoneApp()));
}

class ZoneApp extends ConsumerWidget {
  const ZoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Zone',
      debugShowCheckedModeBanner: false,
      theme: ZoneTheme.light(),
      darkTheme: ZoneTheme.dark(),
      themeMode: themeMode,
      // Logged out → Landing; logged in → Map.
      home: user == null ? const LandingScreen() : const MapScreen(),
    );
  }
}
