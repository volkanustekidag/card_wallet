import 'package:hive/hive.dart';

part 'loyalty_card.g.dart';

/// A scannable loyalty / membership card. Holds enough metadata to render a
/// readable card preview and to redraw the original barcode at the cashier.
@HiveType(typeId: 4)
class LoyaltyCard extends HiveObject {
  @HiveField(0)
  late String id;

  /// User-facing card name (e.g. "Starbucks Rewards").
  @HiveField(1)
  late String name;

  /// Brand / merchant (e.g. "Starbucks"). May match a known preset for logo
  /// + colour, otherwise treated as a free-form string.
  @HiveField(2)
  String? brand;

  /// Raw barcode value as scanned. Format-specific.
  @HiveField(3)
  late String barcode;

  /// One of `EAN_13`, `EAN_8`, `UPC_A`, `UPC_E`, `CODE_128`, `CODE_39`,
  /// `QR_CODE`, `OTHER`. Mirrors `BarcodeFormat` from `google_mlkit`.
  @HiveField(4)
  late String barcodeFormat;

  /// Index into [LinearGradients] for the rendered card colour.
  @HiveField(5)
  late int colorId;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime? createdAt;

  /// Optional bundled asset path for the brand logo.
  @HiveField(8)
  String? logoAsset;

  /// Free-form tags. The literal `'favorite'` is treated specially
  /// throughout the app to drive starring / the Favorites filter.
  @HiveField(9)
  List<String>? tags;

  LoyaltyCard({
    required this.id,
    required this.name,
    this.brand,
    required this.barcode,
    required this.barcodeFormat,
    required this.colorId,
    this.notes,
    this.createdAt,
    this.logoAsset,
    this.tags,
  });
}
