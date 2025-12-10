import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/discipline_data.dart';

class DataLoader {
  static Future<List<DisciplineData>> loadAllDataFromAssets(String gender) async {
    final disciplinesList = <DisciplineData>[];
    final String data = await rootBundle.loadString('assets/disciplines.txt');
    final lines = LineSplitter().convert(data);

    for (final line in lines) {
      if (line.trim().isEmpty || line.trim().startsWith('#')) {
        continue;
      }
      
      final parts = line.split(';');
      if (parts.length >= 4) {
        final name = parts[0].trim();
        final lineGender = parts[1].trim();
        final rank = parts[2].trim();
        final time = parts[3].trim();
        final track = parts.length > 4 && parts[4].trim().isNotEmpty
            ? parts[4].trim()
            : null;
        final timing = parts.length > 5 && parts[5].trim().isNotEmpty
            ? parts[5].trim()
            : null;

        if (lineGender.toLowerCase() == gender.toLowerCase()) {
          disciplinesList.add(
            DisciplineData(
              name: name,
              gender: lineGender,
              rank: rank,
              time: time,
              trackType: track,
              timingType: timing,
            ),
          );
        }
      }
    }
    return disciplinesList;
  }
}

