import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

import 'bt.dart'; // فيها Rashad bottom bar

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  Position? _pos;
  double? _heading; // device heading degrees (0 = North)
  double? _qiblaBearing; // bearing to Kaaba degrees (0 = North)

  StreamSubscription<CompassEvent>? _compassSub;

  bool _loading = true;
  String _status = "جاري تحديد الموقع...";

  static const double _kaabaLat = 21.422487;
  static const double _kaabaLng = 39.826206;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _status = "جاري تحديد الموقع...";
    });

    final ok = await _ensureLocationPermission();
    if (!ok) {
      setState(() {
        _loading = false;
        _status = "لا يمكن تحديد الموقع (إذن الموقع مرفوض)";
      });
      return;
    }

    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final bearing = _bearingToKaaba(p.latitude, p.longitude);

      setState(() {
        _pos = p;
        _qiblaBearing = bearing;
        _status = "حرّك هاتفك ببطء لمعايرة البوصلة";
      });

      _listenCompass();

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _status = "تعذر تحديد الموقع";
      });
    }
  }

  void _listenCompass() {
    _compassSub?.cancel();

    _compassSub = FlutterCompass.events?.listen((event) {
      final h = event.heading; // degrees
      if (h == null) return;
      setState(() => _heading = h);
    });
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  // حساب اتجاه القبلة (bearing) من الموقع إلى الكعبة
  double _bearingToKaaba(double lat, double lng) {
    final lat1 = _degToRad(lat);
    final lon1 = _degToRad(lng);
    final lat2 = _degToRad(_kaabaLat);
    final lon2 = _degToRad(_kaabaLng);

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var brng = math.atan2(y, x);
    brng = _radToDeg(brng);
    brng = (brng + 360) % 360; // normalize 0..360
    return brng;
  }

  double _degToRad(double d) => d * math.pi / 180.0;
  double _radToDeg(double r) => r * 180.0 / math.pi;

  @override
  Widget build(BuildContext context) {
    final bearing = _qiblaBearing;
    final heading = _heading;

    // زاوية دوران السهم = اتجاه القبلة - اتجاه الجهاز
    final bool compassAvailable = heading != null && heading != 0;

    final double? turnDeg =
    (bearing != null && compassAvailable) ? (bearing - heading) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("تحديد القبلة"),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black26,
        actions: [
          IconButton(
            tooltip: "تحديث",
            onPressed: _init,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: const Rashad(currentIndex: 4),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 8,
              shadowColor: Colors.blueGrey.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "اتجاه القبلة",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // دائرة البوصلة + سهم القبلة
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.blueGrey.shade200),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                            color: Colors.black.withOpacity(0.10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _loading
                            ? const CircularProgressIndicator()
                            : (turnDeg == null)
                            ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.explore,
                              size: 46,
                              color: Colors.blueGrey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "البوصلة غير متاحة",
                              style: TextStyle(
                                color: Colors.blueGrey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "جرّب تشغيل المستشعرات\nأو أعد تشغيل الهاتف",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                          ],
                        )
                            : Transform.rotate(
                          angle: _degToRad(turnDeg),
                          child: const Icon(
                            Icons.navigation,
                            size: 90,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ),

                    // ✅ الإضافة المطلوبة: لما البوصلة غير مدعومة لكن عندنا bearing
                    const SizedBox(height: 12),
                    if (!compassAvailable && bearing != null)
                      Text(
                        "📍 اتجاه القبلة: ${bearing!.toStringAsFixed(0)}° من الشمال\n(هاتفك لا يدعم البوصلة)",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueGrey.shade800,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),

                    const SizedBox(height: 18),

                    // معلومات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoChip(
                          icon: Icons.my_location,
                          label: _pos == null
                              ? "—"
                              : "${_pos!.latitude.toStringAsFixed(4)}, ${_pos!.longitude.toStringAsFixed(4)}",
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),




                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // زر اختياري لفتح إعدادات الموقع
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF2196F3)),
                title: const Text("إعدادات الموقع"),
                subtitle: const Text(""),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Geolocator.openLocationSettings(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D47A1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2196F3)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
