import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../domain/entities/todo_list_icons.dart';

/// Grid de iconos seleccionables. El seleccionado se resalta con el color
/// primario del tema.
class IconPicker extends StatelessWidget {
  const IconPicker({
    super.key,
    required this.selectedKey,
    required this.onChanged,
  });

  final String selectedKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = TodoListIcons.all.entries.toList(growable: false);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final e in entries)
          _IconChoice(
            iconKey: e.key,
            icon: e.value,
            selected: e.key == selectedKey,
            selectedBg: colors.primary,
            selectedFg: colors.onPrimary,
            unselectedBg: colors.canvasSoft,
            unselectedFg: colors.ink,
            onTap: () => onChanged(e.key),
          ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconKey,
    required this.icon,
    required this.selected,
    required this.selectedBg,
    required this.selectedFg,
    required this.unselectedBg,
    required this.unselectedFg,
    required this.onTap,
  });

  final String iconKey;
  final IconData icon;
  final bool selected;
  final Color selectedBg;
  final Color selectedFg;
  final Color unselectedBg;
  final Color unselectedFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: iconKey,
      child: Material(
        color: selected ? selectedBg : unselectedBg,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              icon,
              color: selected ? selectedFg : unselectedFg,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
