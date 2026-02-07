class Score {
  final int? id;
  final String name;
  final int points;
  final String date;

  Score({
    this.id,
    required this.name,
    required this.points,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'points': points,
      'date': date,
    };
  }

  factory Score.fromMap(Map<String, dynamic> map) {
    return Score(
      id: map['id'],
      name: map['name'],
      points: map['points'],
      date: map['date'],
    );
  }
}
