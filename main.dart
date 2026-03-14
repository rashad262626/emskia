
import 'dart:async';
import 'dart:convert';
import 'dart:math' as _m;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:ltt_ramadan_emskia/sitting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'bt.dart';
import 'notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.I.init(
    onNotificationTap: (id, payload) {
      debugPrint("[Adhan] User tapped notification id=$id -> app will open");
    },
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  late BuildContext _mainContext;

  @override
  Widget build( BuildContext context) {
    return MaterialApp(
      title: 'إمساكية رمضان',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2196F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFFFFB74D),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F9FF),
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
        cardTheme: CardThemeData(
          elevation: 6,
          shadowColor: Colors.grey.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ///////////////////////////////

  final PageController _adsController = PageController(viewportFraction: 0.92);
  Timer? _adsTimer;
  int _adsIndex = 0;

  static const String _adsJsonUrl =
      "https://rashad262626.github.io/ramadan-ads/ads.json";

  List<_AdSlide> _adsSlides = []; // ✅ dynamic now

// ✅ one offline slide only
  static const _AdSlide _offlineSlide = _AdSlide(
    image: 'assets/ads/ad7.jpg',
    isNetwork: false,
    title: ' ',
    subtitle: 'سيتم تحميل الإعلانات عند توفر اتصال',
    url: '', // no click
  );
  Future<void> _openAdLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // يفتح المتصفح
    )) {
      debugPrint('❌ Could not launch $url');
    }
  }
  void _startAdsAutoSlide() {
    _adsTimer?.cancel();
    _adsTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_adsSlides.isEmpty) return;

      _adsIndex = (_adsIndex + 1) % _adsSlides.length;

      _adsController.animateToPage(
        _adsIndex,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override




  Future<void> _loadAdsOnlineOrOffline() async {
    try {
      // 1) Check connectivity
      final conn = await Connectivity().checkConnectivity();
      final hasConn = conn != ConnectivityResult.none;

      if (!hasConn) {
        setState(() {
          _adsSlides = [_offlineSlide];
          _adsIndex = 0;
        });
        return;
      }

      // 2) Fetch JSON from GitHub Pages
      final res = await http
          .get(Uri.parse(_adsJsonUrl))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode != 200) {
        throw Exception("ads.json http ${res.statusCode}");
      }

      final decoded = json.decode(res.body);
      if (decoded is! List) throw Exception("ads.json must be a LIST");

      final slides = decoded
          .whereType<Map>()
          .map((e) => _AdSlide.fromJson(Map<String, dynamic>.from(e)))
          .where((s) => s.image.isNotEmpty)
          .toList();

      if (slides.isEmpty) throw Exception("ads.json is empty");

      setState(() {
        _adsSlides = slides;
        _adsIndex = 0;
      });
    } catch (e) {
      debugPrint("❌ Ads load failed: $e");
      setState(() {
        _adsSlides = [_offlineSlide];
        _adsIndex = 0;
      });
    }
  }



  /////////////////////////////////////////////
  void _debugTimeInfo() {
    final utcNow = DateTime.now().toUtc();
    final localNow = DateTime.now();
    final libyaNow = _libyaNow;

    debugPrint("⏰ Debug Time Info:");
    debugPrint("⏰ UTC Now: $utcNow");
    debugPrint("⏰ Local Now: $localNow");
    debugPrint("⏰ Libya Now (calculated): $libyaNow");
    debugPrint("⏰ Libya offset: ${libyaNow.timeZoneOffset}");
    debugPrint("⏰ Local offset: ${localNow.timeZoneOffset}");
  }


  Future<void> _testNotification(BuildContext context) async {
    try {
      // 1) Permissions
      final ok = await NotificationService.I.requestPermissions();
      if (!ok) {
        _showErrorMessage("Notifications permission denied");
        return;
      }

      // 2) IMMEDIATE TEST (shows now) - use SAME adhan channel to test sound settings


      _showSuccessMessage("Immediate notification sent ✅");

      // 3) Cancel previous test notifications (IDs 99900+)
      await _cancelTestNotifications();

      // 4) Schedule test after 5 seconds (Libya time)
      final libyaNow = _libyaNow;
      final scheduleTime = libyaNow.add(const Duration(seconds: 5));
      await NotificationService.I.scheduleOne(
        id: 99999,
        title: 'اختبار الأذان بعد 5 ثواني',
        body: 'لازم تسمع الصوت الآن',
        dateTime: scheduleTime,
        soundEnabled: true,
        soundRawNameAndroid: 'adhan_duqali',
        soundFileIOS: 'adhan.aiff',
      );
      _showSuccessMessage("Scheduled adhan test in 5 seconds ✅");

      // Optional countdown logs
      for (int i = 5; i > 0; i--) {
        await Future.delayed(const Duration(seconds: 1));
        debugPrint("⏳ Scheduled notification in $i seconds...");
      }
    } catch (e, st) {
      debugPrint("❌ Test failed: $e");
      debugPrint("Stack: $st");
      _showErrorMessage("Test failed: $e");
    }
  }

  Future<void> _cancelTestNotifications() async {
    final pending = await NotificationService.I.getPendingNotifications();
    for (final p in pending) {
      if (p.id >= 99900) {
        await NotificationService.I.cancel(p.id); // ✅ IMPORTANT
      }
    }
  }


  void _showSuccessMessage(String message) {
    debugPrint("🍞 Showing success snackbar: $message");
    if (!mounted) {
      debugPrint("⚠️ Not mounted, skipping snackbar");
      return;
    }
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      debugPrint("✅ Snackbar shown successfully");
    } catch (e) {
      debugPrint("❌ Could not show snackbar: $e");
    }
  }

  void _showErrorMessage(String message) {
    debugPrint("🍞 Showing error snackbar: $message");
    if (!mounted) {
      debugPrint("⚠️ Not mounted, skipping snackbar");
      return;
    }
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("✅ Snackbar shown successfully");
    } catch (e) {
      debugPrint("❌ Could not show snackbar: $e");
    }
  }

  // رمضان حسب طلبك يبدأ 19 Feb 2026
  final DateTime ramadanStart = DateTime(2026, 2, 9);
  final int ramadanDays = 30;

  // Default
  String _citySlug = 'tripoli';
  String _cityLabel = 'طرابلس';
  final DateTime? _mockDateOnly = null;

  // Selected date for viewing (arrows)
  DateTime _selectedDate = DateTime.now();

  // If user has navigated into Ramadan using arrows (even if today not Ramadan)
  bool _userNavigated = false;

  // Countdown
  Timer? _ticker;
  String _nextPrayerName = 'الفجر';

  Duration _remainingToFajr = Duration.zero;
  
  // Track which prayers have been triggered today to avoid duplicates
  Set<String> _triggeredPrayersToday = {};
  DateTime? _lastTriggerCheckDate;
  DateTime? _lastCountdownLog;

  /// Convert selected asset (from settings) to Android raw sound name.
  /// Example: assets/adhan/adhan_duqali.mp3 -> adhan_duqali
  /// Fallback: adhan_duqali
  String _adhanRawNameFromSelectedAsset(String assetPath) {
    if (assetPath.isEmpty) return 'adhan_duqali';
    final file = assetPath.split('/').last;
    final dot = file.lastIndexOf('.');
    final base = (dot >= 0) ? file.substring(0, dot) : file;
    final normalized = base.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    return normalized.isEmpty ? 'adhan_duqali' : normalized;
  }

  Future<String> _getSelectedAdhanRawNameAndroid() async {
    final prefs = await SharedPreferences.getInstance();
    final asset = prefs.getString('selectedSoundAsset') ?? 'assets/adhan/adhan_duqali.mp3';
    return _adhanRawNameFromSelectedAsset(asset);
  }

  DateTime get _now {
    final real = _libyaNow;
    if (_mockDateOnly == null) return real;

    return DateTime(2026, 2, 18, real.hour, real.minute, real.second);
  }

  // Data:
  // { citySlug: [ {date,fajr,sunrise,dhuhr,asr,maghrib,isha}, ... ] }
  Map<String, List<Map<String, dynamic>>> _db = {};

  // quick lookup for current selected day
  Map<String, String> _timesForSelected = {
    'الإمساك': '00:00',
    'الفجر': '00:00',
    'الشروق': '00:00',
    'الظهر': '00:00',
    'العصر': '00:00',
    'المغرب': '00:00',
    'العشاء': '00:00',
  };
  Future<void> _openSettings() async {
    final BuildContext currentContext = context; // Add this line
    final changed = await Navigator.push<bool>(
      currentContext, // Use currentContext
      MaterialPageRoute(builder: (_) => const SittingPage()),
    );

    if (changed == true) {
      await _loadPrefs();
      _refreshSelectedTimes();
      _updateCountdown();
      await _scheduleNext30DaysPrayers();
      if (mounted) setState(() {});
    }
  }


  // Minimal coords for nearest-city pick (وسعها براحتك)
  final Map<String, _CityCoord> _coords = {
    // already existing
    'tripoli': _CityCoord('طرابلس', 32.8872, 13.1913),
    'benghazi': _CityCoord('بنغازي', 32.1167, 20.0667),
    'misrata': _CityCoord('مصراتة', 32.3754, 15.0920),
    'ajdabiya': _CityCoord('اجدابيا', 30.7555, 20.2263),
    'sabha': _CityCoord('سبها', 27.0377, 14.4283),
    'tobruk': _CityCoord('طبرق', 32.0767, 23.9601),
    'derna': _CityCoord('درنة', 32.7640, 22.6390),
    'zawiya': _CityCoord('الزاوية', 32.7571, 12.7276),
    'zliten': _CityCoord('زليتن', 32.4674, 14.5687),
    'khoms': _CityCoord('الخمس', 32.6486, 14.2619),

    // added from JSON
    'bani-walid': _CityCoord('بني وليد', 31.7560, 13.9900),
    'sirte': _CityCoord('سرت', 31.2060, 16.5880),
    'zuwara': _CityCoord('زوارة', 32.9312, 12.0819),
    'zuwetina': _CityCoord('الزويتينة', 30.9522, 20.1200),
    'bayda': _CityCoord('البيضاء', 32.7627, 21.7551),
    'ras-lanuf': _CityCoord('رأس لانوف', 30.5000, 18.5000),
    'tobruk': _CityCoord('طبرق', 32.0767, 23.9601),
    'tajura': _CityCoord('تاجوراء', 32.8817, 13.3500),
    'sabratha': _CityCoord('صبراتة', 32.8070, 12.4850),
    'gharyan': _CityCoord('غريان', 32.1722, 13.0203),
    'zintan': _CityCoord('الزنتان', 31.9316, 12.2529),
    'nalut': _CityCoord('نالوت', 31.8687, 10.9810),
    'kufra': _CityCoord('الكفرة', 24.1997, 23.2905),
    'murzuq': _CityCoord('مرزق', 25.9155, 13.9184),
    'ubari': _CityCoord('أوباري', 26.5903, 12.7751),
    'ghat': _CityCoord('غات', 25.1333, 10.1667),
    'hun': _CityCoord('هون', 29.1268, 15.9477),
    'waddan': _CityCoord('ودان', 29.1614, 16.1390),
    'masallatah': _CityCoord('مسلاتة', 32.6150, 14.0000),
    'tarhuna': _CityCoord('ترهونة', 32.4350, 13.6330),
    'ajaylat': _CityCoord('العجيلات', 32.7570, 12.3760),
    'surman': _CityCoord('صرمان', 32.7550, 12.5710),
    'zaltan': _CityCoord('زلطن', 32.9460, 11.8660),
    'suluq': _CityCoord('سلوق', 31.6682, 20.2520),
  };

  @override
  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(_now);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _boot();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _adsTimer?.cancel();
    _adsController.dispose();
    super.dispose();
  }

  /// Default: صوت الأذان ON, صوت المؤذن الدوكالي — saved once if not set.
  Future<void> _ensureSoundDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('muezzinSoundEnabled') == null) {
      await prefs.setBool('muezzinSoundEnabled', true);
    }
    if (prefs.getString('selectedSoundAsset') == null || prefs.getString('selectedSoundAsset')!.isEmpty) {
      await prefs.setString('selectedSoundAsset', 'assets/adhan/adhan_duqali.mp3');
    }
  }

  Future<void> _boot() async {
    // 1) Load DB + prefs first
    await _ensureJsonLoadedAndCached();
    await _ensureSoundDefaults();
    await _loadPrefs();
    await _loadAdsOnlineOrOffline(); // ✅ HERE
    _startAdsAutoSlide();            // ✅ مهم

    // 2) Refresh UI + countdown
    _refreshSelectedTimes();
    _startTicker();

    // 3) ✅ Schedule prayers for the next 30 days (local notifications)
    await _scheduleNext30DaysPrayers();

    // 4) (Optional) Debug pending notifications
    await _debugScheduledNotifications();

  }

  /// Schedules prayer notifications for every day in the JSON (today or in the future).
  /// Runs once on app open (and when settings change). No day limit — all JSON days are scheduled.
  Future<void> _scheduleNext30DaysPrayers() async {
    debugPrint("[Adhan] _scheduleNext30DaysPrayers() started");
    final now = _now; // Libya current moment
    final todayOnly = _dateOnly(now);
    final loc = tz.getLocation('Africa/Tripoli');

    final prefs = await SharedPreferences.getInstance();

    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    if (!notificationsEnabled) {
      debugPrint("[Adhan] Notifications disabled, skipping scheduling");
      await _cancelPrayerNotifications();
      return;
    }

    final atAdhanEnabled = <String, bool>{
      'fajr': prefs.getBool('at_adhan_fajr') ?? true,
      'dhuhr': prefs.getBool('at_adhan_dhuhr') ?? true,
      'asr': prefs.getBool('at_adhan_asr') ?? true,
      'maghrib': prefs.getBool('at_adhan_maghrib') ?? true,
      'isha': prefs.getBool('at_adhan_isha') ?? true,
    };

    final muezzinSoundEnabled = prefs.getBool('muezzinSoundEnabled') ?? true;
    final selectedRaw = await _getSelectedAdhanRawNameAndroid();
    debugPrint("[Adhan] Scheduling: muezzinSoundEnabled=$muezzinSoundEnabled, selectedRaw=$selectedRaw (Android: res/raw/$selectedRaw.mp3 must exist for sound)");

    await _cancelPrayerNotifications();

    final rows = _db[_citySlug];
    if (rows == null || rows.isEmpty) {
      debugPrint("[Adhan] No prayer data for city: $_citySlug");
      return;
    }

    // Build list of days in JSON that are today or in the future (then sort by date)
    final List<Map<String, dynamic>> daysToSchedule = [];
    for (final r in rows) {
      final raw = (r['date'] ?? r['gregorian'] ?? '').toString().trim();
      final dayKey = _toIsoDateKey(raw);
      if (dayKey.isEmpty) continue;
      final dayOnly = DateTime.parse(dayKey);
      if (_isBeforeDate(dayOnly, todayOnly)) continue;
      daysToSchedule.add(r);
    }
    daysToSchedule.sort((a, b) {
      final keyA = _toIsoDateKey((a['date'] ?? a['gregorian'] ?? '').toString().trim());
      final keyB = _toIsoDateKey((b['date'] ?? b['gregorian'] ?? '').toString().trim());
      return keyA.compareTo(keyB);
    });
    // No cap: schedule all days in JSON (today or future)

    int scheduledCount = 0;
    int dayIndex = 0;
    for (final times in daysToSchedule) {
      final raw = (times['date'] ?? times['gregorian'] ?? '').toString().trim();
      final dayKey = _toIsoDateKey(raw);
      if (dayKey.isEmpty) continue;
      final dayOnly = DateTime.parse(dayKey);

      // Build prayer times as Libya TZDateTime so "past" check and scheduling are correct
      tz.TZDateTime dt(String key) {
        final hhmm = (times[key] ?? '00:00') as String;
        final parts = hhmm.split(':');
        final hh = int.tryParse(parts[0]) ?? 0;
        final mm = int.tryParse(parts[1]) ?? 0;
        return tz.TZDateTime(loc, dayOnly.year, dayOnly.month, dayOnly.day, hh, mm, 0);
      }

      final ordered = [
        {'key': 'fajr', 'name': 'الفجر', 'time': dt('fajr')},
        {'key': 'dhuhr', 'name': 'الظهر', 'time': dt('dhuhr')},
        {'key': 'asr', 'name': 'العصر', 'time': dt('asr')},
        {'key': 'maghrib', 'name': 'المغرب', 'time': dt('maghrib')},
        {'key': 'isha', 'name': 'العشاء', 'time': dt('isha')},
      ];

      for (int i = 0; i < ordered.length; i++) {
        final item = ordered[i];
        final key = item['key'] as String;
        if (!(atAdhanEnabled[key] ?? true)) continue;

        final prayerTime = item['time'] as tz.TZDateTime;
        if (prayerTime.isBefore(now)) continue;

        final prayerName = item['name'] as String;
        final id = 100 + dayIndex * 5 + i;

        await NotificationService.I.scheduleOne(
          id: id,
          title: 'حان وقت الأذان',
          body: 'حان الآن وقت صلاة $prayerName',
          dateTime: prayerTime,
          soundEnabled: muezzinSoundEnabled,
          soundRawNameAndroid: selectedRaw,
          soundFileIOS: 'adhan.aiff',
        );
        scheduledCount++;
      }
      dayIndex++;
    }

    debugPrint("[Adhan] Scheduled $scheduledCount prayer notifications for ${daysToSchedule.length} days. Each prayer fires once; tap opens app. Sound=$muezzinSoundEnabled, raw=$selectedRaw");
    await _debugScheduledNotifications();
  }

  Future<void> _cancelPrayerNotifications() async {
    final pending = await NotificationService.I.getPendingNotifications();
    int n = 0;
    for (final p in pending) {
      if (p.id >= 100 && p.id < 10000) {
        await NotificationService.I.cancel(p.id);
        n++;
      }
    }
    if (n > 0) debugPrint("[Adhan] _cancelPrayerNotifications: cancelled $n prayer notifications");
  }

  Future<void> _debugScheduledNotifications() async {
    try {
      final pending = await NotificationService.I.getPendingNotifications();
      debugPrint("[Adhan] Pending notifications: ${pending.length}");
      if (pending.isEmpty) {
        debugPrint("[Adhan] No pending notifications (schedule may have failed or none for future)");
      } else {
        for (final p in pending) {
          debugPrint("[Adhan]   id=${p.id}, title=${p.title}");
        }
      }
    } catch (e) {
      debugPrint("[Adhan] Error getting pending notifications: $e");
    }
  }
  Future<void> _ensureJsonLoadedAndCached() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('ramadan_db_json');
    if (cached != null && cached.isNotEmpty) {
      _db = _decodeDb(cached);
      return;
    }

    // Load from assets once
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

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _citySlug = prefs.getString('city_slug') ?? 'tripoli';
    _cityLabel = prefs.getString('city_label') ??
        (_coords[_citySlug]?.name ?? 'طرابلس');

    final sd = prefs.getString('selected_date'); // yyyy-MM-dd
    if (sd != null) {
      final dt = DateTime.tryParse(sd);
      if (dt != null) _selectedDate = _dateOnly(dt);
    }

    _userNavigated = prefs.getBool('user_navigated') ?? false;

    setState(() {});
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city_slug', _citySlug);
    await prefs.setString('city_label', _cityLabel);
    await prefs.setString('selected_date', _dateKey(_selectedDate));
    await prefs.setBool('user_navigated', _userNavigated);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
    _updateCountdown();
  }

  void _updateCountdown() {
    final now = _now;
    final todayOnly = _dateOnly(now);

    // Reset triggered prayers if it's a new day
    if (_lastTriggerCheckDate == null || !_isSameDate(_dateOnly(_lastTriggerCheckDate!), todayOnly)) {
      _triggeredPrayersToday.clear();
      _lastTriggerCheckDate = todayOnly;
    }

    // لو اليوم مش موجود في JSON => ما فيش رمضان => 00
    if (!_hasRowForDate(_citySlug, todayOnly)) {
      setState(() {
        _remainingToFajr = Duration.zero;
        _nextPrayerName = 'الفجر';
      });
      return;
    }

    // نجيب أوقات اليوم من JSON — use Libya timezone so comparison with _now (Libya) is correct
    final todayKey = _dateKey(todayOnly);
    final times = _findTimesByDate(_citySlug, todayKey);
    if (times == null) {
      setState(() {
        _remainingToFajr = Duration.zero;
        _nextPrayerName = 'الفجر';
      });
      return;
    }

    final loc = tz.getLocation('Africa/Tripoli');
    tz.TZDateTime prayerTimeLibya(String key) {
      final t = (times[key] ?? '00:00') as String;
      final parts = t.split(':');
      final hh = int.tryParse(parts[0]) ?? 0;
      final mm = int.tryParse(parts[1]) ?? 0;
      return tz.TZDateTime(loc, todayOnly.year, todayOnly.month, todayOnly.day, hh, mm, 0);
    }

    final fajr = prayerTimeLibya('fajr');
    final dhuhr = prayerTimeLibya('dhuhr');
    final asr = prayerTimeLibya('asr');
    final maghrib = prayerTimeLibya('maghrib');
    final isha = prayerTimeLibya('isha');

    // Show in-app notification ONLY when we are exactly in the prayer minute (Libya time). One time only per prayer.
    final prayersToCheck = [
      {'name': 'الفجر', 'time': fajr, 'key': 'fajr'},
      {'name': 'الظهر', 'time': dhuhr, 'key': 'dhuhr'},
      {'name': 'العصر', 'time': asr, 'key': 'asr'},
      {'name': 'المغرب', 'time': maghrib, 'key': 'maghrib'},
      {'name': 'العشاء', 'time': isha, 'key': 'isha'},
    ];

    for (final prayer in prayersToCheck) {
      final prayerTime = prayer['time'] as tz.TZDateTime;
      final prayerName = prayer['name'] as String;
      final prayerKey = prayer['key'] as String;
      final prayerMinuteEnd = prayerTime.add(const Duration(minutes: 1));
      if (now.isBefore(prayerTime) || !now.isBefore(prayerMinuteEnd)) continue;

      final triggerKey = '${_dateKey(todayOnly)}_$prayerKey';

    }

    // نحدد الصلاة الجاية بناء على الوقت الحالي (Libya)
    tz.TZDateTime target;
    String name;

    if (now.isBefore(fajr)) {
      target = fajr;
      name = 'الفجر';
    } else if (now.isBefore(dhuhr)) {
      target = dhuhr;
      name = 'الظهر';
    } else if (now.isBefore(asr)) {
      target = asr;
      name = 'العصر';
    } else if (now.isBefore(maghrib)) {
      target = maghrib;
      name = 'المغرب';
    } else if (now.isBefore(isha)) {
      target = isha;
      name = 'العشاء';
    } else {
      // بعد العشاء -> نجيب فجر الغد
      final tomorrowOnly = todayOnly.add(const Duration(days: 1));
      final tomorrowKey = _dateKey(tomorrowOnly);
      final t2 = _findTimesByDate(_citySlug, tomorrowKey);

      if (t2 != null) {
        final fajrStr = (t2['fajr'] ?? '00:00') as String;
        final parts = fajrStr.split(':');
        final hh = int.tryParse(parts[0]) ?? 0;
        final mm = int.tryParse(parts[1]) ?? 0;
        target = tz.TZDateTime(loc, tomorrowOnly.year, tomorrowOnly.month, tomorrowOnly.day, hh, mm, 0);
        name = 'الفجر';
      } else {
        setState(() {
          _remainingToFajr = Duration.zero;
          _nextPrayerName = 'الفجر';
        });
        return;
      }
    }

    final diff = target.difference(now);

    // Log countdown every 60s to track in logcat without spam
    final nowStamp = DateTime.now();
    if (_lastCountdownLog == null || nowStamp.difference(_lastCountdownLog!).inSeconds >= 60) {
      _lastCountdownLog = nowStamp;
      debugPrint("[Adhan] Countdown: next=$name in ${diff.inMinutes}m (Libya now=$now)");
    }

    setState(() {
      _remainingToFajr = diff.isNegative ? Duration.zero : diff;
      _nextPrayerName = name;
    });
  }

  /// Prayer name (Arabic) -> pref key for "at adhan"
  static String _prayerNameToKey(String name) {
    switch (name) {
      case 'الفجر': return 'fajr';
      case 'الظهر': return 'dhuhr';
      case 'العصر': return 'asr';
      case 'المغرب': return 'maghrib';
      case 'العشاء': return 'isha';
      default: return '';
    }
  }

  /// Prayer key -> index in ordered list (fajr=0, dhuhr=1, asr=2, maghrib=3, isha=4).
  static int _prayerKeyToIndex(String key) {
    switch (key) {
      case 'fajr': return 0;
      case 'dhuhr': return 1;
      case 'asr': return 2;
      case 'maghrib': return 3;
      case 'isha': return 4;
      default: return -1;
    }
  }

  /// Returns the scheduled notification id for today's prayer (so we can cancel it when showing immediate = one notification only).
  int? _getScheduledNotificationIdForTodayPrayer(String prayerKey) {
    final now = _now;
    final todayOnly = _dateOnly(now);
    final loc = tz.getLocation('Africa/Tripoli');
    final rows = _db[_citySlug];
    if (rows == null || rows.isEmpty) return null;

    final List<Map<String, dynamic>> daysToSchedule = [];
    for (final r in rows) {
      final raw = (r['date'] ?? r['gregorian'] ?? '').toString().trim();
      final dayKey = _toIsoDateKey(raw);
      if (dayKey.isEmpty) continue;
      final dayOnly = DateTime.parse(dayKey);
      if (_isBeforeDate(dayOnly, todayOnly)) continue;

// ✅ لا نُجدول إشعارات اليوم (عشان اليوم حيكون فوري داخل التطبيق)
      if (_isSameDate(dayOnly, todayOnly)) continue;

      daysToSchedule.add(r);
    }
    daysToSchedule.sort((a, b) {
      final keyA = _toIsoDateKey((a['date'] ?? a['gregorian'] ?? '').toString().trim());
      final keyB = _toIsoDateKey((b['date'] ?? b['gregorian'] ?? '').toString().trim());
      return keyA.compareTo(keyB);
    });

    final todayKey = _dateKey(todayOnly);
    int dayIndex = 0;
    for (final r in daysToSchedule) {
      final raw = (r['date'] ?? r['gregorian'] ?? '').toString().trim();
      if (_toIsoDateKey(raw) == todayKey) {
        final prayerIndex = _prayerKeyToIndex(prayerKey);
        if (prayerIndex < 0) return null;
        return 100 + dayIndex * 5 + prayerIndex;
      }
      dayIndex++;
    }
    return null;
  }

  // ✅ Trigger prayer notification and adhan when prayer time arrives (app in foreground). One notification only: cancel scheduled for this prayer so it doesn't fire too.
  Future<void> _triggerPrayerImmediately(String prayerName) async {
    try {
      final key = _prayerNameToKey(prayerName);
      debugPrint("[Adhan] _triggerPrayerImmediately: prayerName=$prayerName, key=$key");

      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      if (!notificationsEnabled) {
        debugPrint("[Adhan] _triggerPrayerImmediately: notifications disabled, skip");
        return;
      }

      if (key.isNotEmpty) {
        final prayerEnabled = prefs.getBool('at_adhan_$key') ?? true;
        if (!prayerEnabled) {
          debugPrint("[Adhan] _triggerPrayerImmediately: prayer $key disabled, skip");
          return;
        }
      }

      // One notification only: cancel the scheduled one for this prayer so we don't get two (scheduled + immediate).
      final scheduledId = key.isNotEmpty ? _getScheduledNotificationIdForTodayPrayer(key) : null;
      if (scheduledId != null) {
        debugPrint("[Adhan] _triggerPrayerImmediately: cancelling scheduled id=$scheduledId so only one notification shows");
        await NotificationService.I.cancel(scheduledId);
      }

      final muezzinSoundEnabled = prefs.getBool('muezzinSoundEnabled') ?? true;
      final selectedAsset =
          prefs.getString('selectedSoundAsset') ?? 'assets/adhan/adhan_duqali.mp3';
      final selectedRaw = _adhanRawNameFromSelectedAsset(selectedAsset);
      debugPrint("[Adhan] _triggerPrayerImmediately: soundEnabled=$muezzinSoundEnabled, selectedRaw=$selectedRaw (Android needs res/raw/$selectedRaw.mp3)");

      await NotificationService.I.showImmediate(
        id: 200,
        title: 'حان وقت الأذان',
        body: 'حان الآن وقت صلاة $prayerName',
        soundEnabled: muezzinSoundEnabled,
        soundRawNameAndroid: selectedRaw,
        soundFileIOS: 'adhan.aiff',
      );
      debugPrint("[Adhan] _triggerPrayerImmediately: showed one notification for $prayerName (sound=$muezzinSoundEnabled)");
    } catch (e, st) {
      debugPrint("❌ [Adhan] Error triggering immediate prayer notification: $e");
      debugPrint("❌ [Adhan] Stack: $st");
    }
  }

  String _formatHMS(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  // Rules you asked:
  // - If not Ramadan yet: times = zero unless user navigates to Ramadan range

  bool _hasRowForDate(String city, DateTime d) {
    final key = _dateKey(d); // yyyy-MM-dd
    return _findTimesByDate(city, key) != null;
  }

  bool get _shouldShowRealTimes {
    // اليوم: لو موجود في JSON = رمضان = اعرض الأوقات
    final today = _now;
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (_hasRowForDate(_citySlug, todayOnly)) return true;

    // لو مش رمضان اليوم: ما تعرضش إلا إذا المستخدم تنقل بالأسهم
    return _userNavigated && _hasRowForDate(_citySlug, _selectedDate);
  }

  bool _isDateInRamadan(DateTime d) {
    final start = _dateOnly(ramadanStart);
    final end = start.add(Duration(days: ramadanDays - 1));
    final x = _dateOnly(d);
    return !_isBeforeDate(x, start) && !_isAfterDate(x, end);
  }

  bool _isBeforeDate(DateTime a, DateTime b) => _dateOnly(a).isBefore(_dateOnly(b));
  bool _isAfterDate(DateTime a, DateTime b) => _dateOnly(a).isAfter(_dateOnly(b));
  bool _isSameDate(DateTime a, DateTime b) {
    final aOnly = _dateOnly(a);
    final bOnly = _dateOnly(b);
    return aOnly.year == bOnly.year && aOnly.month == bOnly.month && aOnly.day == bOnly.day;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _timeOnDate(DateTime dateOnly, String hhmm) {
    final parts = hhmm.split(':');
    final hh = int.tryParse(parts[0]) ?? 0;
    final mm = int.tryParse(parts[1]) ?? 0;
    return DateTime(dateOnly.year, dateOnly.month, dateOnly.day, hh, mm);
  }

  String _dateKey(DateTime d) => _dateOnly(d).toIso8601String().substring(0, 10);

  Map<String, dynamic>? _findTimesByDate(String city, String dateKeyIso) {
    final rows = _db[city];
    if (rows == null) return null;

    for (final r in rows) {
      // جرّب نجيب التاريخ من أكثر من مفتاح محتمل
      final raw = (r['date'] ??
          r['gregorian'] ??
          r['ميلادي'] ??
          r['الميلادي'] ??
          r['day'] ??
          '')
          .toString()
          .trim();

      final rowIso = _toIsoDateKey(raw);
      if (rowIso == dateKeyIso) return r;
    }

    return null;
  }

  /// يحاول يحول أي صيغة تاريخ إلى yyyy-MM-dd
  /// يقبل:
  ///  - 2026-02-19
  ///  - 2026-2-19
  ///  - 19-2-2026
  ///  - 19/2/2026
  ///  - 19-2  (يعتبرها سنة رمضان 2026)
  ///  - 19 فيفري / 19 فبراير / 19 Feb  (يعتبرها 2026)
  String _toIsoDateKey(String raw) {
    if (raw.isEmpty) return '';

    // 1) إذا أصلاً ISO أو قريب منه: 2026-2-19
    final isoLike = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$');
    final m1 = isoLike.firstMatch(raw);
    if (m1 != null) {
      final y = int.parse(m1.group(1)!);
      final mo = int.parse(m1.group(2)!);
      final d = int.parse(m1.group(3)!);
      return DateTime(y, mo, d).toIso8601String().substring(0, 10);
    }

    // 2) dd-mm-yyyy أو dd/mm/yyyy
    final dmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$');
    final m2 = dmy.firstMatch(raw);
    if (m2 != null) {
      final d = int.parse(m2.group(1)!);
      final mo = int.parse(m2.group(2)!);
      final y = int.parse(m2.group(3)!);
      return DateTime(y, mo, d).toIso8601String().substring(0, 10);
    }

    // 3) dd-mm أو dd/mm (بدون سنة) -> نفترض سنة رمضان 2026
    final dm = RegExp(r'^(\d{1,2})[-/](\d{1,2})$');
    final m3 = dm.firstMatch(raw);
    if (m3 != null) {
      final d = int.parse(m3.group(1)!);
      final mo = int.parse(m3.group(2)!);
      return DateTime(2026, mo, d).toIso8601String().substring(0, 10);
    }

    // 4) نص فيه شهر (فيفري/فبراير/March/Feb...)
    // نلتقط الرقم الأول كـ day
    final dayMatch = RegExp(r'(\d{1,2})').firstMatch(raw);
    if (dayMatch != null) {
      final day = int.parse(dayMatch.group(1)!);

      final lower = raw.toLowerCase();

      int? month;
      if (lower.contains('feb') || lower.contains('فيف') || lower.contains('فبراير')) month = 2;
      if (lower.contains('mar') || lower.contains('مارس')) month = 3;

      if (month != null) {
        return DateTime(2026, month, day).toIso8601String().substring(0, 10);
      }
    }

    // لو فشلنا
    return '';
  }

  void _setZeroTimes() {
    setState(() {
      _timesForSelected = {
        'الإمساك': '00:00',
        'الفجر': '00:00',
        'الشروق': '00:00',
        'الظهر': '00:00',
        'العصر': '00:00',
        'المغرب': '00:00',
        'العشاء': '00:00',
      };
    });
  }

  void _refreshSelectedTimes() {
    final key = _dateKey(_selectedDate);
    final t = _findTimesByDate(_citySlug, key);

    // إذا مش لازم نعرض أوقات أو التاريخ مش موجود في JSON -> 00:00
    if (!_shouldShowRealTimes || t == null) {
      setState(() {
        _timesForSelected = {
          'الإمساك': '00:00',
          'الفجر': '00:00',
          'الشروق': '00:00',
          'الظهر': '00:00',
          'العصر': '00:00',
          'المغرب': '00:00',
          'العشاء': '00:00',
        };
      });
      return;
    }

    final fajr = (t['fajr'] ?? '00:00') as String;

    setState(() {
      _timesForSelected = {
        'الإمساك': fajr,
        'الفجر': fajr,
        'الشروق': (t['sunrise'] ?? '00:00') as String,
        'الظهر': (t['dhuhr'] ?? '00:00') as String,
        'العصر': (t['asr'] ?? '00:00') as String,
        'المغرب': (t['maghrib'] ?? '00:00') as String,
        'العشاء': (t['isha'] ?? '00:00') as String,
      };
    });

    print("city=$_citySlug key=$key rows=${_db[_citySlug]?.length}");

  }

  void _goPrevDay() {
    setState(() {
      _userNavigated = true;
      _selectedDate = _dateOnly(_selectedDate).subtract(const Duration(days: 1));
    });
    _refreshSelectedTimes();
    _savePrefs();
  }

  void _goNextDay() {
    setState(() {
      _userNavigated = true;
      _selectedDate = _dateOnly(_selectedDate).add(const Duration(days: 1));
    });
    _refreshSelectedTimes();
    _savePrefs();


  }
  void _showCityDialog(String cityName) {
    final BuildContext currentContext = context; // Add this line
    showDialog(
      context: currentContext, // Use currentContext
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '📍 تم تحديد موقعك',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'مدينتك هي\n\n$cityName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('تمام'),
            ),
          ],
        );
      },
    );
  }  Future<void> _pickCityByLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack("خدمة الموقع (GPS) مقفلة");
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _snack("تم رفض إذن الموقع");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String bestSlug = _citySlug;
      double bestDist = double.infinity;

      for (final entry in _coords.entries) {
        final d = _haversineKm(
          pos.latitude,
          pos.longitude,
          entry.value.lat,
          entry.value.lng,
        );
        if (d < bestDist) {
          bestDist = d;
          bestSlug = entry.key;
        }
      }

      setState(() {
        _citySlug = bestSlug;
        _cityLabel = _coords[bestSlug]?.name ?? bestSlug;
      });

      _refreshSelectedTimes();
      _updateCountdown();
      await _savePrefs();

