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
