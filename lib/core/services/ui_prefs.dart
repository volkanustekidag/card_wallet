import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Small, non-sensitive UI preferences kept in the plain `app_state` box
/// (same box as the onboarding flag): Up Next on/off, when the last backup
/// was made, and what the user said they carry during onboarding.
class UiPrefs {
  UiPrefs._();
  static final UiPrefs instance = UiPrefs._();

  static const _box = 'app_state';
  static const _kUpNext = 'up_next_enabled';
  static const _kLastBackup = 'last_backup_at';
  static const _kCarry = 'carry_kinds';

  final RxBool upNext = true.obs;
  final Rxn<DateTime> lastBackup = Rxn<DateTime>();
  final RxList<String> carry = <String>[].obs;

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

  Future<void> setCarry(List<String> kinds) async {
    carry.assignAll(kinds);
    try {
      await (await _open()).put(_kCarry, kinds);
    } catch (_) {}
  }
}