// ✅ popup بعد النجاح
      _showCityDialog(_cityLabel);

      _snack("تم اختيار: $_cityLabel");
    } catch (_) {
      _snack("تعذر تحديد الموقع");
    }
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    double toRad(double x) => x * (_m.pi / 180.0);

    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);

    final a = (_m.sin(dLat / 2) * _m.sin(dLat / 2)) +
        _m.cos(toRad(lat1)) *
            _m.cos(toRad(lat2)) *
            (_m.sin(dLon / 2) * _m.sin(dLon / 2));

    final c = 2 * _m.atan2(_m.sqrt(a), _m.sqrt(1 - a));
    return r * c;
  }
  DateTime get _libyaNow {
    final libyaLocation = tz.getLocation('Africa/Tripoli');
    return tz.TZDateTime.now(libyaLocation);
  }

  Widget _buildAdsCarousel() {
    if (_adsSlides.isEmpty) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: screenHeight * 0.38,
          child: PageView.builder(
            controller: _adsController,
            itemCount: _adsSlides.length,
            onPageChanged: (i) {
              setState(() => _adsIndex = i);
              // Restart timer so user interaction doesn't fight auto-scroll
              _startAdsAutoSlide();
            },
            itemBuilder: (_, i) {
              final s = _adsSlides[i];
              return AnimatedPadding(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: i == _adsIndex ? 0 : 6),
                child: _AdCard(slide: s),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: AnimatedSmoothIndicator(
            activeIndex: _adsIndex,
            count: _adsSlides.length,
            effect: const ExpandingDotsEffect(
              expansionFactor: 3.5,
              dotHeight: 8,
              dotWidth: 8,
              spacing: 6,
              activeDotColor: Color(0xFF2196F3),
              dotColor: Color(0xFFBBDEFB),
            ),
            onDotClicked: (i) {
              _adsController.animateToPage(
                i,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut,
              );
              setState(() => _adsIndex = i);
              _startAdsAutoSlide();
            },
          ),
        ),
      ],
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  @override
  Widget build( BuildContext context) {
    final todayText = DateFormat('yyyy-MM-dd').format(_now);
    final selectedText = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('إمساكية رمضان - $_cityLabel'),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings, // ✅ هنا تستدعيها
            tooltip: 'الإعدادات',
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                _buildAdsCarousel(),
                const SizedBox(height: 14),

              ],
            ),

            // Countdown Card
            Card(
              elevation: 8,
              shadowColor: Colors.blueGrey.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      ' بقي على أذان  $_nextPrayerName',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.blueGrey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _formatHMS(_remainingToFajr),
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.grey,
                              Colors.red,
                              Colors.blue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(
                            const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                          ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: 0.65,
                        minHeight: 10,
                        backgroundColor: Colors.blueGrey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ],
                )


              ),
            ),

            const SizedBox(height: 15),

            // Prayer Times Card
            Card(
              elevation: 6,
              shadowColor: Colors.grey.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // header row: right arrow (prev) - title - left arrow (next)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _goNextDay,
                          icon: const Icon(Icons.chevron_left),
                          color: Colors.grey.shade700,
                        ),
                        const Expanded(
                          child: Text(
                            'اوقات الصلاة اليوم',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _goPrevDay,
                          icon: const Icon(Icons.chevron_right),
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '    $selectedText',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'المدينة: $_cityLabel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    PrayerTimeRowPro(
                      name: 'الفجر',
                      time: _timesForSelected['الفجر']!,
                      iconColor: const Color(0xFF2196F3),
                      timeColor: const Color(0xFF2196F3),
                    ),
                    PrayerTimeRowPro(
                      name: 'الشروق',
                      time: _timesForSelected['الشروق']!,
                      iconColor: const Color(0xFF2196F3),
                      timeColor: const Color(0xFF2196F3),
                    ),
                    PrayerTimeRowPro(
                      name: 'الظهر',
                      time: _timesForSelected['الظهر']!,
                      iconColor: const Color(0xFF2196F3),
                      timeColor: const Color(0xFF2196F3),
                    ),
                    PrayerTimeRowPro(
                      name: 'العصر',
                      time: _timesForSelected['العصر']!,
                      iconColor: const Color(0xFF2196F3),
                      timeColor: const Color(0xFF2196F3),
                    ),
                    PrayerTimeRowPro(
                      name: 'المغرب',
                      time: _timesForSelected['المغرب']!,
                      iconColor: const Color(0xFF2196F3),
                      timeColor: const Color(0xFF2196F3),
                    ),
                    PrayerTimeRowPro(
                      name: 'العشاء',
                      time: _timesForSelected['العشاء']!,
                      iconColor: const Color(0xFF2196F3),
                      timeColor: const Color(0xFF2196F3),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // In your build method, find the FloatingActionButton for testing:

            // Dua Card
            Card(
              color: const Color(0xFFFFF3E0),
              elevation: 6,
              shadowColor: Colors.grey.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _pickCityByLocation,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.location_on, size: 30, color: Colors.white),
      ),

      bottomNavigationBar: const Rashad(currentIndex: 0),
    );
  }

  Widget _buildPackageCard(String title, String price) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(left: 16), // RTL
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),

        ],
      ),

    );
  }
}

