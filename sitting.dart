import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as _m;
import 'bt.dart';
import 'main.dart';
import 'notification_service.dart';

// اختياري للموقع
// import 'package:geolocator/geolocator.dart';

class SittingPage extends StatefulWidget {
  const SittingPage({super.key});

  @override
  State<SittingPage> createState() => _SittingPageState();
}

class _SittingPageState extends State<SittingPage> {
  // Settings
  bool autoLocation = true; // تحديد تلقائي
  bool notificationsEnabled = true; // تفعيل التنبيهات
  bool muezzinSoundEnabled = true; // صوت المؤذن
  bool _changed = false;

  String selectedCity = "طرابلس";
  List<String> libyaCities = [];

  // Sounds
  final List<MuezzinSound> sounds = const [
    MuezzinSound(name: "صوت الدوكالي", assetPath: "assets/adhan/adhan_duqali.mp3"),
    MuezzinSound(name: "صوت 2", assetPath: "assets/adhan/adhan_sound2.mp3"),
    MuezzinSound(name: "صوت 3", assetPath: "assets/adhan/sound3.mp3"),
    MuezzinSound(name: "صوت 4", assetPath: "assets/adhan/sound4.mp3"),
    MuezzinSound(name: "صوت 5", assetPath: "assets/adhan/sound5.mp3"),
  ];

  String selectedSoundAsset = "assets/adhan/adhan_duqali.mp3";
  final AudioPlayer _player = AudioPlayer();

  // Bottom nav demo
  int bottomIndex = 2; // settings

