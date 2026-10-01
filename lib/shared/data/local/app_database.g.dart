// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 4,
      maxTextLength: 8,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _appointmentsCompletionEnabledMeta =
      const VerificationMeta('appointmentsCompletionEnabled');
  @override
  late final GeneratedColumn<bool> appointmentsCompletionEnabled =
      GeneratedColumn<bool>(
        'appointments_completion_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("appointments_completion_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _completedToBottomMeta = const VerificationMeta(
    'completedToBottom',
  );
  @override
  late final GeneratedColumn<bool> completedToBottom = GeneratedColumn<bool>(
    'completed_to_bottom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed_to_bottom" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _appointmentsCompletedToBottomMeta =
      const VerificationMeta('appointmentsCompletedToBottom');
  @override
  late final GeneratedColumn<bool> appointmentsCompletedToBottom =
      GeneratedColumn<bool>(
        'appointments_completed_to_bottom',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("appointments_completed_to_bottom" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _appointmentsTodayOnTopMeta =
      const VerificationMeta('appointmentsTodayOnTop');
  @override
  late final GeneratedColumn<bool> appointmentsTodayOnTop =
      GeneratedColumn<bool>(
        'appointments_today_on_top',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("appointments_today_on_top" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _invertSwipeActionsMeta =
      const VerificationMeta('invertSwipeActions');
  @override
  late final GeneratedColumn<bool> invertSwipeActions = GeneratedColumn<bool>(
    'invert_swipe_actions',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("invert_swipe_actions" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _use24HourFormatMeta = const VerificationMeta(
    'use24HourFormat',
  );
  @override
  late final GeneratedColumn<bool> use24HourFormat = GeneratedColumn<bool>(
    'use24_hour_format',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use24_hour_format" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _appointmentReminderMinutesMeta =
      const VerificationMeta('appointmentReminderMinutes');
  @override
  late final GeneratedColumn<String> appointmentReminderMinutes =
      GeneratedColumn<String>(
        'appointment_reminder_minutes',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('30'),
      );
  static const VerificationMeta _longPressHintSeenMeta = const VerificationMeta(
    'longPressHintSeen',
  );
  @override
  late final GeneratedColumn<bool> longPressHintSeen = GeneratedColumn<bool>(
    'long_press_hint_seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("long_press_hint_seen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _trashRetentionDaysMeta =
      const VerificationMeta('trashRetentionDays');
  @override
  late final GeneratedColumn<int> trashRetentionDays = GeneratedColumn<int>(
    'trash_retention_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    themeMode,
    notificationsEnabled,
    appointmentsCompletionEnabled,
    completedToBottom,
    appointmentsCompletedToBottom,
    appointmentsTodayOnTop,
    invertSwipeActions,
    use24HourFormat,
    appointmentReminderMinutes,
    longPressHintSeen,
    trashRetentionDays,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('appointments_completion_enabled')) {
      context.handle(
        _appointmentsCompletionEnabledMeta,
        appointmentsCompletionEnabled.isAcceptableOrUnknown(
          data['appointments_completion_enabled']!,
          _appointmentsCompletionEnabledMeta,
        ),
      );
    }
    if (data.containsKey('completed_to_bottom')) {
      context.handle(
        _completedToBottomMeta,
        completedToBottom.isAcceptableOrUnknown(
          data['completed_to_bottom']!,
          _completedToBottomMeta,
        ),
      );
    }
    if (data.containsKey('appointments_completed_to_bottom')) {
      context.handle(
        _appointmentsCompletedToBottomMeta,
        appointmentsCompletedToBottom.isAcceptableOrUnknown(
          data['appointments_completed_to_bottom']!,
          _appointmentsCompletedToBottomMeta,
        ),
      );
    }
    if (data.containsKey('appointments_today_on_top')) {
      context.handle(
        _appointmentsTodayOnTopMeta,
        appointmentsTodayOnTop.isAcceptableOrUnknown(
          data['appointments_today_on_top']!,
          _appointmentsTodayOnTopMeta,
        ),
      );
    }
    if (data.containsKey('invert_swipe_actions')) {
      context.handle(
        _invertSwipeActionsMeta,
        invertSwipeActions.isAcceptableOrUnknown(
          data['invert_swipe_actions']!,
          _invertSwipeActionsMeta,
        ),
      );
    }
    if (data.containsKey('use24_hour_format')) {
      context.handle(
        _use24HourFormatMeta,
        use24HourFormat.isAcceptableOrUnknown(
          data['use24_hour_format']!,
          _use24HourFormatMeta,
        ),
      );
    }
    if (data.containsKey('appointment_reminder_minutes')) {
      context.handle(
        _appointmentReminderMinutesMeta,
        appointmentReminderMinutes.isAcceptableOrUnknown(
          data['appointment_reminder_minutes']!,
          _appointmentReminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('long_press_hint_seen')) {
      context.handle(
        _longPressHintSeenMeta,
        longPressHintSeen.isAcceptableOrUnknown(
          data['long_press_hint_seen']!,
          _longPressHintSeenMeta,
        ),
      );
    }
    if (data.containsKey('trash_retention_days')) {
      context.handle(
        _trashRetentionDaysMeta,
        trashRetentionDays.isAcceptableOrUnknown(
          data['trash_retention_days']!,
          _trashRetentionDaysMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      appointmentsCompletionEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}appointments_completion_enabled'],
      )!,
      completedToBottom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed_to_bottom'],
      )!,
      appointmentsCompletedToBottom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}appointments_completed_to_bottom'],
      )!,
      appointmentsTodayOnTop: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}appointments_today_on_top'],
      )!,
      invertSwipeActions: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}invert_swipe_actions'],
      )!,
      use24HourFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use24_hour_format'],
      )!,
      appointmentReminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_reminder_minutes'],
      )!,
      longPressHintSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}long_press_hint_seen'],
      )!,
      trashRetentionDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trash_retention_days'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;

  /// 'system' | 'light' | 'dark'
  final String themeMode;

  /// Los avisos vienen apagados de fábrica: el permiso del sistema se pide al
  /// encenderlos (ver `NotificationsService`).
  final bool notificationsEnabled;
  final bool appointmentsCompletionEnabled;

  /// Si `true`, las tareas completadas van al final de la lista.
  final bool completedToBottom;

  /// Si `true`, las citas completadas van al final de la lista de su día.
  final bool appointmentsCompletedToBottom;

  /// Si `true`, el día de hoy va primero en la lista de citas, aunque haya
  /// días pasados por delante.
  final bool appointmentsTodayOnTop;

  /// Si `true`, las acciones del deslizamiento se invierten: eliminar queda
  /// a la izquierda y completar a la derecha (y viceversa en `false`).
  final bool invertSwipeActions;

  /// Si `true`, las horas de las citas se muestran en formato 24H.
  /// Si `false`, se muestran en formato 12H con AM/PM.
  final bool use24HourFormat;

  /// Minutos de antelación de los recordatorios de una cita (0 = a su hora),
  /// separados por comas y como mucho tres. Un valor vacío es «sin avisos».
  final String appointmentReminderMinutes;

  /// Si `true`, ya se mostró la pista de mantener pulsada una tarjeta para
  /// editarla y no vuelve a aparecer.
  final bool longPressHintSeen;

  /// Días que aguanta un borrado en la papelera antes de que la app la vacíe
  /// sola. `0` es «nunca»; de fábrica, un mes.
  final int trashRetentionDays;
  final DateTime updatedAt;
  const SettingsRow({
    required this.id,
    required this.themeMode,
    required this.notificationsEnabled,
    required this.appointmentsCompletionEnabled,
    required this.completedToBottom,
    required this.appointmentsCompletedToBottom,
    required this.appointmentsTodayOnTop,
    required this.invertSwipeActions,
    required this.use24HourFormat,
    required this.appointmentReminderMinutes,
    required this.longPressHintSeen,
    required this.trashRetentionDays,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme_mode'] = Variable<String>(themeMode);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['appointments_completion_enabled'] = Variable<bool>(
      appointmentsCompletionEnabled,
    );
    map['completed_to_bottom'] = Variable<bool>(completedToBottom);
    map['appointments_completed_to_bottom'] = Variable<bool>(
      appointmentsCompletedToBottom,
    );
    map['appointments_today_on_top'] = Variable<bool>(appointmentsTodayOnTop);
    map['invert_swipe_actions'] = Variable<bool>(invertSwipeActions);
    map['use24_hour_format'] = Variable<bool>(use24HourFormat);
    map['appointment_reminder_minutes'] = Variable<String>(
      appointmentReminderMinutes,
    );
    map['long_press_hint_seen'] = Variable<bool>(longPressHintSeen);
    map['trash_retention_days'] = Variable<int>(trashRetentionDays);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      notificationsEnabled: Value(notificationsEnabled),
      appointmentsCompletionEnabled: Value(appointmentsCompletionEnabled),
      completedToBottom: Value(completedToBottom),
      appointmentsCompletedToBottom: Value(appointmentsCompletedToBottom),
      appointmentsTodayOnTop: Value(appointmentsTodayOnTop),
      invertSwipeActions: Value(invertSwipeActions),
      use24HourFormat: Value(use24HourFormat),
      appointmentReminderMinutes: Value(appointmentReminderMinutes),
      longPressHintSeen: Value(longPressHintSeen),
      trashRetentionDays: Value(trashRetentionDays),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      appointmentsCompletionEnabled: serializer.fromJson<bool>(
        json['appointmentsCompletionEnabled'],
      ),
      completedToBottom: serializer.fromJson<bool>(json['completedToBottom']),
      appointmentsCompletedToBottom: serializer.fromJson<bool>(
        json['appointmentsCompletedToBottom'],
      ),
      appointmentsTodayOnTop: serializer.fromJson<bool>(
        json['appointmentsTodayOnTop'],
      ),
      invertSwipeActions: serializer.fromJson<bool>(json['invertSwipeActions']),
      use24HourFormat: serializer.fromJson<bool>(json['use24HourFormat']),
      appointmentReminderMinutes: serializer.fromJson<String>(
        json['appointmentReminderMinutes'],
      ),
      longPressHintSeen: serializer.fromJson<bool>(json['longPressHintSeen']),
      trashRetentionDays: serializer.fromJson<int>(json['trashRetentionDays']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'themeMode': serializer.toJson<String>(themeMode),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'appointmentsCompletionEnabled': serializer.toJson<bool>(
        appointmentsCompletionEnabled,
      ),
      'completedToBottom': serializer.toJson<bool>(completedToBottom),
      'appointmentsCompletedToBottom': serializer.toJson<bool>(
        appointmentsCompletedToBottom,
      ),
      'appointmentsTodayOnTop': serializer.toJson<bool>(appointmentsTodayOnTop),
      'invertSwipeActions': serializer.toJson<bool>(invertSwipeActions),
      'use24HourFormat': serializer.toJson<bool>(use24HourFormat),
      'appointmentReminderMinutes': serializer.toJson<String>(
        appointmentReminderMinutes,
      ),
      'longPressHintSeen': serializer.toJson<bool>(longPressHintSeen),
      'trashRetentionDays': serializer.toJson<int>(trashRetentionDays),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SettingsRow copyWith({
    int? id,
    String? themeMode,
    bool? notificationsEnabled,
    bool? appointmentsCompletionEnabled,
    bool? completedToBottom,
    bool? appointmentsCompletedToBottom,
    bool? appointmentsTodayOnTop,
    bool? invertSwipeActions,
    bool? use24HourFormat,
    String? appointmentReminderMinutes,
    bool? longPressHintSeen,
    int? trashRetentionDays,
    DateTime? updatedAt,
  }) => SettingsRow(
    id: id ?? this.id,
    themeMode: themeMode ?? this.themeMode,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    appointmentsCompletionEnabled:
        appointmentsCompletionEnabled ?? this.appointmentsCompletionEnabled,
    completedToBottom: completedToBottom ?? this.completedToBottom,
    appointmentsCompletedToBottom:
        appointmentsCompletedToBottom ?? this.appointmentsCompletedToBottom,
    appointmentsTodayOnTop:
        appointmentsTodayOnTop ?? this.appointmentsTodayOnTop,
    invertSwipeActions: invertSwipeActions ?? this.invertSwipeActions,
    use24HourFormat: use24HourFormat ?? this.use24HourFormat,
    appointmentReminderMinutes:
        appointmentReminderMinutes ?? this.appointmentReminderMinutes,
    longPressHintSeen: longPressHintSeen ?? this.longPressHintSeen,
    trashRetentionDays: trashRetentionDays ?? this.trashRetentionDays,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SettingsRow copyWithCompanion(SettingsTableCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      appointmentsCompletionEnabled: data.appointmentsCompletionEnabled.present
          ? data.appointmentsCompletionEnabled.value
          : this.appointmentsCompletionEnabled,
      completedToBottom: data.completedToBottom.present
          ? data.completedToBottom.value
          : this.completedToBottom,
      appointmentsCompletedToBottom: data.appointmentsCompletedToBottom.present
          ? data.appointmentsCompletedToBottom.value
          : this.appointmentsCompletedToBottom,
      appointmentsTodayOnTop: data.appointmentsTodayOnTop.present
          ? data.appointmentsTodayOnTop.value
          : this.appointmentsTodayOnTop,
      invertSwipeActions: data.invertSwipeActions.present
          ? data.invertSwipeActions.value
          : this.invertSwipeActions,
      use24HourFormat: data.use24HourFormat.present
          ? data.use24HourFormat.value
          : this.use24HourFormat,
      appointmentReminderMinutes: data.appointmentReminderMinutes.present
          ? data.appointmentReminderMinutes.value
          : this.appointmentReminderMinutes,
      longPressHintSeen: data.longPressHintSeen.present
          ? data.longPressHintSeen.value
          : this.longPressHintSeen,
      trashRetentionDays: data.trashRetentionDays.present
          ? data.trashRetentionDays.value
          : this.trashRetentionDays,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write(
            'appointmentsCompletionEnabled: $appointmentsCompletionEnabled, ',
          )
          ..write('completedToBottom: $completedToBottom, ')
          ..write(
            'appointmentsCompletedToBottom: $appointmentsCompletedToBottom, ',
          )
          ..write('appointmentsTodayOnTop: $appointmentsTodayOnTop, ')
          ..write('invertSwipeActions: $invertSwipeActions, ')
          ..write('use24HourFormat: $use24HourFormat, ')
          ..write('appointmentReminderMinutes: $appointmentReminderMinutes, ')
          ..write('longPressHintSeen: $longPressHintSeen, ')
          ..write('trashRetentionDays: $trashRetentionDays, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    themeMode,
    notificationsEnabled,
    appointmentsCompletionEnabled,
    completedToBottom,
    appointmentsCompletedToBottom,
    appointmentsTodayOnTop,
    invertSwipeActions,
    use24HourFormat,
    appointmentReminderMinutes,
    longPressHintSeen,
    trashRetentionDays,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.appointmentsCompletionEnabled ==
              this.appointmentsCompletionEnabled &&
          other.completedToBottom == this.completedToBottom &&
          other.appointmentsCompletedToBottom ==
              this.appointmentsCompletedToBottom &&
          other.appointmentsTodayOnTop == this.appointmentsTodayOnTop &&
          other.invertSwipeActions == this.invertSwipeActions &&
          other.use24HourFormat == this.use24HourFormat &&
          other.appointmentReminderMinutes == this.appointmentReminderMinutes &&
          other.longPressHintSeen == this.longPressHintSeen &&
          other.trashRetentionDays == this.trashRetentionDays &&
          other.updatedAt == this.updatedAt);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String> themeMode;
  final Value<bool> notificationsEnabled;
  final Value<bool> appointmentsCompletionEnabled;
  final Value<bool> completedToBottom;
  final Value<bool> appointmentsCompletedToBottom;
  final Value<bool> appointmentsTodayOnTop;
  final Value<bool> invertSwipeActions;
  final Value<bool> use24HourFormat;
  final Value<String> appointmentReminderMinutes;
  final Value<bool> longPressHintSeen;
  final Value<int> trashRetentionDays;
  final Value<DateTime> updatedAt;
  const SettingsTableCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.appointmentsCompletionEnabled = const Value.absent(),
    this.completedToBottom = const Value.absent(),
    this.appointmentsCompletedToBottom = const Value.absent(),
    this.appointmentsTodayOnTop = const Value.absent(),
    this.invertSwipeActions = const Value.absent(),
    this.use24HourFormat = const Value.absent(),
    this.appointmentReminderMinutes = const Value.absent(),
    this.longPressHintSeen = const Value.absent(),
    this.trashRetentionDays = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.appointmentsCompletionEnabled = const Value.absent(),
    this.completedToBottom = const Value.absent(),
    this.appointmentsCompletedToBottom = const Value.absent(),
    this.appointmentsTodayOnTop = const Value.absent(),
    this.invertSwipeActions = const Value.absent(),
    this.use24HourFormat = const Value.absent(),
    this.appointmentReminderMinutes = const Value.absent(),
    this.longPressHintSeen = const Value.absent(),
    this.trashRetentionDays = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? themeMode,
    Expression<bool>? notificationsEnabled,
    Expression<bool>? appointmentsCompletionEnabled,
    Expression<bool>? completedToBottom,
    Expression<bool>? appointmentsCompletedToBottom,
    Expression<bool>? appointmentsTodayOnTop,
    Expression<bool>? invertSwipeActions,
    Expression<bool>? use24HourFormat,
    Expression<String>? appointmentReminderMinutes,
    Expression<bool>? longPressHintSeen,
    Expression<int>? trashRetentionDays,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (appointmentsCompletionEnabled != null)
        'appointments_completion_enabled': appointmentsCompletionEnabled,
      if (completedToBottom != null) 'completed_to_bottom': completedToBottom,
      if (appointmentsCompletedToBottom != null)
        'appointments_completed_to_bottom': appointmentsCompletedToBottom,
      if (appointmentsTodayOnTop != null)
        'appointments_today_on_top': appointmentsTodayOnTop,
      if (invertSwipeActions != null)
        'invert_swipe_actions': invertSwipeActions,
      if (use24HourFormat != null) 'use24_hour_format': use24HourFormat,
      if (appointmentReminderMinutes != null)
        'appointment_reminder_minutes': appointmentReminderMinutes,
      if (longPressHintSeen != null) 'long_press_hint_seen': longPressHintSeen,
      if (trashRetentionDays != null)
        'trash_retention_days': trashRetentionDays,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? themeMode,
    Value<bool>? notificationsEnabled,
    Value<bool>? appointmentsCompletionEnabled,
    Value<bool>? completedToBottom,
    Value<bool>? appointmentsCompletedToBottom,
    Value<bool>? appointmentsTodayOnTop,
    Value<bool>? invertSwipeActions,
    Value<bool>? use24HourFormat,
    Value<String>? appointmentReminderMinutes,
    Value<bool>? longPressHintSeen,
    Value<int>? trashRetentionDays,
    Value<DateTime>? updatedAt,
  }) {
    return SettingsTableCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      appointmentsCompletionEnabled:
          appointmentsCompletionEnabled ?? this.appointmentsCompletionEnabled,
      completedToBottom: completedToBottom ?? this.completedToBottom,
      appointmentsCompletedToBottom:
          appointmentsCompletedToBottom ?? this.appointmentsCompletedToBottom,
      appointmentsTodayOnTop:
          appointmentsTodayOnTop ?? this.appointmentsTodayOnTop,
      invertSwipeActions: invertSwipeActions ?? this.invertSwipeActions,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      appointmentReminderMinutes:
          appointmentReminderMinutes ?? this.appointmentReminderMinutes,
      longPressHintSeen: longPressHintSeen ?? this.longPressHintSeen,
      trashRetentionDays: trashRetentionDays ?? this.trashRetentionDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (appointmentsCompletionEnabled.present) {
      map['appointments_completion_enabled'] = Variable<bool>(
        appointmentsCompletionEnabled.value,
      );
    }
    if (completedToBottom.present) {
      map['completed_to_bottom'] = Variable<bool>(completedToBottom.value);
    }
    if (appointmentsCompletedToBottom.present) {
      map['appointments_completed_to_bottom'] = Variable<bool>(
        appointmentsCompletedToBottom.value,
      );
    }
    if (appointmentsTodayOnTop.present) {
      map['appointments_today_on_top'] = Variable<bool>(
        appointmentsTodayOnTop.value,
      );
    }
    if (invertSwipeActions.present) {
      map['invert_swipe_actions'] = Variable<bool>(invertSwipeActions.value);
    }
    if (use24HourFormat.present) {
      map['use24_hour_format'] = Variable<bool>(use24HourFormat.value);
    }
    if (appointmentReminderMinutes.present) {
      map['appointment_reminder_minutes'] = Variable<String>(
        appointmentReminderMinutes.value,
      );
    }
    if (longPressHintSeen.present) {
      map['long_press_hint_seen'] = Variable<bool>(longPressHintSeen.value);
    }
    if (trashRetentionDays.present) {
      map['trash_retention_days'] = Variable<int>(trashRetentionDays.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write(
            'appointmentsCompletionEnabled: $appointmentsCompletionEnabled, ',
          )
          ..write('completedToBottom: $completedToBottom, ')
          ..write(
            'appointmentsCompletedToBottom: $appointmentsCompletedToBottom, ',
          )
          ..write('appointmentsTodayOnTop: $appointmentsTodayOnTop, ')
          ..write('invertSwipeActions: $invertSwipeActions, ')
          ..write('use24HourFormat: $use24HourFormat, ')
          ..write('appointmentReminderMinutes: $appointmentReminderMinutes, ')
          ..write('longPressHintSeen: $longPressHintSeen, ')
          ..write('trashRetentionDays: $trashRetentionDays, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AccountCacheTableTable extends AccountCacheTable
    with TableInfo<$AccountCacheTableTable, AccountCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [uid, email, displayName, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_cache_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  AccountCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountCacheRow(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $AccountCacheTableTable createAlias(String alias) {
    return $AccountCacheTableTable(attachedDatabase, alias);
  }
}

class AccountCacheRow extends DataClass implements Insertable<AccountCacheRow> {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime cachedAt;
  const AccountCacheRow({
    required this.uid,
    required this.email,
    this.displayName,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  AccountCacheTableCompanion toCompanion(bool nullToAbsent) {
    return AccountCacheTableCompanion(
      uid: Value(uid),
      email: Value(email),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      cachedAt: Value(cachedAt),
    );
  }

  factory AccountCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountCacheRow(
      uid: serializer.fromJson<String>(json['uid']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String?>(displayName),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  AccountCacheRow copyWith({
    String? uid,
    String? email,
    Value<String?> displayName = const Value.absent(),
    DateTime? cachedAt,
  }) => AccountCacheRow(
    uid: uid ?? this.uid,
    email: email ?? this.email,
    displayName: displayName.present ? displayName.value : this.displayName,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  AccountCacheRow copyWithCompanion(AccountCacheTableCompanion data) {
    return AccountCacheRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountCacheRow(')
          ..write('uid: $uid, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, email, displayName, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountCacheRow &&
          other.uid == this.uid &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.cachedAt == this.cachedAt);
}

class AccountCacheTableCompanion extends UpdateCompanion<AccountCacheRow> {
  final Value<String> uid;
  final Value<String> email;
  final Value<String?> displayName;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const AccountCacheTableCompanion({
    this.uid = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountCacheTableCompanion.insert({
    required String uid,
    required String email,
    this.displayName = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       email = Value(email),
       cachedAt = Value(cachedAt);
  static Insertable<AccountCacheRow> custom({
    Expression<String>? uid,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountCacheTableCompanion copyWith({
    Value<String>? uid,
    Value<String>? email,
    Value<String?>? displayName,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return AccountCacheTableCompanion(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountCacheTableCompanion(')
          ..write('uid: $uid, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrashPendingTableTable extends TrashPendingTable
    with TableInfo<$TrashPendingTableTable, TrashPendingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrashPendingTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _docIdMeta = const VerificationMeta('docId');
  @override
  late final GeneratedColumn<String> docId = GeneratedColumn<String>(
    'doc_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [uid, docId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trash_pending_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrashPendingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('doc_id')) {
      context.handle(
        _docIdMeta,
        docId.isAcceptableOrUnknown(data['doc_id']!, _docIdMeta),
      );
    } else if (isInserting) {
      context.missing(_docIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid, docId};
  @override
  TrashPendingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrashPendingRow(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      docId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TrashPendingTableTable createAlias(String alias) {
    return $TrashPendingTableTable(attachedDatabase, alias);
  }
}

class TrashPendingRow extends DataClass implements Insertable<TrashPendingRow> {
  final String uid;

  /// Id del documento en `users/{uid}/trash`.
  final String docId;
  final DateTime createdAt;
  const TrashPendingRow({
    required this.uid,
    required this.docId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['doc_id'] = Variable<String>(docId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TrashPendingTableCompanion toCompanion(bool nullToAbsent) {
    return TrashPendingTableCompanion(
      uid: Value(uid),
      docId: Value(docId),
      createdAt: Value(createdAt),
    );
  }

  factory TrashPendingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrashPendingRow(
      uid: serializer.fromJson<String>(json['uid']),
      docId: serializer.fromJson<String>(json['docId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'docId': serializer.toJson<String>(docId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TrashPendingRow copyWith({String? uid, String? docId, DateTime? createdAt}) =>
      TrashPendingRow(
        uid: uid ?? this.uid,
        docId: docId ?? this.docId,
        createdAt: createdAt ?? this.createdAt,
      );
  TrashPendingRow copyWithCompanion(TrashPendingTableCompanion data) {
    return TrashPendingRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      docId: data.docId.present ? data.docId.value : this.docId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrashPendingRow(')
          ..write('uid: $uid, ')
          ..write('docId: $docId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, docId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrashPendingRow &&
          other.uid == this.uid &&
          other.docId == this.docId &&
          other.createdAt == this.createdAt);
}

class TrashPendingTableCompanion extends UpdateCompanion<TrashPendingRow> {
  final Value<String> uid;
  final Value<String> docId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TrashPendingTableCompanion({
    this.uid = const Value.absent(),
    this.docId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrashPendingTableCompanion.insert({
    required String uid,
    required String docId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       docId = Value(docId),
       createdAt = Value(createdAt);
  static Insertable<TrashPendingRow> custom({
    Expression<String>? uid,
    Expression<String>? docId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (docId != null) 'doc_id': docId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrashPendingTableCompanion copyWith({
    Value<String>? uid,
    Value<String>? docId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TrashPendingTableCompanion(
      uid: uid ?? this.uid,
      docId: docId ?? this.docId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (docId.present) {
      map['doc_id'] = Variable<String>(docId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrashPendingTableCompanion(')
          ..write('uid: $uid, ')
          ..write('docId: $docId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final $AccountCacheTableTable accountCacheTable =
      $AccountCacheTableTable(this);
  late final $TrashPendingTableTable trashPendingTable =
      $TrashPendingTableTable(this);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final AccountCacheDao accountCacheDao = AccountCacheDao(
    this as AppDatabase,
  );
  late final TrashPendingDao trashPendingDao = TrashPendingDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settingsTable,
    accountCacheTable,
    trashPendingTable,
  ];
}

typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<bool> notificationsEnabled,
      Value<bool> appointmentsCompletionEnabled,
      Value<bool> completedToBottom,
      Value<bool> appointmentsCompletedToBottom,
      Value<bool> appointmentsTodayOnTop,
      Value<bool> invertSwipeActions,
      Value<bool> use24HourFormat,
      Value<String> appointmentReminderMinutes,
      Value<bool> longPressHintSeen,
      Value<int> trashRetentionDays,
      required DateTime updatedAt,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<bool> notificationsEnabled,
      Value<bool> appointmentsCompletionEnabled,
      Value<bool> completedToBottom,
      Value<bool> appointmentsCompletedToBottom,
      Value<bool> appointmentsTodayOnTop,
      Value<bool> invertSwipeActions,
      Value<bool> use24HourFormat,
      Value<String> appointmentReminderMinutes,
      Value<bool> longPressHintSeen,
      Value<int> trashRetentionDays,
      Value<DateTime> updatedAt,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appointmentsCompletionEnabled => $composableBuilder(
    column: $table.appointmentsCompletionEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completedToBottom => $composableBuilder(
    column: $table.completedToBottom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appointmentsCompletedToBottom => $composableBuilder(
    column: $table.appointmentsCompletedToBottom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appointmentsTodayOnTop => $composableBuilder(
    column: $table.appointmentsTodayOnTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get invertSwipeActions => $composableBuilder(
    column: $table.invertSwipeActions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get use24HourFormat => $composableBuilder(
    column: $table.use24HourFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appointmentReminderMinutes => $composableBuilder(
    column: $table.appointmentReminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get longPressHintSeen => $composableBuilder(
    column: $table.longPressHintSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trashRetentionDays => $composableBuilder(
    column: $table.trashRetentionDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appointmentsCompletionEnabled => $composableBuilder(
    column: $table.appointmentsCompletionEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completedToBottom => $composableBuilder(
    column: $table.completedToBottom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appointmentsCompletedToBottom => $composableBuilder(
    column: $table.appointmentsCompletedToBottom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appointmentsTodayOnTop => $composableBuilder(
    column: $table.appointmentsTodayOnTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get invertSwipeActions => $composableBuilder(
    column: $table.invertSwipeActions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get use24HourFormat => $composableBuilder(
    column: $table.use24HourFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appointmentReminderMinutes => $composableBuilder(
    column: $table.appointmentReminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get longPressHintSeen => $composableBuilder(
    column: $table.longPressHintSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trashRetentionDays => $composableBuilder(
    column: $table.trashRetentionDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get appointmentsCompletionEnabled => $composableBuilder(
    column: $table.appointmentsCompletionEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completedToBottom => $composableBuilder(
    column: $table.completedToBottom,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get appointmentsCompletedToBottom => $composableBuilder(
    column: $table.appointmentsCompletedToBottom,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get appointmentsTodayOnTop => $composableBuilder(
    column: $table.appointmentsTodayOnTop,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get invertSwipeActions => $composableBuilder(
    column: $table.invertSwipeActions,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get use24HourFormat => $composableBuilder(
    column: $table.use24HourFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appointmentReminderMinutes => $composableBuilder(
    column: $table.appointmentReminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get longPressHintSeen => $composableBuilder(
    column: $table.longPressHintSeen,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trashRetentionDays => $composableBuilder(
    column: $table.trashRetentionDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingsRow,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> appointmentsCompletionEnabled =
                    const Value.absent(),
                Value<bool> completedToBottom = const Value.absent(),
                Value<bool> appointmentsCompletedToBottom =
                    const Value.absent(),
                Value<bool> appointmentsTodayOnTop = const Value.absent(),
                Value<bool> invertSwipeActions = const Value.absent(),
                Value<bool> use24HourFormat = const Value.absent(),
                Value<String> appointmentReminderMinutes = const Value.absent(),
                Value<bool> longPressHintSeen = const Value.absent(),
                Value<int> trashRetentionDays = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SettingsTableCompanion(
                id: id,
                themeMode: themeMode,
                notificationsEnabled: notificationsEnabled,
                appointmentsCompletionEnabled: appointmentsCompletionEnabled,
                completedToBottom: completedToBottom,
                appointmentsCompletedToBottom: appointmentsCompletedToBottom,
                appointmentsTodayOnTop: appointmentsTodayOnTop,
                invertSwipeActions: invertSwipeActions,
                use24HourFormat: use24HourFormat,
                appointmentReminderMinutes: appointmentReminderMinutes,
                longPressHintSeen: longPressHintSeen,
                trashRetentionDays: trashRetentionDays,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> appointmentsCompletionEnabled =
                    const Value.absent(),
                Value<bool> completedToBottom = const Value.absent(),
                Value<bool> appointmentsCompletedToBottom =
                    const Value.absent(),
                Value<bool> appointmentsTodayOnTop = const Value.absent(),
                Value<bool> invertSwipeActions = const Value.absent(),
                Value<bool> use24HourFormat = const Value.absent(),
                Value<String> appointmentReminderMinutes = const Value.absent(),
                Value<bool> longPressHintSeen = const Value.absent(),
                Value<int> trashRetentionDays = const Value.absent(),
                required DateTime updatedAt,
              }) => SettingsTableCompanion.insert(
                id: id,
                themeMode: themeMode,
                notificationsEnabled: notificationsEnabled,
                appointmentsCompletionEnabled: appointmentsCompletionEnabled,
                completedToBottom: completedToBottom,
                appointmentsCompletedToBottom: appointmentsCompletedToBottom,
                appointmentsTodayOnTop: appointmentsTodayOnTop,
                invertSwipeActions: invertSwipeActions,
                use24HourFormat: use24HourFormat,
                appointmentReminderMinutes: appointmentReminderMinutes,
                longPressHintSeen: longPressHintSeen,
                trashRetentionDays: trashRetentionDays,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingsRow,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$AccountCacheTableTableCreateCompanionBuilder =
    AccountCacheTableCompanion Function({
      required String uid,
      required String email,
      Value<String?> displayName,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$AccountCacheTableTableUpdateCompanionBuilder =
    AccountCacheTableCompanion Function({
      Value<String> uid,
      Value<String> email,
      Value<String?> displayName,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$AccountCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $AccountCacheTableTable> {
  $$AccountCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountCacheTableTable> {
  $$AccountCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountCacheTableTable> {
  $$AccountCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$AccountCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountCacheTableTable,
          AccountCacheRow,
          $$AccountCacheTableTableFilterComposer,
          $$AccountCacheTableTableOrderingComposer,
          $$AccountCacheTableTableAnnotationComposer,
          $$AccountCacheTableTableCreateCompanionBuilder,
          $$AccountCacheTableTableUpdateCompanionBuilder,
          (
            AccountCacheRow,
            BaseReferences<
              _$AppDatabase,
              $AccountCacheTableTable,
              AccountCacheRow
            >,
          ),
          AccountCacheRow,
          PrefetchHooks Function()
        > {
  $$AccountCacheTableTableTableManager(
    _$AppDatabase db,
    $AccountCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountCacheTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountCacheTableCompanion(
                uid: uid,
                email: email,
                displayName: displayName,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String email,
                Value<String?> displayName = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountCacheTableCompanion.insert(
                uid: uid,
                email: email,
                displayName: displayName,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountCacheTableTable,
      AccountCacheRow,
      $$AccountCacheTableTableFilterComposer,
      $$AccountCacheTableTableOrderingComposer,
      $$AccountCacheTableTableAnnotationComposer,
      $$AccountCacheTableTableCreateCompanionBuilder,
      $$AccountCacheTableTableUpdateCompanionBuilder,
      (
        AccountCacheRow,
        BaseReferences<_$AppDatabase, $AccountCacheTableTable, AccountCacheRow>,
      ),
      AccountCacheRow,
      PrefetchHooks Function()
    >;
typedef $$TrashPendingTableTableCreateCompanionBuilder =
    TrashPendingTableCompanion Function({
      required String uid,
      required String docId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TrashPendingTableTableUpdateCompanionBuilder =
    TrashPendingTableCompanion Function({
      Value<String> uid,
      Value<String> docId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TrashPendingTableTableFilterComposer
    extends Composer<_$AppDatabase, $TrashPendingTableTable> {
  $$TrashPendingTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docId => $composableBuilder(
    column: $table.docId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrashPendingTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TrashPendingTableTable> {
  $$TrashPendingTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docId => $composableBuilder(
    column: $table.docId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrashPendingTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrashPendingTableTable> {
  $$TrashPendingTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get docId =>
      $composableBuilder(column: $table.docId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TrashPendingTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrashPendingTableTable,
          TrashPendingRow,
          $$TrashPendingTableTableFilterComposer,
          $$TrashPendingTableTableOrderingComposer,
          $$TrashPendingTableTableAnnotationComposer,
          $$TrashPendingTableTableCreateCompanionBuilder,
          $$TrashPendingTableTableUpdateCompanionBuilder,
          (
            TrashPendingRow,
            BaseReferences<
              _$AppDatabase,
              $TrashPendingTableTable,
              TrashPendingRow
            >,
          ),
          TrashPendingRow,
          PrefetchHooks Function()
        > {
  $$TrashPendingTableTableTableManager(
    _$AppDatabase db,
    $TrashPendingTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrashPendingTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrashPendingTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrashPendingTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> docId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrashPendingTableCompanion(
                uid: uid,
                docId: docId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String docId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TrashPendingTableCompanion.insert(
                uid: uid,
                docId: docId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrashPendingTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrashPendingTableTable,
      TrashPendingRow,
      $$TrashPendingTableTableFilterComposer,
      $$TrashPendingTableTableOrderingComposer,
      $$TrashPendingTableTableAnnotationComposer,
      $$TrashPendingTableTableCreateCompanionBuilder,
      $$TrashPendingTableTableUpdateCompanionBuilder,
      (
        TrashPendingRow,
        BaseReferences<_$AppDatabase, $TrashPendingTableTable, TrashPendingRow>,
      ),
      TrashPendingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
  $$AccountCacheTableTableTableManager get accountCacheTable =>
      $$AccountCacheTableTableTableManager(_db, _db.accountCacheTable);
  $$TrashPendingTableTableTableManager get trashPendingTable =>
      $$TrashPendingTableTableTableManager(_db, _db.trashPendingTable);
}
