import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/text/capitalize.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_stroke.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../buttons/primary_button.dart';

/// Abre el selector de fecha del DS y devuelve la fecha elegida, o `null` si
/// se cancela. [today] es el día que el calendario marca como hoy: solo lo
/// inyectan los tests, en la app va `null` y manda el reloj.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? today,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    // Sobre el Navigator raíz para que el sheet tape el TopBar del shell.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _DatePickerSheet(
      initialDate: initialDate,
      today: today ?? DateTime.now(),
    ),
  );
}

/// Abre el selector de hora del DS y devuelve la hora elegida, o `null` si se
/// cancela. [use24HourFormat] decide si se ofrecen 24 horas o 12 más AM/PM.
Future<TimeOfDay?> showAppTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  bool use24HourFormat = true,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    // Sobre el Navigator raíz para que el sheet tape el TopBar del shell.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _TimePickerSheet(
      initialTime: initialTime,
      use24HourFormat: use24HourFormat,
    ),
  );
}

/// Estructura común de los sheets del DS: título centrado, contenido y
/// acciones (CTA pill + cancelar).
class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.onConfirm,
    required this.child,
  });

  final String title;
  final VoidCallback onConfirm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.displaySm.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Aceptar', onPressed: onConfirm, expand: true),
        ],
      ),
    );
  }
}

/// Botón circular con borde hairline (icon-button-circular del DS).
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brFull,
          side: BorderSide(
            color: colors.cardBorder,
            width: AppStroke.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 20, color: colors.ink),
          ),
        ),
      ),
    );
  }
}

/// Rueda vertical de selección (carrousel): el elemento centrado es el
/// elegido y el resto queda atenuado.
class _WheelPicker extends StatelessWidget {
  const _WheelPicker({
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

/// Calendario del DS: navegación por mes, semana empezando en lunes y día
/// seleccionado en primary (hoy queda marcado con borde hairline).
class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({required this.initialDate, required this.today});

  final DateTime initialDate;

  /// Día que cuenta como hoy, con la hora que traiga: dentro se normaliza.
  final DateTime today;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  /// Medianoche del día que cuenta como hoy.
  DateTime get _today =>
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  /// Lunes de la semana de [_today] — solo para los nombres de los días.
  /// Con el constructor en vez de restar días: en los cambios de hora la
  /// medianoche se desplaza.
  DateTime get _weekStart =>
      DateTime(_today.year, _today.month, _today.day - (_today.weekday - 1));

  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _month = DateTime(_selected.year, _selected.month);
  }

  void _goToMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final monthText = capitalize(DateFormat.yMMMM('es_ES').format(_month));

    return _PickerSheet(
      title: 'Fecha',
      onConfirm: () => Navigator.of(context).pop(_selected),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Mes anterior',
                onTap: () => _goToMonth(-1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthText,
                    style: AppTypography.bodyMdStrong.copyWith(
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
              _CircleIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Mes siguiente',
                onTap: () => _goToMonth(1),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _weekdayRow(),
          const SizedBox(height: AppSpacing.xxs),
          ..._monthRows(),
        ],
      ),
    );
  }

