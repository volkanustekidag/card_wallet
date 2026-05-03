import 'dart:io';
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/utils/card_reminder_rules.dart';

class CardReminderService {
  CardReminderService._internal();
  static final CardReminderService _instance = CardReminderService._internal();
  factory CardReminderService() => _instance;

  static const String _channelId = 'card_wallet_reminders';
  static const String _channelName = 'Card reminders';
  static const String _channelDescription =
      'Credit card expiry and payment date reminders';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<CardReminderPayload> _payloadController =
      StreamController<CardReminderPayload>.broadcast();

  Future<void>? _initFuture;
  CardReminderPayload? _pendingPayload;

  Stream<CardReminderPayload> get reminderPayloads => _payloadController.stream;

  CardReminderPayload? takePendingPayload() {
    final payload = _pendingPayload;
    _pendingPayload = null;
    return payload;
  }

  Future<void> init() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  Future<void> scheduleForCard(
    CreditCard card, {
    bool promptForPermissions = true,
  }) async {
    await init();
    await cancelForCard(card);

    if (!_hasEnabledReminder(card)) {
      return;
    }

    final allowed =
        await _notificationsAllowed(promptForPermissions: promptForPermissions);
    if (!allowed) {
      return;
    }

    if (card.expiryReminderEnabled) {
      await _scheduleExpiryReminder(card);
    }

    if (card.paymentReminderEnabled && card.paymentDueDay != null) {
      await _schedulePaymentReminders(card);
    }
  }

  Future<void> scheduleAllCreditCardReminders(
    List<CreditCard> cards, {
    bool promptForPermissions = false,
  }) async {
    await init();

    if (!cards.any(_hasEnabledReminder)) {
      await cancelAllForCards(cards);
      return;
    }

    final allowed =
        await _notificationsAllowed(promptForPermissions: promptForPermissions);
    for (final card in cards) {
      await cancelForCard(card);
      if (!allowed || !_hasEnabledReminder(card)) {
        continue;
      }
      if (card.expiryReminderEnabled) {
        await _scheduleExpiryReminder(card);
      }
      if (card.paymentReminderEnabled && card.paymentDueDay != null) {
        await _schedulePaymentReminders(card);
      }
    }
  }

  Future<void> cancelForCard(CreditCard card) async {
    await init();
    await _notifications.cancel(_notificationId(card, 'expiry'));
    for (var slot = 0; slot < CardReminderRules.paymentScheduleSlots; slot++) {
      await _notifications.cancel(_notificationId(card, 'payment-$slot'));
    }
  }

  Future<void> cancelAllForCards(List<CreditCard> cards) async {
    await init();
    for (final card in cards) {
      await cancelForCard(card);
    }
  }

  Future<void> _initialize() async {
    await _configureLocalTimeZone();

    const androidSettings =
        AndroidInitializationSettings('ic_stat_card_wallet');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _rememberPayload(launchDetails?.notificationResponse?.payload);
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _rememberPayload(response.payload);
  }

  void _rememberPayload(String? rawPayload) {
    final payload = CardReminderPayload.tryParse(rawPayload);
    if (payload == null) return;
    _pendingPayload = payload;
    _payloadController.add(payload);
  }

  Future<bool> _notificationsAllowed({
    required bool promptForPermissions,
  }) async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await androidPlugin?.areNotificationsEnabled();
      if (enabled == true) return true;
      if (!promptForPermissions) return false;
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    }

    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final permissions = await iosPlugin?.checkPermissions();
      if (permissions?.isEnabled == true) return true;
      if (!promptForPermissions) return false;
      return await iosPlugin?.requestPermissions(
            alert: true,
            sound: true,
          ) ??
          false;
    }

    if (Platform.isMacOS) {
      final macPlugin = _notifications.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final permissions = await macPlugin?.checkPermissions();
      if (permissions?.isEnabled == true) return true;
      if (!promptForPermissions) return false;
      return await macPlugin?.requestPermissions(
            alert: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || Platform.isLinux) {
      return;
    }

    tz_data.initializeTimeZones();
    if (Platform.isWindows) {
      return;
    }

    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (error) {
      debugPrint('Unable to resolve local timezone: $error');
    }
  }

  Future<void> _scheduleExpiryReminder(CreditCard card) async {
    final expiryDate = CardReminderRules.parseExpiryDate(card.expirationDate);
    if (expiryDate == null) return;
    final reminderAt = CardReminderRules.expiryReminderDate(card);
    if (reminderAt == null) return;

    if (!reminderAt.isAfter(DateTime.now())) {
      return;
    }

    await _schedule(
      id: _notificationId(card, 'expiry'),
      title: 'cardExpiryReminderTitle'.tr(),
      body: 'cardExpiryReminderBody'.tr(
        namedArgs: {
          'card': _cardDisplayName(card),
          'date': DateFormat.yMMMd().format(expiryDate),
        },
      ),
      scheduledAt: reminderAt,
      payload: 'credit-card:${card.id}:expiry',
    );
  }

  Future<void> _schedulePaymentReminders(CreditCard card) async {
    final now = DateTime.now();
    final reminderDates =
        CardReminderRules.paymentReminderDates(card, now: now);
    for (var i = 0; i < reminderDates.length; i++) {
      final reminderAt = reminderDates[i];
      final dueDate = reminderAt.add(
        Duration(
          days: CardReminderRules.safeDaysBefore(
            card.paymentReminderDaysBefore,
          ),
        ),
      );
      await _schedule(
        id: _notificationId(card, 'payment-$i'),
        title: 'cardPaymentReminderTitle'.tr(),
        body: 'cardPaymentReminderBody'.tr(
          namedArgs: {
            'card': _cardDisplayName(card),
            'date': DateFormat.yMMMd().format(dueDate),
          },
        ),
        scheduledAt: reminderAt,
        payload: 'credit-card:${card.id}:payment',
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) {
    return _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  bool _hasEnabledReminder(CreditCard card) {
    return card.expiryReminderEnabled ||
        (card.paymentReminderEnabled && card.paymentDueDay != null);
  }

  String _cardDisplayName(CreditCard card) {
    final bankName = card.bankName.trim();
    if (bankName.isNotEmpty) return bankName;

    final digits = card.creditCardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      return '•••• ${digits.substring(digits.length - 4)}';
    }
    return 'creditCard'.tr();
  }

  int _notificationId(CreditCard card, String purpose) {
    var hash = 0x811c9dc5;
    final input = '${card.id}|${card.creditCardNumber}|$purpose';
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

enum CardReminderKind { expiry, payment }

class CardReminderPayload {
  final String cardId;
  final CardReminderKind kind;

  const CardReminderPayload({
    required this.cardId,
    required this.kind,
  });

  static CardReminderPayload? tryParse(String? payload) {
    if (payload == null) return null;
    final parts = payload.split(':');
    if (parts.length != 3 || parts[0] != 'credit-card') return null;

    final kind = switch (parts[2]) {
      'expiry' => CardReminderKind.expiry,
      'payment' => CardReminderKind.payment,
      _ => null,
    };
    if (kind == null || parts[1].isEmpty) return null;

    return CardReminderPayload(cardId: parts[1], kind: kind);
  }
}
