import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ZoneNavItem {
  const ZoneNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge = 0,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badge; // 0 hides the badge
}

/// Floating frosted nav bar. The selected tab widens into a pill showing its
/// label while the others shrink to icons; widths animate so the pill
/// appears to slide between tabs. Icons bounce on selection and an optional
/// count badge pops in/out.
class ZoneNavBar extends StatelessWidget {
  const ZoneNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ZoneNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _duration = Duration(milliseconds: 380);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    final radius = BorderRadius.circular(28);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 66,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: zc.surface.withValues(alpha: 0.86),
                  borderRadius: radius,
                  border: Border.all(color: zc.border.withValues(alpha: 0.7)),
                ),
                child: LayoutBuilder(builder: (context, c) {
                  // Selected tab gets ~38% of the width; the rest share the
                  // remainder. Animating widths is what makes the pill glide.
                  final selectedW = c.maxWidth * 0.38;
                  final otherW =
                      (c.maxWidth - selectedW) / (items.length - 1);
                  return Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        AnimatedContainer(
                          duration: _duration,
                          curve: _curve,
                          width: i == selectedIndex ? selectedW : otherW,
                          child: _NavButton(
                            item: items[i],
                            selected: i == selectedIndex,
                            onTap: () {
                              if (i == selectedIndex) return;
                              HapticFeedback.selectionClick();
                              onSelected(i);
                            },
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ZoneNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    final color = selected ? zc.primary : zc.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: ZoneNavBar._duration,
          curve: ZoneNavBar._curve,
          decoration: BoxDecoration(
            color: selected
                ? zc.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BouncingIcon(
                key: ValueKey(selected),
                icon: selected ? item.selectedIcon : item.icon,
                color: color,
                bounce: selected,
                badge: item.badge,
              ),
              Flexible(
                child: AnimatedSize(
                  duration: ZoneNavBar._duration,
                  curve: ZoneNavBar._curve,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 260),
                            builder: (_, v, child) =>
                                Opacity(opacity: v, child: child),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon that springs from small to full size when it becomes selected, with
/// an optional count badge that scales in and out.
class _BouncingIcon extends StatelessWidget {
  const _BouncingIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.bounce,
    required this.badge,
  });

  final IconData icon;
  final Color color;
  final bool bounce;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: bounce ? 0.6 : 1, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: color, size: 24),
          Positioned(
            right: -8,
            top: -5,
            child: AnimatedScale(
              scale: badge > 0 ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17),
                height: 17,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ZoneColors.event,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: context.zc.surface, width: 2),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
