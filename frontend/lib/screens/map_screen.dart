import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';
import '../state/app_state.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/radius_slider.dart';
import '../widgets/signal_bottom_sheet.dart';
import '../widgets/sign_in_gate.dart';
import 'create_signal_screen.dart';
import 'chat_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'activity_screen.dart';

/// Home. Full-screen map with the "you" marker, radius rings, and nearby
/// signal pins. This is the heart of the app.
///
/// To use real Google Maps: add a Maps API key to the native projects, then
/// replace [MapPlaceholder] below with a `GoogleMap` widget. The rest of the
/// screen (radius chips, bottom sheet, create flow) stays the same.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // Default center: near a Delhi metro station (matches backend seed).
  final _center = (lat: 28.6139, lng: 77.209);
  int _radius = 500;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await ref.read(signalsProvider.notifier).loadNearby(
          lat: _center.lat,
          lng: _center.lng,
          range: _radius,
        );
  }

  void _onRadiusChanged(int r) {
    setState(() => _radius = r);
    _refresh();
  }

  Future<void> _openSignal(Signal s) async {
    final accepted = await SignalBottomSheet.show(context, s);
    if (accepted == true && mounted) {
      try {
        await ref.read(apiProvider).acceptSignal(s.id);
      } catch (_) {
        // Ignore for the mock/offline case; still open chat.
      }
      ref.read(conversationsProvider.notifier).addOrUpdate(s);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(signal: s)),
      );
    }
  }

  /// Broadcasting a signal requires an account. Guests (reached via "Skip")
  /// see a sign-in prompt instead of the compose screen.
  Future<void> _openCreate() async {
    if (ref.read(authProvider) == null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SignInGate(
            message: 'Sign up or log in to broadcast a signal.',
          ),
        ),
      );
      return;
    }
    final created = await Navigator.of(context).push<Signal>(
      PageRouteBuilder<Signal>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => CreateSignalScreen(center: _center),
        transitionsBuilder: (_, animation, __, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    );
    if (created != null) {
      ref.read(signalsProvider.notifier).addLocal(created);
      ref.read(conversationsProvider.notifier).addOrUpdate(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signals = ref.watch(signalsProvider);
    final user = ref.watch(authProvider);

    // Simple nav: index 0 is the map; others push full screens. Activity,
    // Chat, and Profile require an account — guests see a sign-in prompt
    // instead.
    if (_navIndex == 1) {
      return user == null
          ? SignInGate(
              message:
                  'Sign up or log in to see your accepted and posted signals.',
              onBack: () => setState(() => _navIndex = 0),
            )
          : ActivityScreen(onBack: () => setState(() => _navIndex = 0));
    }
    if (_navIndex == 2) {
      return user == null
          ? SignInGate(
              message: 'Sign up or log in to see your chats.',
              onBack: () => setState(() => _navIndex = 0),
            )
          : ChatListScreen(onBack: () => setState(() => _navIndex = 0));
    }
    if (_navIndex == 3) {
      return user == null
          ? SignInGate(
              message: 'Sign up or log in to view and manage your profile.',
              onBack: () => setState(() => _navIndex = 0),
            )
          : ProfileScreen(onBack: () => setState(() => _navIndex = 0));
    }

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: MapPlaceholder(
                center: _center,
                signals: signals,
                selectedRadius: _radius,
                onPinTap: _openSignal,
              ),
            ),
            // Top bar.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _MapChip(
                      child: Row(
                        children: const [
                          Icon(Icons.my_location,
                              size: 18, color: ZoneColors.primary),
                          SizedBox(width: 6),
                          Text('Near you',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _MapChip(
                      onTap: _refresh,
                      child: const Icon(Icons.refresh,
                          size: 20, color: ZoneColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            // Radius slider (drag to pick anything from 250m up to 5km).
            // Right inset leaves room for the FAB so the two floating
            // controls don't overlap in the same bottom band.
            Positioned(
              left: 16,
              right: 160,
              bottom: 24,
              child: RadiusSlider(
                value: _radius,
                onChanged: _onRadiusChanged,
                compact: true,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ZoneColors.accent,
        foregroundColor: Colors.white,
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(
              icon: Icon(Icons.bolt_outlined), label: 'Activity'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: child,
        ),
      ),
    );
  }
}

