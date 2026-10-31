import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/ui/pickers/picker_sheet.dart';
import '../../../../shared/ui/pickers/wheel_picker.dart';
import '../../domain/entities/repeat_rule.dart';

/// Cantidades que ofrece la rueda: «cada 1» a «cada 99».
const int _maxInterval = 99;

const _unitLabels = {
  RepeatUnit.day: 'días',
  RepeatUnit.week: 'semanas',
  RepeatUnit.month: 'meses',
  RepeatUnit.year: 'años',
};

/// Abre el selector «Cada [cantidad] [unidad]» y devuelve la regla elegida, o
/// `null` si se cierra sin aceptar. Sin [initial] arranca en «cada 1 día».
Future<RepeatRule?> showRepeatRulePicker(
  BuildContext context, {
  RepeatRule? initial,
}) {
  return showModalBottomSheet<RepeatRule>(
    context: context,
    // Sobre el Navigator raíz para que el sheet tape el TopBar del shell.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _RepeatRulePickerSheet(
      initial ?? const RepeatRule(interval: 1, unit: RepeatUnit.day),
    ),
  );
}

class _RepeatRulePickerSheet extends StatefulWidget {
  const _RepeatRulePickerSheet(this.initial);

  final RepeatRule initial;

  @override
  State<_RepeatRulePickerSheet> createState() => _RepeatRulePickerSheetState();
}

class _RepeatRulePickerSheetState extends State<_RepeatRulePickerSheet> {
  late int _amountIndex = widget.initial.interval - 1;
  late int _unitIndex = RepeatUnit.values.indexOf(widget.initial.unit);

  late final _amountController = FixedExtentScrollController(
    initialItem: _amountIndex,
  );
  late final _unitController = FixedExtentScrollController(
    initialItem: _unitIndex,
  );

  @override
  void dispose() {
    _amountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PickerSheet(
      title: 'Repetir',
      onConfirm: () => Navigator.of(context).pop(
        RepeatRule(
          interval: _amountIndex + 1,
          unit: RepeatUnit.values[_unitIndex],
        ),
      ),
      child: SizedBox(
        height: WheelPicker.itemExtent * 5,
        child: Stack(
          children: [
            // Banda central que marca la fila seleccionada.
            Center(
              child: IgnorePointer(
                child: Container(
                  height: WheelPicker.itemExtent,
                  decoration: BoxDecoration(
                    color: colors.canvasSoft,
                    borderRadius: AppRadius.brXl,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: WheelPicker(
                    controller: _amountController,
                    itemCount: _maxInterval,
                    labelBuilder: (index) => '${index + 1}',
                    onSelected: (index) => _amountIndex = index,
                  ),
                ),
                Expanded(
                  child: WheelPicker(
                    controller: _unitController,
                    itemCount: RepeatUnit.values.length,
                    labelBuilder: (index) =>
                        _unitLabels[RepeatUnit.values[index]]!,
                    onSelected: (index) => _unitIndex = index,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
