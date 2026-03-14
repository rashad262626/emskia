// cal.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bt.dart'; // BottomNavigationBar widget (rashad)

class CalPage extends StatefulWidget {
  const CalPage({super.key});

  @override
  State<CalPage> createState() => _CalPageState();
}

class _CalPageState extends State<CalPage> {
  // from prefs
  String _citySlug = 'tripoli';
  String _cityLabel = 'طرابلس';

  // db
  Map<String, List<Map<String, dynamic>>> _db = {};
  List<Map<String, dynamic>> _rows = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await _loadPrefs();
      await _ensureJsonLoadedAndCached();
      _buildRowsForCity();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _citySlug = prefs.getString('city_slug') ?? 'tripoli';
    _cityLabel = prefs.getString('city_label') ?? 'طرابلس';
  }

  Future<void> _ensureJsonLoadedAndCached() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('ramadan_db_json');

    if (cached != null && cached.isNotEmpty) {
      _db = _decodeDb(cached);
      return;
    }

    final raw = await rootBundle.loadString('assets/ramadan_2026_libya.json');
    await prefs.setString('ramadan_db_json', raw);
    _db = _decodeDb(raw);
  }

  Map<String, List<Map<String, dynamic>>> _decodeDb(String raw) {
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final out = <String, List<Map<String, dynamic>>>{};

    decoded.forEach((city, rows) {
      out[city] = (rows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    });

    return out;
  }

  void _buildRowsForCity() {
    final list = _db[_citySlug] ?? [];
    // sort by date asc (yyyy-MM-dd)
    list.sort((a, b) => (a['date'] ?? '').toString().compareTo((b['date'] ?? '').toString()));
    _rows = list;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isToday(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return false;
    return _dateOnly(dt) == _dateOnly(DateTime.now());
  }

  String _fmtDateIso(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  // ✅ فيفري => 2 ، مارس => 3
  String _normalizeDateLabel(String label) {
    if (label.isEmpty) return label;

    // قائمة أيام الأسبوع بالعربي
    const days = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];

    for (final d in days) {
      if (label.contains(d)) return d;
    }

    return label; // fallback لو ما لقا شي
  }


  Widget _timeChip(String name, String time, IconData icon, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF2196F3).withOpacity(0.12) : Colors.blueGrey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? const Color(0xFF2196F3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1565C0)),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'الفجر':
        return Icons.wb_sunny;
      case 'الشروق':
        return Icons.sunny;
      case 'الظهر':
        return Icons.wb_sunny_outlined;
      case 'العصر':
        return Icons.brightness_low;
      case 'المغرب':
        return Icons.sunny;
      case 'العشاء':
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقويم'),
        centerTitle: true,
      ),
      bottomNavigationBar: const Rashad(currentIndex: 1),
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
          // header: city + count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'المدينة: $_cityLabel',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.25)),
                  ),
                  child: Text(
                    'اليوم: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemCount: _rows.length,
              itemBuilder: (context, i) {
                final r = _rows[i];

                final iso = (r['date'] ?? '').toString();
                final isToday = _isToday(iso);

                final ramadanDay = (r['ramadan_day'] ?? '').toString();
                final dateLabel = (r['date_label'] ?? '').toString();

                final fajr = (r['fajr'] ?? '00:00').toString();
                final sunrise = (r['sunrise'] ?? '00:00').toString();
                final dhuhr = (r['dhuhr'] ?? '00:00').toString();
                final asr = (r['asr'] ?? '00:00').toString();
                final maghrib = (r['maghrib'] ?? '00:00').toString();
                final isha = (r['isha'] ?? '00:00').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isToday ? const Color(0xFF2196F3) : Colors.grey.shade300,
                      width: isToday ? 2 : 1,
                    ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: day badge + date label + today badge
                        Row(
                          children: [


                    Expanded(
                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // أقصى اليمين
                          mainAxisSize: MainAxisSize.min,
                          children: [

                              Text(
                                _normalizeDateLabel(dateLabel), // الأربعاء
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey,
                                ),
                              ),


                        // 🔹 التاريخ أولًا
                            Text(
                              _fmtDateIso(iso), // 2026-02-18
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                              ),

                      ),
                            const SizedBox(height: 2),

                            // 🔹 اليوم ثانيًا

                          ],
                        ),

                    ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'رمضان $ramadanDay',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),


                    if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'اليوم',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ✅ Prayer times ONE LINE (horizontal scroll)
                LayoutBuilder(
                builder: (context, constraints) {
                const count = 6; // الفجر → العشاء (بدون الإمساك هنا)
                const gap = 6.0;
                final itemW =
                (constraints.maxWidth - gap * (count - 1)) / count;

                Widget item(String name, String time, IconData icon) {
                return SizedBox(
                width: itemW,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Icon(
                icon,
                size: 16,
                color: isToday
                ? const Color(0xFF1565C0)
                    : Colors.blueGrey,
                ),
                const SizedBox(height: 2),
                FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                name,
                style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isToday
                ? const Color(0xFF2196F3)
                    : Colors.blueGrey.shade700,
                ),
                ),
                ),
                const SizedBox(height: 1),

                FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                time,
                style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isToday
                ? const Color(0xFF0D47A1)
                    : Colors.black87,
                ),
                ),
                ),
                ],
                ),
                );
                }

                return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                item('العشاء', isha, Icons.nights_stay),
                const SizedBox(width: gap),
                item('المغرب', maghrib, Icons.sunny),
                const SizedBox(width: gap),
                item('العصر', asr, Icons.brightness_low),
                const SizedBox(width: gap),
                item('الظهر', dhuhr, Icons.wb_sunny_outlined),
                const SizedBox(width: gap),
                item('الشروق', sunrise, Icons.sunny),
                const SizedBox(width: gap),
                item('الفجر', fajr, Icons.wb_sunny),
                ],
                );
                },
                ),
                        const SizedBox(height: 10),

                        // ISO date (small)

                      ],
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
