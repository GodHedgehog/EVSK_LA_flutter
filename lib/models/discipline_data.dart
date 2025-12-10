class DisciplineData {
  final String name;
  final String gender;
  final String rank;
  final String time;
  final String? trackType;
  final String? timingType;

  DisciplineData({
    required this.name,
    required this.gender,
    required this.rank,
    required this.time,
    this.trackType,
    this.timingType,
  });
}

