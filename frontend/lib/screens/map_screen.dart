import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';
import '../state/app_state.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/radius_slider.dart';
import '../widgets/signal_bottom_sheet.dart';
import '../widgets/sign_in_gate.dart';
import '../widgets/zone_nav_bar.dart';
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
  double _refreshTurns = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() => _refreshTurns += 1);
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
    final user = ref.watch(authProvider);
    final chatCount = ref.watch(conversationsProvider).length;

    // Activity, Chat, and Profile require an account — guests see a sign-in
    // prompt in their place. The nav bar stays put across all tabs.
    final Widget tab = switch (_navIndex) {
      1 => user == null
          ? const SignInGate(
              message:
                  'Sign up or log in to see your accepted and posted signals.',
              showBack: false,
            )
          : const ActivityScreen(),
      2 => user == null
          ? const SignInGate(
              message: 'Sign up or log in to see your chats.',
              showBack: false,
            )
          : const ChatListScreen(),
      3 => user == null
          ? const SignInGate(
              message: 'Sign up or log in to view and manage your profile.',
              showBack: false,
            )
          : const ProfileScreen(),
      // Builder so _buildMap reads MediaQuery from inside the Scaffold body
      // (where extendBody has added the nav bar's height as padding).
      _ => Builder(builder: _buildMap),
    };

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_navIndex),
          child: _navIndex == 0 ? tab : _ClearOfNavBar(child: tab),
        ),
      ),
      floatingActionButton: AnimatedScale(
        scale: _navIndex == 0 ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: FloatingActionButton.extended(
          backgroundColor: context.zc.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          onPressed: _navIndex == 0 ? _openCreate : null,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      bottomNavigationBar: ZoneNavBar(
        selectedIndex: _navIndex,
        onSelected: (i) => setState(() => _navIndex = i),
        items: [
          const ZoneNavItem(
              icon: Icons.map_outlined,
              selectedIcon: Icons.map_rounded,
              label: 'Map'),
          const ZoneNavItem(
              icon: Icons.bolt_outlined,
              selectedIcon: Icons.bolt_rounded,
              label: 'Activity'),
          ZoneNavItem(
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: 'Chat',
              badge: user == null ? 0 : chatCount),
          const ZoneNavItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    final signals = ref.watch(signalsProvider);
    final zc = context.zc;
    return SizedBox.expand(
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
                  _GlassChip(
                    child: Row(
                      children: [
                        Icon(Icons.near_me_rounded,
                            size: 18, color: zc.primary),
                        const SizedBox(width: 8),
                        Text('Near you',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: zc.textPrimary)),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            key: ValueKey(signals.length),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: zc.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${signals.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: zc.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _GlassChip(
                    onTap: _refresh,
                    child: AnimatedRotation(
                      turns: _refreshTurns,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOutCubic,
                      child: Icon(Icons.refresh_rounded,
                          size: 20, color: zc.textPrimary),
                    ),
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
            // extendBody puts the nav bar's height in the bottom padding.
            bottom: MediaQuery.paddingOf(context).bottom + 12,
            child: _GlassChip(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 2),
              child: RadiusSlider(
                value: _radius,
                onChanged: _onRadiusChanged,
                compact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pads a tab so its content ends above the floating nav bar, and removes
/// that padding from MediaQuery so nested Scaffolds don't apply it twice.
class _ClearOfNavBar extends StatelessWidget {
  const _ClearOfNavBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: context.zc.background,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: child,
        ),
      ),
    );
  }
}

/// Frosted-glass floating control used over the map.
class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    final radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: zc.surface.withValues(alpha: 0.82),
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: zc.border.withValues(alpha: 0.6)),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
