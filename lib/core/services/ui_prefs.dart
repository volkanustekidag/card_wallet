import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Small, non-sensitive UI preferences kept in the plain `app_state` box
/// (same box as the onboarding flag): Up Next on/off, when the last backup
/// was made, what the user said they carry during onboarding and whether
/// new bank cards start with their expiry reminder on.
class UiPrefs {
  UiPrefs._();
  static final UiPrefs instance = UiPrefs._();

  static const _box = 'app_state';
  static const _kUpNext = 'up_next_enabled';
  static const _kLastBackup = 'last_backup_at';
  static const _kCarry = 'carry_kinds';
  static const _kRemindDefault = 'remind_by_default';
  static const _kHomeGrid = 'home_grid';
  static const _kBrandCountry = 'brand_country';
  static const _kViewHintSeen = 'view_hint_seen';
  static const _kHomeSort = 'home_sort';
  static const _kManualOrder = 'manual_order';

  final RxBool upNext = true.obs;
  final Rxn<DateTime> lastBackup = Rxn<DateTime>();
  final RxList<String> carry = <String>[].obs;
  final RxBool remindByDefault = false.obs;
  final RxBool homeGrid = false.obs;

  /// Home order: `smart`, `name` or `manual` (see HomeSort).
  final RxString homeSort = 'smart'.obs;

  /// Hero tags of the cards in the user's own order (manual sort).
  final RxList<String> manualOrder = <String>[].obs;

  /// Country picked in the brand picker; null follows the phone.
  final Rxn<String> brandCountry = Rxn<String>();

  /// The one-time "stack or grid" hint on Home was shown and dismissed.
  final RxBool viewHintSeen = false.obs;

  Future<Box<dynamic>> _open() async {
    if (Hive.isBoxOpen(_box)) return Hive.box<dynamic>(_box);
    return Hive.openBox<dynamic>(_box);
  }

  Future<void> load() async {
    try {
      final b = await _open();
      upNext.value = b.get(_kUpNext, defaultValue: true) == true;
      final ms = b.get(_kLastBackup);
      lastBackup.value =
          ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
      final kinds = b.get(_kCarry);
      carry.assignAll(kinds is List ? kinds.cast<String>() : const []);
      remindByDefault.value = b.get(_kRemindDefault) == true;
      homeGrid.value = b.get(_kHomeGrid) == true;
      final sort = b.get(_kHomeSort);
      homeSort.value = sort is String ? sort : 'smart';
      final order = b.get(_kManualOrder);
      manualOrder.assignAll(order is List ? order.cast<String>() : const []);
      viewHintSeen.value = b.get(_kViewHintSeen) == true;
      final bc = b.get(_kBrandCountry);
      brandCountry.value = bc is String && bc.isNotEmpty ? bc : null;
    } catch (_) {
      // Defaults stand; nothing here is critical.
    }
  }

  Future<void> setUpNext(bool v) async {
    upNext.value = v;
    try {
      await (await _open()).put(_kUpNext, v);
    } catch (_) {}
  }

  Future<void> markBackup([DateTime? at]) async {
    final t = at ?? DateTime.now();
    lastBackup.value = t;
    try {
      await (await _open()).put(_kLastBackup, t.millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> setRemindByDefault(bool v) async {
    remindByDefault.value = v;
    try {
      await (await _open()).put(_kRemindDefault, v);
    } catch (_) {}
  }

  Future<void> setHomeGrid(bool v) async {
    homeGrid.value = v;
    try {
      await (await _open()).put(_kHomeGrid, v);
    } catch (_) {}
  }

  Future<void> setHomeSort(String sort) async {
    homeSort.value = sort;
    try {
      await (await _open()).put(_kHomeSort, sort);
    } catch (_) {}
  }

  Future<void> setManualOrder(List<String> heroTags) async {
    manualOrder.assignAll(heroTags);
    try {
      await (await _open()).put(_kManualOrder, heroTags);
    } catch (_) {}
  }

  Future<void> markViewHintSeen() async {
    if (viewHintSeen.value) return;
    viewHintSeen.value = true;
    try {
      await (await _open()).put(_kViewHintSeen, true);
    } catch (_) {}
  }

  Future<void> setBrandCountry(String? code) async {
    brandCountry.value = code;
    try {
      final b = await _open();
      code == null
          ? await b.delete(_kBrandCountry)
          : await b.put(_kBrandCountry, code);
    } catch (_) {}
  }

  Future<void> setCarry(List<String> kinds) async {
    carry.assignAll(kinds);
    try {
      await (await _open()).put(_kCarry, kinds);
    } catch (_) {}
  }
}
