import 'dart:ui';
import 'package:flutter/material.dart';

/// Satu item pada [FloatingGlassNavBar].
class GlassNavItem {
  final IconData icon; // outlined (tidak aktif)
  final IconData activeIcon; // filled (aktif)
  final String label;
  final Key? widgetKey; // mis. GlobalKey untuk tutorial

  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.widgetKey,
  });
}

/// Floating glassmorphism pill navigation bar yang adaptif Dark / Light Mode.
/// Hanya tampilan: perpindahan tab tetap ditangani oleh [onTap] milik pemanggil.
class FloatingGlassNavBar extends StatelessWidget {
  final bool isDark;
  final int currentIndex;
  final List<GlassNavItem> items;
  final ValueChanged<int> onTap;

  const FloatingGlassNavBar({
    super.key,
    required this.isDark,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  static const double _height = 66;
  static const double _radius = 40;

  @override
  Widget build(BuildContext context) {
    final Color barColor = isDark
        ? const Color(0xFF14161E).withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.82);
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.95);
    final double borderWidth = isDark ? 1.2 : 1.4;
    final BoxShadow shadow = isDark
        ? BoxShadow(
      color: Colors.black.withValues(alpha: 0.40),
      blurRadius: 24,
      offset: const Offset(0, 10),
    )
        : BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 20,
      offset: const Offset(0, 8),
    );
    final Color pillColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.08);
    final Color activeColor =
    isDark ? Colors.white : const Color(0xFF12141A);
    final Color inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.70)
        : const Color(0xFF12141A).withValues(alpha: 0.75);

    // Jaga tata letak kapsul tetap rapi walau skala font aplikasi dibesarkan.
    final MediaQueryData mq = MediaQuery.of(context);
    final MediaQueryData clamped = mq.copyWith(
      textScaler: mq.textScaler.clamp(maxScaleFactor: 1.1),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
      child: MediaQuery(
        data: clamped,
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [shadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < items.length; i++)
                      Expanded(
                        child: _buildItem(
                          i,
                          pillColor,
                          activeColor,
                          inactiveColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
      int index,
      Color pillColor,
      Color activeColor,
      Color inactiveColor,
      ) {
    final GlassNavItem item = items[index];
    final bool selected = index == currentIndex;
    final Color color = selected ? activeColor : inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        key: item.widgetKey,
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? pillColor : Colors.transparent,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? item.activeIcon : item.icon,
                  size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: color,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