// --- Widgets & helpers ---
// Add this method to _MainScreenState
// Remove the old _testNotification() method and replace it with this:

// Inside _MainScreenState class, update this method:


class PrayerTimeRowPro extends StatelessWidget {
  final String name;
  final String time;
  final Color? iconColor;
  final Color? timeColor;

  const PrayerTimeRowPro({
    super.key,
    required this.name,
    required this.time,
    this.iconColor,
    this.timeColor,
  });

  @override
  Widget build(BuildContext context  ) {
    IconData icon;
    switch (name) {
      case 'الفجر':
        icon = Icons.wb_sunny;
        break;
      case 'الشروق':
        icon = Icons.sunny;
        break;
      case 'الظهر':
        icon = Icons.wb_sunny_outlined;
        break;
      case 'العصر':
        icon = Icons.brightness_low;
        break;
      case 'المغرب':
        icon = Icons.sunny;
        break;
      case 'العشاء':
        icon = Icons.nights_stay;
        break;
      default:
        icon = Icons.access_time;
    }

    const TextStyle nameStyle = TextStyle(
      color: Color(0xFF2196F3),
      fontSize: 17,
      fontWeight: FontWeight.w600,
    );
    final TextStyle timeStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.bold,
      color: timeColor ?? Colors.black87,
    );

