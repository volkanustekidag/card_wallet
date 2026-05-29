/// Supported barcode formats. Names match `google_mlkit_barcode_scanning`'s
/// BarcodeFormat enum so that scanned values from a future scanner can be
/// stored verbatim.
class LoyaltyBarcodeFormat {
  final String code;
  final String label;
  const LoyaltyBarcodeFormat(this.code, this.label);
}

const List<LoyaltyBarcodeFormat> kLoyaltyBarcodeFormats = [
  LoyaltyBarcodeFormat('CODE_128', 'Code 128'),
  LoyaltyBarcodeFormat('CODE_39', 'Code 39'),
  LoyaltyBarcodeFormat('EAN_13', 'EAN-13'),
  LoyaltyBarcodeFormat('EAN_8', 'EAN-8'),
  LoyaltyBarcodeFormat('UPC_A', 'UPC-A'),
  LoyaltyBarcodeFormat('UPC_E', 'UPC-E'),
  LoyaltyBarcodeFormat('QR_CODE', 'QR Code'),
  LoyaltyBarcodeFormat('ITF', 'ITF'),
];

/// Formats that only accept numeric digits. EAN/UPC/ITF are positional
/// digit codes; CODE_128/CODE_39/QR_CODE accept arbitrary characters.
const Set<String> kDigitOnlyBarcodeFormats = {
  'EAN_13',
  'EAN_8',
  'UPC_A',
  'UPC_E',
  'ITF',
};

bool isDigitOnlyBarcodeFormat(String format) =>
    kDigitOnlyBarcodeFormats.contains(format);
