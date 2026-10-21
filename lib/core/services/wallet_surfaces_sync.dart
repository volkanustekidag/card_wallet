import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/services/watch_sync_service.dart';
import 'package:wallet_app/core/services/widget_data_service.dart';

/// Keeps every surface outside the app — the home/lock-screen widget, the
/// Android quick tile and the Apple Watch — in step with the loyalty box.
///
/// Listens to the Hive box directly, so any add / edit / delete / restore /
/// wipe (from any screen) reaches the widget and the watch. Before this the
/// watch only synced when the loyalty list page was opened.
class WalletSurfacesSync {
  WalletSurfacesSync({
    Future<List<LoyaltyCard>> Function()? loadCards,
    Future<Stream<Object?>> Function()? watchChanges,
    Future<void> Function(List<LoyaltyCard> cards)? reconcileWidget,
    Future<void> Function()? clearWidget,
    void Function(List<LoyaltyCard> cards)? scheduleWatchSync,
    Future<void> Function(List<LoyaltyCard> cards)? pushWatchNow,
    this.debounce = const Duration(milliseconds: 300),
  })  : _loadCards = loadCards ?? _defaultLoad,
        _watchChanges = watchChanges ?? (() => LoyaltyCardService().watch()),
        _reconcileWidget =
            reconcileWidget ?? WidgetDataService.instance.reconcile,
        _clearWidget =
            clearWidget ?? WidgetDataService.instance.clearLastUsedLoyaltyCard,
        _scheduleWatchSync =
            scheduleWatchSync ?? WatchSyncService.instance.scheduleSync,
        _pushWatchNow = pushWatchNow ??
            ((cards) => WatchSyncService.instance.pushAllCards(cards));

  static final WalletSurfacesSync instance = WalletSurfacesSync();

  final Duration debounce;
  final Future<List<LoyaltyCard>> Function() _loadCards;
  final Future<Stream<Object?>> Function() _watchChanges;
  final Future<void> Function(List<LoyaltyCard> cards) _reconcileWidget;
  final Future<void> Function() _clearWidget;
  final void Function(List<LoyaltyCard> cards) _scheduleWatchSync;
  final Future<void> Function(List<LoyaltyCard> cards) _pushWatchNow;

  StreamSubscription<Object?>? _subscription;
  Timer? _debounceTimer;

  static Future<List<LoyaltyCard>> _defaultLoad() async {
    final service = LoyaltyCardService();
    await service.openBox();
    return service.getAllLoyaltyCards();
  }

  /// Syncs once and starts following the loyalty box. Safe to call again.
  Future<void> start() async {
    if (_subscription == null) {
      try {
        final changes = await _watchChanges();
        _subscription = changes.listen((_) => _scheduleSync());
      } catch (e, st) {
        ErrorReporter.report(e, st, reason: 'WalletSurfacesSync.watch');
      }
    }
    await syncNow();
  }

  /// Pushes the current loyalty list to the widget and the watch right away
  /// (e.g. after a backup restore).
  Future<void> syncNow() async {
    _debounceTimer?.cancel();
    try {
      final cards = await _loadCards();
      await _reconcileWidget(cards);
      _scheduleWatchSync(cards);
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'WalletSurfacesSync.sync');
    }
  }

  /// Empties the widget and the watch immediately ("Delete all data").
  Future<void> clearAll() async {
    _debounceTimer?.cancel();
    try {
      await _clearWidget();
      await _pushWatchNow(const []);
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'WalletSurfacesSync.clear');
    }
  }

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(syncNow()));
  }

  @visibleForTesting
  Future<void> stop() async {
    _debounceTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
  }
}
