import 'package:comfy_list/features/settings/presentation/widgets/reminder_lead_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatReminderLead', () {
    test('lee los presets como los ofrece Ajustes', () {
      expect(formatReminderLead(5), '5 min');
      expect(formatReminderLead(10), '10 min');
      expect(formatReminderLead(15), '15 min');
      expect(formatReminderLead(30), '30 min');
      expect(formatReminderLead(60), '1 h');
      expect(formatReminderLead(1440), '1 día');
    });

    test('cuenta días y horas en plural', () {
      expect(formatReminderLead(120), '2 h');
      expect(formatReminderLead(2880), '2 días');
    });

    test('los minutos que no llenan una hora van en minutos', () {
      expect(formatReminderLead(20), '20 min');
      expect(formatReminderLead(90), '90 min');
    });

    test('el cero es el aviso a la hora de la cita, de antes', () {
      expect(formatReminderLead(0), 'A la hora');
    });
  });

  group('formatReminderLeadBefore', () {
    test('dice el tiempo entero, como se ofrece en el menú', () {
      expect(formatReminderLeadBefore(5), '5 minutos antes');
      expect(formatReminderLeadBefore(10), '10 minutos antes');
      expect(formatReminderLeadBefore(15), '15 minutos antes');
      expect(formatReminderLeadBefore(30), '30 minutos antes');
      expect(formatReminderLeadBefore(60), '1 hora antes');
      expect(formatReminderLeadBefore(1440), '1 día antes');
    });

    test('cuenta en plural cuando toca', () {
      expect(formatReminderLeadBefore(120), '2 horas antes');
      expect(formatReminderLeadBefore(2880), '2 días antes');
    });
  });
}
