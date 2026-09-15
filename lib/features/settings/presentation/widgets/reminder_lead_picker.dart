import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/ui/pickers/picker_sheet.dart';
import '../../../../shared/ui/pickers/wheel_picker.dart';

/// Lo que devuelve el selector de recordatorio personalizado.
sealed class ReminderLeadChoice {
  const ReminderLeadChoice();
}

/// El usuario eligió un margen, en minutos antes de la cita.
class ReminderLeadChosen extends ReminderLeadChoice {
  const ReminderLeadChosen(this.minutes);

  final int minutes;
}

/// El usuario quiso dejar la cita sin recordatorio personalizado.
class ReminderLeadCleared extends ReminderLeadChoice {
  const ReminderLeadCleared();
}

/// Unidad de la rueda de cantidad. Los minutos van de 5 en 5 —para un aviso da
/// igual 43 que 45— y las horas y los días no pasan de lo que tiene sentido
/// avisar por adelantado.
enum _ReminderUnit {
  minutes('minutos', 1),
  hours('horas', 60),
  days('días', 1440);

  const _ReminderUnit(this.label, this.factor);

  final String label;

  /// Minutos que vale cada unidad.
  final int factor;

  List<int> get amounts => switch (this) {
    minutes => List.generate(11, (index) => (index + 1) * 5),
    hours => List.generate(23, (index) => index + 1),
    days => List.generate(7, (index) => index + 1),
  };
}

/// Abre el selector de recordatorio personalizado —cantidad y unidad— y devuelve
/// lo que eligió el usuario, o `null` si se cierra sin aceptar.
///
/// Con [removable] —cuando la cita ya tiene un personalizado puesto— el sheet
/// ofrece quitarlo, que es la única forma de deshacerlo: el chip de Ajustes
/// abre este selector tanto si hay valor como si no.
Future<ReminderLeadChoice?> showReminderLeadPicker(
  BuildContext context, {
  required int initialMinutes,
  required bool removable,
}) {
  return showModalBottomSheet<ReminderLeadChoice>(
    context: context,
    // Sobre el Navigator raíz para que el sheet tape el TopBar del shell.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _ReminderLeadPickerSheet(
      initialMinutes: initialMinutes,
      removable: removable,
    ),
  );
}

/// Unidad y cantidad con las que abrir la rueda para [minutes].
///
/// Un margen que no cae en ninguna cantidad ofrecida —uno guardado por una
/// versión vieja o tocado a mano— se abre en minutos con la más cercana, en vez
/// de dejar la rueda en un hueco que no existe.
(_ReminderUnit, int) wheelPositionFor(int minutes) {
  for (final unit in _ReminderUnit.values.reversed) {
    final amount = minutes ~/ unit.factor;
    if (minutes % unit.factor == 0 && unit.amounts.contains(amount)) {
      return (unit, unit.amounts.indexOf(amount));
    }
  }

  final amounts = _ReminderUnit.minutes.amounts;
  var closest = 0;
  for (var i = 1; i < amounts.length; i++) {
    if ((amounts[i] - minutes).abs() < (amounts[closest] - minutes).abs()) {
      closest = i;
    }
  }
  return (_ReminderUnit.minutes, closest);
}

class _ReminderLeadPickerSheet extends StatefulWidget {
  const _ReminderLeadPickerSheet({
    required this.initialMinutes,
    required this.removable,
  });

  final int initialMinutes;
  final bool removable;

  @override
  State<_ReminderLeadPickerSheet> createState() =>
      _ReminderLeadPickerSheetState();
}

class _ReminderLeadPickerSheetState extends State<_ReminderLeadPickerSheet> {
  late _ReminderUnit _unit;
  late int _amountIndex;

  /// La rueda de cantidad se rehace al cambiar de unidad —tiene otras
  /// cantidades—, así que el controlador se reemplaza con ella.
  late FixedExtentScrollController _amountController;
  late final FixedExtentScrollController _unitController;

  @override
  void initState() {
    super.initState();
    final (unit, index) = wheelPositionFor(widget.initialMinutes);
    _unit = unit;
    _amountIndex = index;
    _amountController = FixedExtentScrollController(initialItem: index);
    _unitController = FixedExtentScrollController(
      initialItem: _ReminderUnit.values.indexOf(unit),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  int get _minutes => _unit.amounts[_amountIndex] * _unit.factor;

  void _selectUnit(int index) {
    final unit = _ReminderUnit.values[index];
    if (unit == _unit) return;

    // Cambiar de unidad es cambiar cómo se dice el mismo margen, así que la
    // cantidad se convierte; la que salga puede no existir en la rueda nueva
    // —no hay 0,75 horas— y entonces se queda la más cercana.
    final amounts = unit.amounts;
    final converted = _minutes / unit.factor;
    final closest = amounts.reduce(
      (a, b) => (b - converted).abs() < (a - converted).abs() ? b : a,
    );
    final amount = amounts.indexOf(closest);

    _amountController.dispose();
    setState(() {
      _unit = unit;
      _amountIndex = amount;
      _amountController = FixedExtentScrollController(initialItem: amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PickerSheet(
      title: 'Recordatorio',
      onConfirm: () => Navigator.of(context).pop(ReminderLeadChosen(_minutes)),
      secondaryLabel: widget.removable ? 'Quitar' : null,
      onSecondary: widget.removable
          ? () => Navigator.of(context).pop(const ReminderLeadCleared())
          : null,
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
                    // Otra unidad es otra rueda: se rehace en la cantidad que
                    // toca en vez de recolocar la que estaba.
                    key: ValueKey(_unit),
                    controller: _amountController,
                    itemCount: _unit.amounts.length,
                    labelBuilder: (index) => '${_unit.amounts[index]}',
                    onSelected: (index) => _amountIndex = index,
                  ),
                ),
                Expanded(
                  child: WheelPicker(
                    controller: _unitController,
                    itemCount: _ReminderUnit.values.length,
                    labelBuilder: (index) => _ReminderUnit.values[index].label,
                    onSelected: _selectUnit,
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
