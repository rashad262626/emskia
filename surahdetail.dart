// surah_detail.dart (or keep it in qran.dart under the index page)
import 'package:flutter/material.dart';
import 'qran.dart'; // if models are there (QuranSurah/QuranVerse)

class SurahDetailPage extends StatelessWidget {
  final QuranSurah surah;

  const SurahDetailPage({super.key, required this.surah});

  String _typeLabel(String type) {
    switch (type) {
      case 'meccan':
        return 'مكية';
      case 'medinan':
        return 'مدنية';
      default:
        return type;
    }
  }
  String removeTashkeel(String text) {
    final tashkeelRegex = RegExp(
      r'[\u064B-\u0652\u0670\u0653\u0654\u0655]',
    );
    return text.replaceAll(tashkeelRegex, '');
  }
  String removeQuranMarks(String text) {
    // tashkeel + quran marks (stop signs, sajdah marks, etc.)
    final reg = RegExp(r'[\u064B-\u0652\u0670\u0653-\u0655\u06D6-\u06ED]');
    return text.replaceAll(reg, '');
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(surah.name),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // Header row inside the card
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surah.transliteration,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'عدد الآيات: ${surah.totalVerses}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _typeLabel(surah.type),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // All verses in one scrollable area (no per-verse cards)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    itemCount: surah.verses.length,
                    itemBuilder: (context, i) {
                      final v = surah.verses[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${v.id}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                removeTashkeel(v.text),
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 20,
                                  height: 1.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
