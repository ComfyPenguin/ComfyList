import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Rueda vertical de selección (carrusel): el elemento centrado es el elegido y
/// el resto queda atenuado.
class WheelPicker extends StatelessWidget {
  const WheelPicker({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.labelBuilder,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onSelected;

  static const double itemExtent = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      diameterRatio: 1.8,
      useMagnifier: true,
      magnification: 1.15,
      overAndUnderCenterOpacity: 0.4,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) => Center(
          child: Text(
            labelBuilder(index),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMdStrong.copyWith(color: colors.ink),
          ),
        ),
      ),
    );
  }
}
