import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Called when user taps a notification (e.g. to open app).
typedef OnNotificationTap = void Function(int? id, String? payload);

class NotificationService {
  NotificationService._();
  static final NotificationService I = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Android 8+: notification sound is set on the channel. We use raw resources (res/raw).
  /// _v3: use AudioAttributesUsage.alarm so Android 12+ does NOT "Mute recently noisy" (sound will play when app open/closed/foreground).
  static const String kAdhanChannelName = 'أذان الصلاة';
  static const String _kChannelIdPrefix = 'adhan_channel_sound_v3_';

  Future<void> init({OnNotificationTap? onNotificationTap}) async {
    debugPrint("[Adhan] NotificationService.init() started");
    // timezone
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Tripoli'));
    debugPrint("[Adhan] Timezone set to Africa/Tripoli");

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        debugPrint("[Adhan] onDidReceiveNotificationResponse: id=${r.id}, payload=${r.payload}, actionId=${r.actionId}");
        if (r.id != null) {
          onNotificationTap?.call(r.id, r.payload);
        }
      },
    );
    debugPrint("[Adhan] Plugin initialized; tap callback ${onNotificationTap != null ? "set" : "not set"}");

    // channels (Android)
    await _ensureAdhanChannel(soundRawNameAndroid: 'adhan_duqali');
    debugPrint("[Adhan] init() completed");
  }

  String _channelIdForSound(String soundRawNameAndroid) =>
      '$_kChannelIdPrefix$soundRawNameAndroid';

  Future<void> _ensureAdhanChannel({required String soundRawNameAndroid}) async {
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) {
      debugPrint("[Adhan] _ensureAdhanChannel: not Android, skip");
      return;
    }

    final channelId = _channelIdForSound(soundRawNameAndroid);
    debugPrint("[Adhan] _ensureAdhanChannel: channelId=$channelId, soundRawName=$soundRawNameAndroid, audioAttributesUsage=alarm (avoids 'Muting recently noisy')");
    final channel = AndroidNotificationChannel(
      channelId,
      kAdhanChannelName,
      description: 'Notifications for prayer times',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundRawNameAndroid),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await androidImpl.createNotificationChannel(channel);
    debugPrint("[Adhan] Channel created: playSound=true, sound=$soundRawNameAndroid, audioAttributesUsage=alarm");
  }

  Future<bool> requestPermissions() async {
    // iOS
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+ فقط (Android 10 عادة ترجع true)
    final android = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return (ios ?? true) && (android ?? true);
  }

  Future<void> cancelAll() async {
    debugPrint("[Adhan] cancelAll()");
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    debugPrint("[Adhan] cancel(id=$id)");
    await _plugin.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() =>
      _plugin.pendingNotificationRequests();

  // ---------- DETAILS ----------

  AndroidNotificationDetails _adhanAndroidDetails({
    required bool soundEnabled,
    String soundRawNameAndroid = 'adhan_duqali',
  }) {
    return AndroidNotificationDetails(
      _channelIdForSound(soundRawNameAndroid),
      kAdhanChannelName,
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      sound: soundEnabled ? RawResourceAndroidNotificationSound(soundRawNameAndroid) : null,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: false,
      autoCancel: true,
      enableVibration: true,
      enableLights: true,
    );
  }

  DarwinNotificationDetails _iosDetails({
    required bool soundEnabled,
    required String soundFileName,
  }) {
    return DarwinNotificationDetails(
      presentSound: soundEnabled,
      sound: soundEnabled ? soundFileName : null,
      presentAlert: true,
      presentBadge: true,
    );
  }

  // ---------- IMMEDIATE (TEST) ----------

  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
    bool soundEnabled = true,
    String soundRawNameAndroid = 'adhan_duqali',
    String soundFileIOS = 'adhan.aiff',
  }) async {
    debugPrint("[Adhan] showImmediate: id=$id, soundEnabled=$soundEnabled, soundRawNameAndroid=$soundRawNameAndroid");
    if (soundEnabled) {
      await _ensureAdhanChannel(soundRawNameAndroid: soundRawNameAndroid);
    }
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: _adhanAndroidDetails(
          soundEnabled: soundEnabled,
          soundRawNameAndroid: soundRawNameAndroid,
        ),
        iOS: _iosDetails(
          soundEnabled: soundEnabled,
          soundFileName: soundFileIOS,
        ),
      ),
    );
    debugPrint("[Adhan] showImmediate: notification shown (sound=$soundEnabled). If no sound: check res/raw/$soundRawNameAndroid.mp3 exists on device.)");
  }

  // ---------- SCHEDULE ONE ----------

  Future<void> scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    bool soundEnabled = true,
    String soundRawNameAndroid = 'adhan_duqali',
    String soundFileIOS = 'adhan.aiff',
  }) async {
    debugPrint("[Adhan] scheduleOne: id=$id, when=$dateTime, soundEnabled=$soundEnabled, soundRaw=$soundRawNameAndroid");
    if (soundEnabled) {
      await _ensureAdhanChannel(soundRawNameAndroid: soundRawNameAndroid);
    }
    final loc = tz.getLocation('Africa/Tripoli');

    final when = tz.TZDateTime(
      loc,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      0,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdForSound(soundRawNameAndroid),
          kAdhanChannelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: soundEnabled,
          sound: soundEnabled ? RawResourceAndroidNotificationSound(soundRawNameAndroid) : null,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: soundEnabled,
          sound: soundEnabled ? soundFileIOS : null,
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint("[Adhan] scheduleOne: scheduled id=$id for $when (sound=$soundEnabled)");
  }

}
