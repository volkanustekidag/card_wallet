/// Where the user shops, for ranking local loyalty brands first.
///
/// The phone's language says little (plenty of people in Rome run their
/// phone in English); its time zone says where they are. Zones map to
/// ISO 3166 country codes, lower case. Zones shared by several countries
/// map to the largest one.
String? countryForTimezone(String? zone) {
  if (zone == null || zone.isEmpty) return null;
  final direct = _zones[zone];
  if (direct != null) return direct;
  // Families with many sub-zones.
  if (zone.startsWith('America/Indiana/') ||
      zone.startsWith('America/Kentucky/') ||
      zone.startsWith('America/North_Dakota/')) {
    return 'us';
  }
  if (zone.startsWith('America/Argentina/')) return 'ar';
  if (zone.startsWith('Australia/')) return 'au';
  if (zone.startsWith('Canada/')) return 'ca';
  if (zone.startsWith('US/')) return 'us';
  if (zone.startsWith('Brazil/')) return 'br';
  return null;
}

/// ISO code the catalogue uses for [code]: lower case, and the UK as `gb`
/// whichever spelling comes in.
String? normalizeCountry(String? code) {
  if (code == null || code.isEmpty) return null;
  final c = code.toLowerCase();
  return c == 'uk' ? 'gb' : c;
}

const Map<String, String> _zones = {
  // United States
  'America/New_York': 'us', 'America/Detroit': 'us', 'America/Chicago': 'us',
  'America/Menominee': 'us', 'America/Denver': 'us', 'America/Boise': 'us',
  'America/Phoenix': 'us', 'America/Los_Angeles': 'us',
  'America/Anchorage': 'us', 'America/Juneau': 'us', 'America/Sitka': 'us',
  'America/Metlakatla': 'us', 'America/Yakutat': 'us', 'America/Nome': 'us',
  'America/Adak': 'us', 'Pacific/Honolulu': 'us', 'America/Puerto_Rico': 'us',
  // Canada
  'America/Toronto': 'ca', 'America/Montreal': 'ca', 'America/Vancouver': 'ca',
  'America/Edmonton': 'ca', 'America/Winnipeg': 'ca', 'America/Regina': 'ca',
  'America/Halifax': 'ca', 'America/St_Johns': 'ca', 'America/Moncton': 'ca',
  'America/Whitehorse': 'ca', 'America/Yellowknife': 'ca',
  'America/Iqaluit': 'ca', 'America/Glace_Bay': 'ca',
  'America/Swift_Current': 'ca',
  // Europe
  'Europe/London': 'gb', 'Europe/Belfast': 'gb', 'Europe/Dublin': 'ie',
  'Europe/Berlin': 'de', 'Europe/Busingen': 'de', 'Europe/Vienna': 'at',
  'Europe/Zurich': 'ch', 'Europe/Vaduz': 'ch', 'Europe/Paris': 'fr',
  'Europe/Monaco': 'fr', 'Europe/Brussels': 'be', 'Europe/Luxembourg': 'lu',
  'Europe/Amsterdam': 'nl', 'Europe/Rome': 'it', 'Europe/San_Marino': 'it',
  'Europe/Vatican': 'it', 'Europe/Madrid': 'es', 'Atlantic/Canary': 'es',
  'Africa/Ceuta': 'es', 'Europe/Lisbon': 'pt', 'Atlantic/Madeira': 'pt',
  'Atlantic/Azores': 'pt', 'Europe/Warsaw': 'pl', 'Europe/Istanbul': 'tr',
  'Asia/Istanbul': 'tr', 'Europe/Stockholm': 'se', 'Europe/Oslo': 'no',
  'Europe/Copenhagen': 'dk', 'Europe/Helsinki': 'fi', 'Europe/Prague': 'cz',
  'Europe/Budapest': 'hu', 'Europe/Bucharest': 'ro', 'Europe/Athens': 'gr',
  'Europe/Bratislava': 'sk', 'Europe/Ljubljana': 'si', 'Europe/Zagreb': 'hr',
  'Europe/Sofia': 'bg', 'Europe/Tallinn': 'ee', 'Europe/Riga': 'lv',
  'Europe/Vilnius': 'lt', 'Europe/Malta': 'mt', 'Asia/Nicosia': 'cy',
  'Atlantic/Reykjavik': 'is',
  // Latin America
  'America/Sao_Paulo': 'br', 'America/Bahia': 'br', 'America/Fortaleza': 'br',
  'America/Recife': 'br', 'America/Belem': 'br', 'America/Manaus': 'br',
  'America/Cuiaba': 'br', 'America/Campo_Grande': 'br',
  'America/Porto_Velho': 'br', 'America/Boa_Vista': 'br',
  'America/Rio_Branco': 'br', 'America/Maceio': 'br',
  'America/Araguaina': 'br', 'America/Santarem': 'br',
  'America/Noronha': 'br', 'America/Mexico_City': 'mx',
  'America/Monterrey': 'mx', 'America/Merida': 'mx', 'America/Cancun': 'mx',
  'America/Tijuana': 'mx', 'America/Chihuahua': 'mx',
  'America/Hermosillo': 'mx', 'America/Mazatlan': 'mx',
  'America/Buenos_Aires': 'ar', 'America/Santiago': 'cl',
  'America/Bogota': 'co',
  // Asia-Pacific, Middle East, Africa
  'Pacific/Auckland': 'nz', 'Asia/Tokyo': 'jp', 'Asia/Seoul': 'kr',
  'Asia/Shanghai': 'cn', 'Asia/Chongqing': 'cn', 'Asia/Urumqi': 'cn',
  'Asia/Hong_Kong': 'hk', 'Asia/Taipei': 'tw', 'Asia/Kolkata': 'in',
  'Asia/Calcutta': 'in', 'Asia/Dubai': 'ae', 'Asia/Riyadh': 'sa',
  'Africa/Johannesburg': 'za',
};
