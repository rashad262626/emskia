// qran.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ltt_ramadan_emskia/surahdetail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bt.dart'; // Rashad BottomNavigationBar

// ---------------- Models ----------------

class QuranSurah {
  final int id;
  final String name;
  final String transliteration;
  final String type; // meccan / medinan
  final int totalVerses;
  final List<QuranVerse> verses;

  QuranSurah({
    required this.id,
    required this.name,
    required this.transliteration,
    required this.type,
    required this.totalVerses,
    required this.verses,
  });

  factory QuranSurah.fromMap(Map<String, dynamic> m) {
    return QuranSurah(
      id: (m['id'] ?? 0) as int,
      name: (m['name'] ?? '').toString(),
      transliteration: (m['transliteration'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      totalVerses: (m['total_verses'] ?? 0) as int,
      verses: ((m['verses'] ?? []) as List)
          .map((e) => QuranVerse.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class QuranVerse {
  final int id; // verse number inside surah
  final String text;

  QuranVerse({required this.id, required this.text});

  factory QuranVerse.fromMap(Map<String, dynamic> m) {
    return QuranVerse(
      id: (m['id'] ?? 0) as int,
      text: (m['text'] ?? '').toString(),
    );
  }
}

// ---------------- Page: Index (الفهرس) ----------------

class QuranIndexPage extends StatefulWidget {
  const QuranIndexPage({super.key});

  @override
  State<QuranIndexPage> createState() => _QuranIndexPageState();
}

class _QuranIndexPageState extends State<QuranIndexPage> {
  bool _loading = true;
  String? _error;

  List<QuranSurah> _surahs = [];
  List<QuranSurah> _filtered = [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final raw = await _loadAndCacheJson();
      final list = json.decode(raw) as List<dynamic>; // JSON is List of surahs
      _surahs = list
          .map((e) => QuranSurah.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      _filtered = List.of(_surahs);

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<String> _loadAndCacheJson() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('quran_db_json');
    if (cached != null && cached.isNotEmpty) return cached;

    final raw = await rootBundle.loadString('assets/quran.json');
    await prefs.setString('quran_db_json', raw);
    return raw;
  }

  void _onSearch(String q) {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() => _filtered = List.of(_surahs));
      return;
    }

    setState(() {
      _filtered = _surahs.where((s) {
        final idMatch = int.tryParse(query) != null && s.id == int.parse(query);
        final nameMatch = s.name.contains(query);
        final trMatch = s.transliteration.toLowerCase().contains(query.toLowerCase());
        return idMatch || nameMatch || trMatch;
      }).toList();
    });
  }

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
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        appBar: AppBar(
          title: const Text('الفهرس'),
          centerTitle: true,
        ),
        bottomNavigationBar: const Rashad(currentIndex: 2), // عدّل الرقم حسب مشروعك
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'خطأ: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        )
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blueGrey.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Color(0xFF1565C0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: _onSearch,
                        decoration: const InputDecoration(
                          hintText: 'ابحث بالرقم أو الاسم أو transliteration...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final s = _filtered[i];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurahDetailPage(surah: s),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // number badge
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF2196F3).withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                '${s.id}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D47A1),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.transliteration,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _typeLabel(s.type),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'الآيات: ${s.totalVerses}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

    );
  }
}
