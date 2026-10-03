import 'package:flutter/foundation.dart';

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

  /// Serialización para guardarla en local (papelera).
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'dateTime': dateTime.toIso8601String(),
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        dateTime: DateTime.parse(json['dateTime'] as String),
        isDone: json['isDone'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
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
    bool clearDescription = false,
    bool clearLocation = false,
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
    );
  }
}
