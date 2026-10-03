import 'package:flutter/material.dart';

import '../../app/dunots_theme.dart';

/// Barra principal do Dunots para telas compactas.
///
/// O círculo de seleção é um único elemento animado. Dessa forma, a mudança
/// entre destinos é percebida como continuidade, em vez de quatro indicadores
/// que aparecem e desaparecem independentemente.
class DunotsBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const DunotsBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = <_DunotsNavigationItem>[
    _DunotsNavigationItem(
      label: 'Hoje',
      icon: Icons.today_outlined,
      selectedIcon: Icons.today,
    ),
    _DunotsNavigationItem(
      label: 'Estudar',
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
    ),
    _DunotsNavigationItem(
      label: 'Questões',
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz,
    ),
    _DunotsNavigationItem(
      label: 'Trilhas',
      icon: Icons.route_outlined,
      selectedIcon: Icons.route,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final activeIndex = selectedIndex.clamp(0, _items.length - 1);

    return Semantics(
      container: true,
      label: 'Navegação principal do Dunots',
      child: Material(
        color: DunotsColors.surfaceSidebar,
        child: SizedBox(
          height: 70 + safeBottom,
          child: Padding(
            padding: EdgeInsets.only(bottom: safeBottom),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _items.length;
                final indicatorLeft =
                    (itemWidth * activeIndex) + (itemWidth - 38) / 2;
                final iconLeft =
                    (itemWidth * activeIndex) + (itemWidth - 20) / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Divider(height: 1, color: DunotsColors.border),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
                      left: indicatorLeft,
                      top: -17,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: DunotsColors.emerald,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: DunotsColors.background,
                              width: 4,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x42000000),
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const SizedBox(width: 38, height: 38),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
                      left: iconLeft,
                      top: -8,
                      child: IgnorePointer(
                        child: Icon(
                          _items[activeIndex].selectedIcon,
                          size: 20,
                          color: DunotsColors.background,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_items.length, (index) {
                        final item = _items[index];
                        final selected = index == activeIndex;
                        return Expanded(
                          child: Semantics(
                            button: true,
                            selected: selected,
                            label: item.label,
                            hint: selected
                                ? 'Destino atual'
                                : 'Abrir ${item.label}',
                            child: Tooltip(
                              message: item.label,
                              child: InkWell(
                                onTap: selected
                                    ? null
                                    : () => onSelected(index),
                                child: SizedBox(
                                  height: 70,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 22,
                                        child: selected
                                            ? const SizedBox.shrink()
                                            : Icon(
                                                item.icon,
                                                size: 22,
                                                color: DunotsColors.muted,
                                              ),
                                      ),
                                      const SizedBox(height: 4),
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        curve: Curves.easeOut,
                                        style: TextStyle(
                                          color: selected
                                              ? DunotsColors.mint
                                              : DunotsColors.muted,
                                          fontSize: selected ? 11 : 10.5,
                                          fontWeight: selected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                        child: Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DunotsNavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _DunotsNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