  Widget _weekdayRow() {
    final colors = context.colors;
    final style = AppTypography.sectionLabel(colors.muted);

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: Text(
                DateFormat.E(
                  'es_ES',
                ).format(_weekStart.add(Duration(days: i))).substring(0, 1)
                    .toUpperCase(),
                style: style,
              ),
            ),
          ),
      ],
    );
  }

  /// Semanas del mes visible, siempre de 7 columnas y empezando en lunes.
  List<Widget> _monthRows() {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // weekday: 1 = lunes … 7 = domingo.
    final leadingBlanks = DateTime(_month.year, _month.month).weekday - 1;

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const SizedBox(),
      for (var day = 1; day <= daysInMonth; day++) _dayCell(day),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final end = i + 7 <= cells.length ? i + 7 : cells.length;
      final rowCells = cells.sublist(i, end);
      while (rowCells.length < 7) {
        rowCells.add(const SizedBox());
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.xxs));
      rows.add(
        Row(children: [for (final cell in rowCells) Expanded(child: cell)]),
      );
    }
    return rows;
  }

  Widget _dayCell(int day) {
    final colors = context.colors;
    final date = DateTime(_month.year, _month.month, day);
    final selected = date == _selected;
    final isToday = date == _today;

    return SizedBox(
      height: 44,
      child: Center(
        child: Material(
          color: selected ? colors.primary : Colors.transparent,
          shape: CircleBorder(
            side: !selected && isToday
                ? BorderSide(
                    color: colors.cardBorder,
                    width: AppStroke.hairline,
                  )
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() => _selected = date),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  '$day',
                  style: AppTypography.bodySmStrong.copyWith(
                    color: selected ? colors.onPrimary : colors.ink,
                    fontWeight: selected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector de hora del DS: ruedas verticales de hora y minutos, más AM/PM
/// cuando el ajuste de hora es de 12 horas.
class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({
    required this.initialTime,
    required this.use24HourFormat,
  });

  final TimeOfDay initialTime;
  final bool use24HourFormat;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _periodController;

  /// Índice de la rueda de horas: 0-23 en 24 h y 0-11 (1-12) en 12 h.
  late int _hourIndex;
  late int _minuteIndex;

  /// 0 = AM, 1 = PM. Solo se usa en formato de 12 horas.
  int _periodIndex = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTime;

    if (widget.use24HourFormat) {
      _hourIndex = initial.hour;
    } else {
      _hourIndex = (initial.hour % 12 == 0 ? 12 : initial.hour % 12) - 1;
      _periodIndex = initial.hour >= 12 ? 1 : 0;
    }
    _minuteIndex = initial.minute;

    _hourController = FixedExtentScrollController(initialItem: _hourIndex);
    _minuteController = FixedExtentScrollController(initialItem: _minuteIndex);
    _periodController = FixedExtentScrollController(initialItem: _periodIndex);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  TimeOfDay get _selectedTime {
    if (widget.use24HourFormat) {
      return TimeOfDay(hour: _hourIndex, minute: _minuteIndex);
    }
    final hour24 = (_hourIndex + 1) % 12 + (_periodIndex == 1 ? 12 : 0);
    return TimeOfDay(hour: hour24, minute: _minuteIndex);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _PickerSheet(
      title: 'Hora',
      onConfirm: () => Navigator.of(context).pop(_selectedTime),
      child: SizedBox(
        height: _WheelPicker.itemExtent * 5,
        child: Stack(
          children: [
            // Banda central que marca la fila seleccionada.
            Center(
              child: IgnorePointer(
                child: Container(
                  height: _WheelPicker.itemExtent,
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
                  child: _WheelPicker(
                    controller: _hourController,
                    itemCount: widget.use24HourFormat ? 24 : 12,
                    labelBuilder: (index) => widget.use24HourFormat
                        ? index.toString().padLeft(2, '0')
                        : '${index + 1}',
                    onSelected: (index) => setState(() => _hourIndex = index),
                  ),
                ),
                Text(
                  ':',
                  style: AppTypography.displayMd.copyWith(color: colors.muted),
                ),
                Expanded(
                  child: _WheelPicker(
                    controller: _minuteController,
                    itemCount: 60,
                    labelBuilder: (index) => index.toString().padLeft(2, '0'),
                    onSelected: (index) => setState(() => _minuteIndex = index),
                  ),
                ),
                if (!widget.use24HourFormat)
                  SizedBox(
                    width: 76,
                    child: _WheelPicker(
                      controller: _periodController,
                      itemCount: 2,
                      labelBuilder: (index) => index == 0 ? 'AM' : 'PM',
                      onSelected: (index) =>
                          setState(() => _periodIndex = index),
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
