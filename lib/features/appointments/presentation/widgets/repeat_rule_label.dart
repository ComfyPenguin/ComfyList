import '../../domain/entities/repeat_rule.dart';

/// La regla dicha en una frase: «Cada día», «Cada 2 semanas».
String repeatRuleLabel(RepeatRule rule) {
  final n = rule.interval;
  return switch (rule.unit) {
    RepeatUnit.day => n == 1 ? 'Cada día' : 'Cada $n días',
    RepeatUnit.week => n == 1 ? 'Cada semana' : 'Cada $n semanas',
    RepeatUnit.month => n == 1 ? 'Cada mes' : 'Cada $n meses',
    RepeatUnit.year => n == 1 ? 'Cada año' : 'Cada $n años',
  };
}
