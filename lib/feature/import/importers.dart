import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_validator.dart';

/// A loyalty card read from another app's export.
class ImportedCard {
  final String name;
  final String barcode;
  final String format;
  final int? color;
  final String? note;

  const ImportedCard({
    required this.name,
    required this.barcode,
    required this.format,
    this.color,
    this.note,
  });

  bool get barcodeValid =>
      LoyaltyBarcodeValidator.validate(barcode, format).isValid;
}

enum ImportSource { catima, stocard, fidme, pkpass, csv }

class ImportResult {
  final ImportSource source;
  final List<ImportedCard> cards;
  const ImportResult(this.source, this.cards);
}

/// The zip is password-protected (Catima can encrypt its export).
class ImportNeedsPassword implements Exception {
  const ImportNeedsPassword();
}

/// Nothing we could read.
class ImportUnsupported implements Exception {
  const ImportUnsupported();
}

/// Reads exports of Catima, Stocard (Klarna data export), FidMe, Apple
/// Wallet passes and plain CSV files. Pure Dart; never touches the network.
abstract final class Importers {
  static ImportResult parse(String filename, Uint8List bytes,
      {String? password}) {
    final lower = filename.toLowerCase();
    final isZip = bytes.length > 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B; // "PK"
    if (isZip) return _parseZip(lower, bytes, password);
    final text = _decodeText(bytes);
    if (lower.endsWith('.json')) {
      final cards = stocardFromJson({filename: text});
      if (cards.isNotEmpty) return ImportResult(ImportSource.stocard, cards);
    }
    final catima = catimaFromCsv(text);
    if (catima != null) return ImportResult(ImportSource.catima, catima);
    final generic = genericCsv(text);
    if (generic.isNotEmpty) {
      return ImportResult(
        _looksLikeFidme(text) ? ImportSource.fidme : ImportSource.csv,
        generic,
      );
    }
    throw const ImportUnsupported();
  }

