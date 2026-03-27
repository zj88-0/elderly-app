// lib/models/wellbeing_model.dart
// Daily wellbeing questionnaire answers from elderly user.

class WellbeingAnswer {
  final String questionKey; // e.g. 'mood', 'pain', 'sleep', 'appetite', 'lonely'
  final int score;          // 1–5
  final String? note;       // optional free-text note

  WellbeingAnswer({
    required this.questionKey,
    required this.score,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'questionKey': questionKey,
        'score': score,
        'note': note,
      };

  factory WellbeingAnswer.fromJson(Map<String, dynamic> json) =>
      WellbeingAnswer(
        questionKey: json['questionKey'],
        score: json['score'],
        note: json['note'],
      );
}

class WellbeingEntry {
  final String id;
  final String elderlyId;
  final DateTime date;
  final List<WellbeingAnswer> answers;

  WellbeingEntry({
    required this.id,
    required this.elderlyId,
    required this.date,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'elderlyId': elderlyId,
        'date': date.toIso8601String(),
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  factory WellbeingEntry.fromJson(Map<String, dynamic> json) => WellbeingEntry(
        id: json['id'],
        elderlyId: json['elderlyId'],
        date: DateTime.parse(json['date']),
        answers: (json['answers'] as List<dynamic>)
            .map((a) => WellbeingAnswer.fromJson(a as Map<String, dynamic>))
            .toList(),
      );

  /// Returns the average score across all answers (1–5)
  double get averageScore {
    if (answers.isEmpty) return 0;
    return answers.map((a) => a.score).reduce((a, b) => a + b) / answers.length;
  }
}
