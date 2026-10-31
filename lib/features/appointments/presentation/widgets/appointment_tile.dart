import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/text/date_format.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/swipe_actions_card.dart';
import '../../../../shared/ui/text/animated_strikethrough_text.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/appointment.dart';

/// Item de la lista de citas con hora, título y ubicación.
class AppointmentTile extends ConsumerWidget {
  const AppointmentTile({
    super.key,
    required this.appointment,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
    this.onLongPress,
    this.groupIndex = 0,
    this.groupSize = 1,
    this.topSeparationProgress = 1,
    this.bottomSeparationProgress = 1,
    this.onRevealProgressChanged,
  }) : assert(groupIndex >= 0),
       assert(groupSize > 0),
       assert(groupIndex < groupSize),
       assert(topSeparationProgress >= 0 && topSeparationProgress <= 1),
       assert(bottomSeparationProgress >= 0 && bottomSeparationProgress <= 1);

  final Appointment appointment;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final int groupIndex;
  final int groupSize;
  final double topSeparationProgress;
  final double bottomSeparationProgress;
  final ValueChanged<double>? onRevealProgressChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final muted = colors.muted;
    final done = appointment.isDone;
    final titleStyle = AppTypography.bodyMdStrong;

    final use24H = ref.watch(use24HourFormatProvider);
    final invertActions = ref.watch(
      settingsOrDefaultsProvider.select((s) => s.invertSwipeActions),
    );
    final timeText = formatClockTime(
      appointment.dateTime,
      use24HourFormat: use24H,
    );
    final periodText = formatClockPeriod(
      appointment.dateTime,
      use24HourFormat: use24H,
    );
    final timeStyle = AppTypography.displayMd.copyWith(
      color: done ? muted : colors.ink,
      height: 1,
    );
    final periodStyle = AppTypography.caption.copyWith(
      color: muted,
      height: 1,
      fontWeight: FontWeight.w500,
    );

    return SwipeActionsCard(
      onTap: onTap,
      onLongPress: onLongPress,
      onDelete: onDelete,
      onComplete: onComplete,
      isDone: done,
      invertActions: invertActions,
      groupIndex: groupIndex,
      groupSize: groupSize,
      topSeparationProgress: topSeparationProgress,
      bottomSeparationProgress: bottomSeparationProgress,
      onRevealProgressChanged: onRevealProgressChanged,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 88,
            child: use24H
                ? Center(
                    child: Text(
                      timeText,
                      style: timeStyle,
                      textAlign: TextAlign.center,
                      softWrap: false,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeText,
                        style: timeStyle,
                        textAlign: TextAlign.center,
                        softWrap: false,
                      ),
                      Text(
                        periodText,
                        style: periodStyle,
                        textAlign: TextAlign.center,
                        softWrap: false,
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colors.cardBorder,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedStrikethroughText(
                  text: appointment.title,
                  style: titleStyle.copyWith(color: colors.ink),
                  done: done,
                  doneColor: muted,
                ),
                if (appointment.location != null &&
                    appointment.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: muted,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            appointment.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm.copyWith(color: muted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (appointment.repeatRule != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Icon(Icons.repeat_rounded, size: 18, color: muted),
            ),
          if (appointment.description != null &&
              appointment.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Icon(Icons.notes_rounded, size: 18, color: muted),
            ),
        ],
      ),
    );
  }
}
