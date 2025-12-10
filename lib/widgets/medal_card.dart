import 'package:flutter/material.dart';
import '../models/medal_item.dart';

class MedalCard extends StatelessWidget {
  final MedalItem item;

  const MedalCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0x80FFFFFF), // #80FFFFFF
      elevation: 0,
      
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _getMedalAsset(item.rank),
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFD50000),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                item.timeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMedalAsset(String rank) {
    final r = rank.toLowerCase();
    if (r.contains("мастер спорта международного класса") || r == "мсмк") {
      return 'assets/medals/medal_msmk.png';
    } else if (r.contains("мастер спорта") && !r.contains("мс")) {
      return 'assets/medals/medal_ms.png';
    } else if (r.contains("кандидат") || r == "кмс") {
      return 'assets/medals/medal_kms.png';
    } else if (r.contains("3 взросл")) {
      return 'assets/medals/medal_adult_3.png';
    } else if (r.contains("2 взросл")) {
      return 'assets/medals/medal_adult_2.png';
    } else if (r.contains("1 взросл")) {
      return 'assets/medals/medal_adult_1.png';
    } else if (r.contains("3 юнош")) {
      return 'assets/medals/medal_youth_3.png';
    } else if (r.contains("2 юнош")) {
      return 'assets/medals/medal_youth_2.png';
    } else if (r.contains("1 юнош")) {
      return 'assets/medals/medal_youth_1.png';
    } else {
      return 'assets/medals/medal_ms.png';
    }
  }
}

