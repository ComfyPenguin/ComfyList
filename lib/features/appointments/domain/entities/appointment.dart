import 'package:flutter/foundation.dart';

import 'repeat_rule.dart';

@immutable
class Appointment {
  const Appointment({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.location,
    this.repeatRule,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Ubicación opcional de la cita (p. ej. "Calle Mayor 1, Madrid").
  final String? location;

  /// Si la cita es recurrente, la regla con la que avanza al completarla.
  final RepeatRule? repeatRule;

  /// Serialización para la papelera, que vive en la cuenta. Las fechas van en
  /// UTC: se pueden restaurar desde un dispositivo en otra zona horaria.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'repeatInterval': repeatRule?.interval,
        'repeatUnit': repeatRule?.unit.name,
        'dateTime': dateTime.toUtc().toIso8601String(),
        'isDone': isDone,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        repeatRule: RepeatRule.fromStored(
          interval: json['repeatInterval'],
          unit: json['repeatUnit'],
        ),
        dateTime: DateTime.parse(json['dateTime'] as String).toLocal(),
        isDone: json['isDone'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      );

  Appointment copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isDone,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? location,
    RepeatRule? repeatRule,
    bool clearDescription = false,
    bool clearLocation = false,
    bool clearRepeatRule = false,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      dateTime: dateTime ?? this.dateTime,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: clearLocation ? null : (location ?? this.location),
      repeatRule: clearRepeatRule ? null : (repeatRule ?? this.repeatRule),
    );
  }
}
