/// Maps an IBAN's country prefix to its primary currency code (ISO 4217).
/// Used so QR generation defaults to the right currency without users
/// having to type it. Falls back to 'EUR' for unknown prefixes — that's the
/// currency the EPC SEPA QR standard expects anyway.
String currencyForIban(String iban) {
  if (iban.length < 2) return 'EUR';
  final cc = iban.substring(0, 2).toUpperCase();
  return _ibanCurrencies[cc] ?? 'EUR';
}

const Map<String, String> _ibanCurrencies = {
  // SEPA / EUR
  'AD': 'EUR', 'AT': 'EUR', 'BE': 'EUR', 'CY': 'EUR', 'DE': 'EUR',
  'EE': 'EUR', 'ES': 'EUR', 'FI': 'EUR', 'FR': 'EUR', 'GR': 'EUR',
  'IE': 'EUR', 'IT': 'EUR', 'LT': 'EUR', 'LU': 'EUR', 'LV': 'EUR',
  'MC': 'EUR', 'ME': 'EUR', 'MT': 'EUR', 'NL': 'EUR', 'PT': 'EUR',
  'SI': 'EUR', 'SK': 'EUR', 'SM': 'EUR', 'VA': 'EUR', 'XK': 'EUR',

  // Other Europe
  'BG': 'BGN', 'CH': 'CHF', 'CZ': 'CZK', 'DK': 'DKK', 'GB': 'GBP',
  'HR': 'EUR', // adopted EUR in 2023
  'HU': 'HUF', 'IS': 'ISK', 'LI': 'CHF', 'NO': 'NOK', 'PL': 'PLN',
  'RO': 'RON', 'RS': 'RSD', 'SE': 'SEK', 'AL': 'ALL', 'BA': 'BAM',
  'MD': 'MDL', 'MK': 'MKD', 'UA': 'UAH', 'BY': 'BYN', 'GE': 'GEL',

  // Middle East / Africa
  'AE': 'AED', 'BH': 'BHD', 'EG': 'EGP', 'IL': 'ILS', 'IQ': 'IQD',
  'JO': 'JOD', 'KW': 'KWD', 'LB': 'LBP', 'MR': 'MRU', 'PK': 'PKR',
  'PS': 'ILS', 'QA': 'QAR', 'SA': 'SAR', 'TN': 'TND', 'TR': 'TRY',

  // Asia
  'AZ': 'AZN', 'KZ': 'KZT', 'TL': 'USD',

  // Americas / Caribbean
  'BR': 'BRL', 'CR': 'CRC', 'DO': 'DOP', 'GT': 'GTQ', 'LC': 'XCD',
  'SV': 'USD', 'VG': 'USD',

  // Indian Ocean / Africa
  'MU': 'MUR', 'SC': 'SCR',

  // Other
  'GI': 'GIP', 'FO': 'DKK', 'GL': 'DKK', 'ST': 'STN',
};