  @override
  @override
  void initState() {
    super.initState();
    _loadCities();
    _loadPrefs().then((_) async {
      await _askNotifPermissionOnce();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  Future<void> _askNotifPermissionOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('asked_notif_perm') ?? false;
    if (asked) return;

    // لازم تكون init() تمت قبل
    final ok = await NotificationService.I.requestPermissions();

    await prefs.setBool('asked_notif_perm', true);

    if (!ok) {
      _toast("تم رفض إذن التنبيهات");
    }
  }

  Future<void> _loadCities() async {
    try {
      final raw = await rootBundle.loadString('assets/libya_cities.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final cities = (data['cities'] as List).map((e) => e.toString()).toList();
      if (!mounted) return;
      setState(() => libyaCities = cities);
    } catch (e) {
      // لو الملف مش موجود / خطأ في JSON
      if (!mounted) return;
      _toast("مشكلة في قراءة ملف المدن");
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


  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      autoLocation = prefs.getBool('autoLocation') ?? true;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      muezzinSoundEnabled = prefs.getBool('muezzinSoundEnabled') ?? true;
      selectedCity = prefs.getString('city_label') ?? "طرابلس";
      selectedSoundAsset =
          prefs.getString('selectedSoundAsset') ?? "assets/adhan/adhan_duqali.mp3";
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // ---- Location logic (اختياري) ----
  Future<void> _enableTrackingLocation() async {
    // مهم: لو المدن لسه ما اتحمّلت من JSON
    if (libyaCities.isEmpty) {
      await _loadCities();
    }

    // 1) تأكد GPS شغال
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _toast("فعّل GPS من الجهاز");
      setState(() => autoLocation = false);
      await _saveBool('autoLocation', false);
      return;
    }

    // 2) طلب الإذن
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _toast("لازم إذن الموقع");
      setState(() => autoLocation = false);
      await _saveBool('autoLocation', false);
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _toast("الإذن مرفوض نهائياً — فعّله من الإعدادات");
      setState(() => autoLocation = false);
      await _saveBool('autoLocation', false);
      return;
    }

    // 3) خذ الإحداثيات
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 4) فلترة coords بناء على المدن الموجودة في JSON فقط
    final allowedArabic = libyaCities.toSet();

    final allowedEntries = libyaCityCoords.entries
        .where((e) => allowedArabic.contains(e.value.name))
        .toList();

    if (allowedEntries.isEmpty) {
      _toast("ملف المدن (JSON) ما فيهش مدن مطابقة للإحداثيات");
      return;
    }

    // 5) اختار أقرب مدينة
    String bestSlug = allowedEntries.first.key;
    double bestDist = double.infinity;

    for (final e in allowedEntries) {
      final d = _haversineKm(
        pos.latitude,
        pos.longitude,
        e.value.lat,
        e.value.lng,
      );
      if (d < bestDist) {
        bestDist = d;
        bestSlug = e.key;
      }
    }

    final bestLabel = libyaCityCoords[bestSlug]!.name;

    setState(() => selectedCity = bestLabel);

    // ✅ نفس مفاتيح MainScreen
    await _saveString('city_label', bestLabel);
    await _saveString('city_slug', bestSlug);
    if (!mounted) return;

    _toast("تم تحديد المدينة تلقائياً: $bestLabel");

  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pickCityDialog() async {
    if (libyaCities.isEmpty) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "اختر مدينة",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: libyaCities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final city = libyaCities[i];
                    final selected = city == selectedCity;
                    return ListTile(
                      title: Text(city),
                      trailing: selected
                          ? const Icon(Icons.check_circle)
                          : const SizedBox.shrink(),
                      onTap: () => Navigator.pop(ctx, city),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final slug = _slugFromArabic(result);
      setState(() => selectedCity = result);

      await _saveString('city_label', result);
      await _saveString('city_slug', slug);

      _changed = true;
  }

  }

  Future<void> _pickSoundDialog() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "تغيير صوت المؤذن",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...sounds.map((s) {
                final selected = s.assetPath == selectedSoundAsset;
                return ListTile(
                  leading: Icon(selected ? Icons.volume_up : Icons.music_note),
                  title: Text(s.name),
                  subtitle: Text(s.assetPath.split('/').last),
                  trailing: selected
                      ? const Icon(Icons.check_circle)
                      : const SizedBox(),
                  onTap: () => Navigator.pop(ctx, s.assetPath),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() => selectedSoundAsset = result);
      await _saveString('selectedSoundAsset', result);

      // تشغيل الصوت مباشرة (Preview)
      try {
        await _player.setAsset(result);
        await _player.seek(Duration.zero);
        await _player.play();
      } catch (e) {
        _toast("مشكلة في تشغيل الصوت");
      }
    }
  }

  Future<void> _openPrayerSwitchesPage({
    required String title,
    required String storageKeyPrefix,

  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PrayerSwitchesPage(
          title: title,
          storageKeyPrefix: storageKeyPrefix,
        ),
      ),
    );

    // لو صار تغيير رجّع true للصفحة الرئيسية
    if (changed == true && mounted) {
      setState(() => _changed = true);
    }
  }

  String _slugFromArabic(String city) {
    for (final e in libyaCityCoords.entries) {
      if (e.value.name == city) return e.key;
    }
    return 'tripoli';
  }
  @override
  Widget build(BuildContext context) {
    // عنوان الصفحة = المدينة الحالية (حسب طلبك)
    final appTitle = selectedCity;


    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            // Bottom bar uses pushReplacement, so stack may only have SittingPage.
            // Pop would leave black screen; go to MainScreen instead.
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          }
        },
        child: Scaffold(
      appBar: AppBar(
        title: Text(appTitle),
        centerTitle: true,
        actions: [

        ],
      ),
      bottomNavigationBar: const Rashad(currentIndex: 5),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _SectionCard(
            title: "المدينة",
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("تحديد تلقائي (GPS)"),
                  subtitle: Text(
                    autoLocation
                        ? "مفعّل: يتم تتبع الموقع"
                        : "مقفول: اختر مدينة يدويًا",
                  ),
                  value: autoLocation,
                  onChanged: (v) async {
                    setState(() => autoLocation = v);
                    await _saveBool('autoLocation', v);

                    if (v) {
                      await _enableTrackingLocation();
                    } else {
                      // لو selectedCity مش موجودة في JSON، خليها أول مدينة
                      if (libyaCities.isNotEmpty && !libyaCities.contains(selectedCity)) {
                        setState(() => selectedCity = libyaCities.first);
                        await _saveString('selectedCity', selectedCity);
                      }
                    }
                  },

                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String>(
                    value: libyaCities.contains(selectedCity)
                        ? selectedCity
                        : (libyaCities.isNotEmpty ? libyaCities.first : null),
                    items: libyaCities
                        .map(
                          (c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      ),
                    )
                        .toList(),
                    onChanged: autoLocation
                        ? null
                        : (v) async {
                      if (v == null) return;

                      final slug = _slugFromArabic(v);
                      setState(() => selectedCity = v);
                      _changed = true;

                      await _saveString('city_label', v);
                      await _saveString('city_slug', slug);

                    },

                    decoration: InputDecoration(
                      labelText: "اختيار مدينة",
                      border: const OutlineInputBorder(),
                      enabled: !autoLocation,
                      helperText: autoLocation ? "اقفل GPS عشان تختار مدينة يدويًا" : null,
                    ),
                  ),
                ),

              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: "التنبيهات",
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("تفعيل التنبيهات"),
                  value: notificationsEnabled,
                  onChanged: (v) async {
                    // لو شغّلها: اطلب الإذن أولاً
                    if (v) {
                      final ok = await NotificationService.I.requestPermissions();
                      if (!ok) {
                        if (!mounted) return;
                        setState(() => notificationsEnabled = false);
                        await _saveBool('notificationsEnabled', false);
                        _toast("لازم تسمح بإذن التنبيهات من النظام");
                        return;
                      }
                    }

                    // حدّث سويتش التنبيهات
                    if (!mounted) return;
                    setState(() {
                      notificationsEnabled = v;
                      _changed = true;
                    });
                    await _saveBool('notificationsEnabled', v);

                    // مفاتيح صلوات "عند الأذان"
                    const keys = [
                      'at_adhan_fajr',
                      'at_adhan_dhuhr',
                      'at_adhan_asr',
                      'at_adhan_maghrib',
                      'at_adhan_isha',
                    ];

                    final prefs = await SharedPreferences.getInstance();

                    // Cancel all scheduled prayer notifications (same ID range as main.dart)
                    final pending = await NotificationService.I.getPendingNotifications();
                    for (final p in pending) {
                      if (p.id >= 100 && p.id < 10000) {
                        await NotificationService.I.cancel(p.id);
                      }
                    }

                    if (!v) {
                      // ✅ OFF: اقفل كل الصلوات
                      for (final k in keys) {
                        await prefs.setBool(k, false);
                      }
                      _toast("تم إيقاف كل تنبيهات الصلوات");
                    } else {
                      // ✅ ON: شغّل كل الصلوات
                      for (final k in keys) {
                        await prefs.setBool(k, true);
                      }

                      // ✅ لازم تعيد جدولة الإشعارات من MainScreen بعد الرجوع
                      // (لأن SittingPage ما عندها _scheduleNext30DaysPrayers)
                      _toast("تم تشغيل كل تنبيهات الصلوات");
                    }
                  },


                ),

                ListTile(
                  title: const Text("عند الأذان"),
                  subtitle: const Text("حدد الصلوات التي تريد تنبيهها"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPrayerSwitchesPage(
                    title: "عند الأذان",
                    storageKeyPrefix: "at_adhan",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: "المؤذن",
            child: Column(
              children: [
                ListTile(
                  title: const Text("تغيير صوت المؤذن"),
                  subtitle: Text(_soundNameByAsset(selectedSoundAsset)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: muezzinSoundEnabled ? _pickSoundDialog : null,
                ),
              ],
            ),
          ),
        ],
      ),
     )
    );
  }

  String _soundNameByAsset(String asset) {
    final match = sounds.where((s) => s.assetPath == asset).toList();
    return match.isEmpty ? "غير محدد" : match.first.name;
  }
}

