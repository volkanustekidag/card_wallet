import 'package:hive/hive.dart';

part 'verification.g.dart';

@HiveType(typeId: 1)
class Verification extends HiveObject {
  /// In v1.x this stored the PIN in plaintext. From v2.x onward this stores
  /// the base64 PBKDF2-HMAC-SHA256 hash of the PIN. [salt] is non-null and
  /// [isLegacyPin] is false for hashed records.
  @HiveField(0)
  String password;

  @HiveField(1)
  String? salt;

  @HiveField(2, defaultValue: true)
  bool isLegacyPin;

  Verification(
    this.password, {
    this.salt,
    this.isLegacyPin = true,
  });
}