    // الكل في الوسط: الوقت يسار ثم : ثم الأيقونة ثم الفجر يمين
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(time, style: timeStyle),
          const SizedBox(width: 8),
          Text(' : ', style: nameStyle),
          const SizedBox(width: 8),
          Icon(icon, color: iconColor ?? Colors.orangeAccent, size: 22),
          const SizedBox(width: 12),
          Text(name, style: nameStyle),
        ],
      ),
    );
  }
}

class _CityCoord {
  final String name;
  final double lat;
  final double lng;
  const _CityCoord(this.name, this.lat, this.lng);
}
class _AdSlide {
  final String image; // can be asset path OR network url
  final bool isNetwork;
  final String title;
  final String subtitle;
  final String url;

  const _AdSlide({
    required this.image,
    required this.isNetwork,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  factory _AdSlide.fromJson(Map<String, dynamic> j) {
    return _AdSlide(
      image: (j['imageUrl'] ?? '').toString().trim(),
      isNetwork: true,
      title: (j['title'] ?? '').toString(),
      subtitle: (j['subtitle'] ?? '').toString(),
      url: (j['url'] ?? '').toString(),
    );
  }
}

class _AdCard extends StatelessWidget {
  final _AdSlide slide;
  const _AdCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(slide.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            slide.isNetwork
                ? Image.network(
              slide.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Image.network(
                    slide.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      debugPrint("❌ Image failed: ${slide.image}");
                      debugPrint("❌ error: $error");
                      return Image.asset('assets/ads/ad7.jpg', fit: BoxFit.cover);
                    },
                  )
            )
                : Image.asset(slide.image, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0D47A1).withOpacity(0.75),
                    const Color(0xFF2196F3).withOpacity(0.25),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      slide.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slide.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