class PrayerSwitchesPage extends StatefulWidget {
  final String title;
  final String storageKeyPrefix;

  const PrayerSwitchesPage({
    super.key,
    required this.title,
    required this.storageKeyPrefix,
  });

  @override
  State<PrayerSwitchesPage> createState() => _PrayerSwitchesPageState();
}

class _PrayerSwitchesPageState extends State<PrayerSwitchesPage> {
  final List<PrayerItem> prayers = const [
    PrayerItem(keyName: "fajr", label: "الفجر"),
    PrayerItem(keyName: "dhuhr", label: "الظهر"),
    PrayerItem(keyName: "asr", label: "العصر"),
    PrayerItem(keyName: "maghrib", label: "المغرب"),
    PrayerItem(keyName: "isha", label: "العشاء"),
  ];
  bool _changed = false; // ✅ هنا الصحيح

  final Map<String, bool> _values = {};

  @override
  void initState() {
    super.initState();
    _loadSwitches();
  }

  String _keyFor(String prayerKey) => "${widget.storageKeyPrefix}_$prayerKey";

  Future<void> _loadSwitches() async {
    final prefs = await SharedPreferences.getInstance();

    final map = <String, bool>{};
    for (final p in prayers) {
      // default = true
      map[p.keyName] = prefs.getBool(_keyFor(p.keyName)) ?? true;
    }

    if (!mounted) return;
    setState(() {
      _values.clear();
      _values.addAll(map);
    });
  }

  Future<void> _setSwitch(String prayerKey, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(prayerKey), value);
    _changed = true;

    // Cancel all scheduled prayer notifications so they stop immediately.
    // When user goes to MainScreen we reschedule only enabled; if app is closed, next open will reschedule.
    final pending = await NotificationService.I.getPendingNotifications();
    for (final p in pending) {
      if (p.id >= 100 && p.id < 10000) {
        await NotificationService.I.cancel(p.id);
      }
    }

