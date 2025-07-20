import 'package:hive/hive.dart';

part 'verification.g.dart';

@HiveType(typeId: 1)
class Verification extends HiveObject {
  @HiveField(0)
  final String password;

  Verification(this.password);
}
