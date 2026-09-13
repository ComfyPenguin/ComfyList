import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../domain/entities/todo_list_icons.dart';

/// Grid de iconos seleccionables. Cada opción es una superficie circular del
/// DS (canvas + borde hairline); la seleccionada se rellena con el color
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
    required this.onTap,
  });

  final String iconKey;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;
    final borderColor = isDark
        ? colors.ink.withValues(alpha: 0.18)
        : colors.ink.withValues(alpha: 0.12);

    return Semantics(
      button: true,
      selected: selected,
      label: iconKey,
      child: Material(
        color: selected ? colors.primary : colors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brFull,
          side: BorderSide(
            color: selected ? Colors.transparent : borderColor,
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              icon,
              color: selected ? colors.onPrimary : colors.ink,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
