class TimeFormatter {
  static String format(String raw) {
    final value = double.tryParse(raw);
    if (value == null) {
      return raw.replaceAll('.', ',');
    }
    return formatValue(value);
  }

  static String formatValue(double value) {
    var totalSeconds = value;
    var hours = (totalSeconds / 3600).toInt();
    totalSeconds %= 3600;
    var minutes = (totalSeconds / 60).toInt();
    totalSeconds %= 60;
    var seconds = totalSeconds.toInt();
    var hundredths = ((totalSeconds - seconds) * 100).round();

    if (hundredths == 100) {
      hundredths = 0;
      seconds += 1;
    }
    if (seconds == 60) {
      seconds = 0;
      minutes += 1;
    }
    if (minutes == 60) {
      minutes = 0;
      hours += 1;
    }

    if (hours > 0) {
      return "${hours}.${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    } else if (minutes > 0) {
      return "${minutes}:${seconds.toString().padLeft(2, '0')},${hundredths.toString().padLeft(2, '0')}";
    } else {
      return "${seconds},${hundredths.toString().padLeft(2, '0')}";
    }
  }
}

