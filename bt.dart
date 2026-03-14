import 'package:flutter/material.dart';
import 'package:ltt_ramadan_emskia/qran.dart';
import 'package:ltt_ramadan_emskia/qibla.dart';
import 'package:ltt_ramadan_emskia/sitting.dart';
import 'adkar.dart';
import 'main.dart';
import 'cal.dart';

class Rashad extends StatelessWidget {
  final int currentIndex;

  const Rashad({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CalPage()),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QuranIndexPage()),
        );
        break;

      case 3:
      // صفحة الإعدادات (أضفها لاحقًا)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdkarPage()),);
        break;


      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QiblaPage()),
        );
        break;

      case 5:
      // صفحة الإعدادات (أضفها لاحقًا)
       Navigator.pushReplacement(
        context,
      MaterialPageRoute(builder: (_) => const SittingPage()),);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex, // ⭐ يحدد الأيقونة الزرقاء
      onTap: (index) => _onTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'التقويم',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'المصحف',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pages),
          label: 'الأذكار',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions),
          label: 'القبلة',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'الإعدادات',
        ),
      ],
      selectedItemColor: Color(0xFF2196F3),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
    );
  }
}