  static ImportResult _parseZip(String name, Uint8List bytes, String? pw) {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, password: pw, verify: true);
    } catch (_) {
      throw const ImportNeedsPassword();
    }
    final files = <String, String>{};
    Uint8List? passJson;
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final n = f.name.toLowerCase();
      List<int> content;
      try {
        content = f.content as List<int>;
      } catch (_) {
        throw const ImportNeedsPassword();
      }
      if (n.endsWith('pass.json')) passJson = Uint8List.fromList(content);
      if (n.endsWith('.csv') || n.endsWith('.json') || n.endsWith('.txt')) {
        files[f.name] = _decodeText(content);
      }
    }
    if (passJson != null) {
      final card = pkpassFromJson(_decodeText(passJson));
      if (card != null) return ImportResult(ImportSource.pkpass, [card]);
    }
    for (final e in files.entries) {
      if (!e.key.toLowerCase().endsWith('.csv')) continue;
      final catima = catimaFromCsv(e.value);
      if (catima != null) return ImportResult(ImportSource.catima, catima);
    }
    final stocard = stocardFromJson(files);
    if (stocard.isNotEmpty) return ImportResult(ImportSource.stocard, stocard);
    for (final e in files.entries) {
      if (!e.key.toLowerCase().endsWith('.csv')) continue;
      final g = genericCsv(e.value);
      if (g.isNotEmpty) {
        return ImportResult(
            _looksLikeFidme(e.value) ? ImportSource.fidme : ImportSource.csv,
            g);
      }
    }
    if (name.endsWith('.pkpass')) throw const ImportUnsupported();
    throw const ImportUnsupported();
  }

  // ---------------------------------------------------------------- Catima

  /// Catima `catima.csv`: v2 has a version line and blank-line separated
  /// sections (groups, cards, card-groups); v1 is a single card table.
  static List<ImportedCard>? catimaFromCsv(String text) {
    final rows = parseCsv(text);
    var i = 0;
    while (i < rows.length) {
      final header = rows[i].map((h) => h.trim().toLowerCase()).toList();
      if (header.contains('store') && header.contains('cardid')) {
        final out = <ImportedCard>[];
        for (var r = i + 1; r < rows.length; r++) {
          final row = rows[r];
          if (row.length == 1 && row.first.trim().isEmpty) break;
          String col(String k) {
            final idx = header.indexOf(k);
            return idx >= 0 && idx < row.length ? row[idx].trim() : '';
          }

          final number = col('cardid');
          if (number.isEmpty) continue;
          final colorRaw = int.tryParse(col('headercolor'));
          final barcodeId = col('barcodeid');
          out.add(ImportedCard(
            name: col('store').isEmpty ? number : col('store'),
            barcode: barcodeId.isNotEmpty ? barcodeId : number,
            format: mapFormat(col('barcodetype'), barcodeId.isNotEmpty ? barcodeId : number),
            color: colorRaw == null ? null : (colorRaw & 0xFFFFFFFF) | 0xFF000000,
            note: col('note').isEmpty ? null : col('note'),
          ));
        }
        return out;
      }
      i++;
    }
    return null;
  }

  // --------------------------------------------------------------- Stocard

  /// Stocard / Klarna data export: one JSON per card with `input_id`
  /// (the number) and a provider reference; provider JSONs carry names.
  static List<ImportedCard> stocardFromJson(Map<String, String> files) {
    final providers = <String, String>{};
    final cards = <Map<String, dynamic>>[];
    void visit(dynamic node, String path) {
      if (node is List) {
        for (final n in node) {
          visit(n, path);
        }
      } else if (node is Map<String, dynamic>) {
        if (node.containsKey('input_id')) {
          cards.add(node);
        } else if (node['name'] is String &&
            (path.contains('provider') || node.containsKey('logo_url'))) {
          final id = (node['id'] ?? path.split('/').last.split('.').first)
              .toString();
          providers[id] = node['name'] as String;
        }
        for (final v in node.values) {
          if (v is Map || v is List) visit(v, path);
        }
      }
    }

    for (final e in files.entries) {
      if (!e.key.toLowerCase().endsWith('.json')) continue;
      try {
        visit(jsonDecode(e.value), e.key.toLowerCase());
      } catch (_) {}
    }
    final out = <ImportedCard>[];
    for (final c in cards) {
      final number = '${c['input_id']}'.trim();
      if (number.isEmpty) continue;
      String? name = (c['custom_name'] ?? c['label'] ?? c['name']) as String?;
      final ref = c['input_provider_reference'];
      final refId = ref is Map ? '${ref['identifier'] ?? ''}' : '${ref ?? ''}';
      if (name == null && refId.isNotEmpty) {
        name = providers[refId.split('/').last] ?? providers[refId];
      }
      name ??= (c['input_provider_name'] as String?);
      out.add(ImportedCard(
        name: (name == null || name.isEmpty) ? number : name,
        barcode: number,
        format: mapFormat('${c['input_barcode_format'] ?? ''}', number),
      ));
    }
    return out;
  }

  // ---------------------------------------------------------------- pkpass

  /// Apple Wallet `pass.json`.
  static ImportedCard? pkpassFromJson(String text) {
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      Map<String, dynamic>? barcode;
      if (j['barcodes'] is List && (j['barcodes'] as List).isNotEmpty) {
        barcode = (j['barcodes'] as List).first as Map<String, dynamic>;
      } else if (j['barcode'] is Map) {
        barcode = j['barcode'] as Map<String, dynamic>;
      }
      final message = barcode?['message']?.toString().trim() ?? '';
      if (message.isEmpty) return null;
      final name = [j['organizationName'], j['logoText'], j['description']]
          .whereType<String>()
          .firstWhere((s) => s.trim().isNotEmpty, orElse: () => message);
      return ImportedCard(
        name: name.trim(),
        barcode: message,
        format: mapFormat('${barcode?['format'] ?? ''}', message),
        color: _rgb(j['backgroundColor']?.toString()),
      );
    } catch (_) {
      return null;
    }
  }

  static int? _rgb(String? css) {
    if (css == null) return null;
    final m = RegExp(r'rgba?\((\d+),\s*(\d+),\s*(\d+)').firstMatch(css);
    if (m != null) {
      return 0xFF000000 |
          (int.parse(m[1]!) << 16) |
          (int.parse(m[2]!) << 8) |
          int.parse(m[3]!);
    }
    final hex = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(css.trim());
    return hex == null ? null : 0xFF000000 | int.parse(hex[1]!, radix: 16);
  }

  // ------------------------------------------------------------ generic CSV

  static const _nameCols = [
    'store', 'name', 'card name', 'retailer', 'program name', 'merchant',
    'brand', 'shop', 'enseigne', 'nom', 'magasin', 'title', 'label',
  ];
  static const _numberCols = [
    'cardid', 'card number', 'card_number', 'number', 'barcode', 'code',
    'reference', 'numéro', 'numero', 'card no', 'card id', 'member number',
  ];
  static const _formatCols = ['barcodetype', 'barcode type', 'format', 'type'];
  static const _noteCols = ['note', 'notes', 'card note', 'comment'];

  /// Any CSV with recognisable name / number columns (FidMe and others).
  static List<ImportedCard> genericCsv(String text) {
    final rows = parseCsv(text);
    for (var h = 0; h < rows.length && h < 5; h++) {
      final header = rows[h].map((s) => s.trim().toLowerCase()).toList();
      int find(List<String> keys) {
        for (final k in keys) {
          final i = header.indexOf(k);
          if (i >= 0) return i;
        }
        return -1;
      }

      final ni = find(_nameCols), ci = find(_numberCols);
      if (ni < 0 || ci < 0) continue;
      final fi = find(_formatCols), oi = find(_noteCols);
      final out = <ImportedCard>[];
      for (final row in rows.skip(h + 1)) {
        if (row.length <= ci) continue;
        final number = row[ci].trim();
        if (number.isEmpty) continue;
        final name = ni < row.length ? row[ni].trim() : '';
        out.add(ImportedCard(
          name: name.isEmpty ? number : name,
          barcode: number,
          format: mapFormat(
              fi >= 0 && fi < row.length ? row[fi] : '', number),
          note: oi >= 0 && oi < row.length && row[oi].trim().isNotEmpty
              ? row[oi].trim()
              : null,
        ));
      }
      return out;
    }
    return const [];
  }

  static bool _looksLikeFidme(String text) =>
      text.toLowerCase().contains('retailer') ||
      text.toLowerCase().contains('fidme');

  /// Foreign barcode format names (ZXing, PassKit, Stocard) to ours. Empty
  /// or unknown: guessed from the value (valid EAN/UPC, else Code 128).
  static String mapFormat(String raw, String value) {
    final k = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    const map = {
      'CODE128': 'CODE_128', 'CODE39': 'CODE_39', 'CODE93': 'CODE_93',
      'EAN13': 'EAN_13', 'EAN8': 'EAN_8', 'UPCA': 'UPC_A', 'UPCE': 'UPC_E',
      'QR': 'QR_CODE', 'QRCODE': 'QR_CODE', 'ITF': 'ITF', 'ITF14': 'ITF',
      'PDF417': 'PDF417', 'AZTEC': 'AZTEC', 'DATAMATRIX': 'DATA_MATRIX',
      'CODABAR': 'CODABAR', 'PKBARCODEFORMATQR': 'QR_CODE',
      'PKBARCODEFORMATPDF417': 'PDF417', 'PKBARCODEFORMATAZTEC': 'AZTEC',
      'PKBARCODEFORMATCODE128': 'CODE_128',
    };
    final mapped = map[k];
    if (mapped != null) return mapped;
    final v = value.trim();
    for (final f in const ['EAN_13', 'EAN_8', 'UPC_A']) {
      if (LoyaltyBarcodeValidator.validate(v, f).isValid) return f;
    }
    return 'CODE_128';
  }

  /// Minimal RFC 4180 CSV reader; also handles `;` and tab separators.
  static List<List<String>> parseCsv(String text) {
    final firstLine = text.split('\n').firstWhere(
        (l) => l.trim().length > 1,
        orElse: () => '');
    final sep = [';', '\t', ','].reduce((a, b) =>
        firstLine.split(a).length >= firstLine.split(b).length ? a : b);
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(ch);
        }
      } else if (ch == '"') {
        quoted = true;
      } else if (ch == sep) {
        row.add(cell.toString());
        cell.clear();
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else {
        cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }

  static String _decodeText(List<int> bytes) {
    var b = bytes;
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
      b = b.sublist(3);
    }
    try {
      return utf8.decode(b);
    } catch (_) {
      return latin1.decode(b);
    }
  }
}