    if (!mounted) return;
    setState(() => _values[prayerKey] = value);
  }

  Future<void> _setAll(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    for (final p in prayers) {
      await prefs.setBool(_keyFor(p.keyName), value);
    }

    if (!mounted) return;
    setState(() {
      for (final p in prayers) {
        _values[p.keyName] = value;
        _changed = true;

      }
      _changed = true; // ✅ مرة واحدة فقط

    });
    Navigator.of(context).maybePop(true);

  }

  @override
  @override
  Widget build(BuildContext context) {
    final allOn = prayers.every((p) => _values[p.keyName] ?? true);
    final allOff = prayers.every((p) => !(_values[p.keyName] ?? true));

    return WillPopScope(
      onWillPop: () async {
        // ✅ رجّع للصفحة السابقة هل صار تغيير ولا لا
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          automaticallyImplyLeading: false,

          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _changed); // ✅ نفس الفكرة
            },
          ),
          actions: [
            IconButton(
              tooltip: "تشغيل الكل",
              onPressed: allOn ? null : () => _setAll(true),
              icon: const Icon(Icons.done_all),
            ),
            IconButton(
              tooltip: "إيقاف الكل",
              onPressed: allOff ? null : () => _setAll(false),
              icon: const Icon(Icons.remove_done),
            ),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: prayers.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = prayers[i];
            final v = _values[p.keyName] ?? true;

            return SwitchListTile(
              title: Text(p.label),
              subtitle: Text(
                widget.storageKeyPrefix == "before_adhan"
                    ? "تنبيه قبل الأذان"
                    : "تنبيه عند الأذان",
              ),
              value: v,
              onChanged: (nv) => _setSwitch(p.keyName, nv),
            );
          },
        ),
      ),
    );
  }
}

// ---------- Helper models & widgets ----------

class PrayerItem {
  final String keyName;
  final String label;
  const PrayerItem({required this.keyName, required this.label});
}

class MuezzinSound {
  final String name;
  final String assetPath;
  const MuezzinSound({required this.name, required this.assetPath});
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class CityCoord {
  final String name;
  final double lat;
  final double lng;

  const CityCoord(this.name, this.lat, this.lng);
}

const Map<String, CityCoord> libyaCityCoords = {
  'tripoli': CityCoord('طرابلس', 32.8872, 13.1913),
  'benghazi': CityCoord('بنغازي', 32.1167, 20.0667),
  'misrata': CityCoord('مصراتة', 32.3754, 15.0920),
  'ajdabiya': CityCoord('اجدابيا', 30.7555, 20.2263),
  'sabha': CityCoord('سبها', 27.0377, 14.4283),
  'tobruk': CityCoord('طبرق', 32.0767, 23.9601),
  'derna': CityCoord('درنة', 32.7640, 22.6390),
  'zawiya': CityCoord('الزاوية', 32.7571, 12.7276),
  'zliten': CityCoord('زليتن', 32.4674, 14.5687),
  'khoms': CityCoord('الخمس', 32.6486, 14.2619),

  'bani-walid': CityCoord('بني وليد', 31.7560, 13.9900),
  'sirte': CityCoord('سرت', 31.2060, 16.5880),
  'zuwara': CityCoord('زوارة', 32.9312, 12.0819),
  'zuwetina': CityCoord('الزويتينة', 30.9522, 20.1200),
  'bayda': CityCoord('البيضاء', 32.7627, 21.7551),
  'ras-lanuf': CityCoord('رأس لانوف', 30.5000, 18.5000),
  'tajura': CityCoord('تاجوراء', 32.8817, 13.3500),
  'sabratha': CityCoord('صبراتة', 32.8070, 12.4850),
  'gharyan': CityCoord('غريان', 32.1722, 13.0203),
  'zintan': CityCoord('الزنتان', 31.9316, 12.2529),
  'nalut': CityCoord('نالوت', 31.8687, 10.9810),
  'kufra': CityCoord('الكفرة', 24.1997, 23.2905),
  'murzuq': CityCoord('مرزق', 25.9155, 13.9184),
  'ubari': CityCoord('أوباري', 26.5903, 12.7751),
  'ghat': CityCoord('غات', 25.1333, 10.1667),
  'hun': CityCoord('هون', 29.1268, 15.9477),
  'waddan': CityCoord('ودان', 29.1614, 16.1390),
  'masallatah': CityCoord('مسلاتة', 32.6150, 14.0000),
  'tarhuna': CityCoord('ترهونة', 32.4350, 13.6330),
  'ajaylat': CityCoord('العجيلات', 32.7570, 12.3760),
  'surman': CityCoord('صرمان', 32.7550, 12.5710),
  'zaltan': CityCoord('زلطن', 32.9460, 11.8660),
  'suluq': CityCoord('سلوق', 31.6682, 20.2520),
};
