import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/feature/import/importers.dart';

Uint8List _zip(Map<String, String> files) {
  final a = Archive();
  files.forEach((name, text) {
    final data = utf8.encode(text);
    a.addFile(ArchiveFile(name, data.length, data));
  });
  return Uint8List.fromList(ZipEncoder().encode(a)!);
}

void main() {
  const catimaV2 = '2\n\n'
      '_id,name\n1,Food\n\n'
      '_id,store,note,validfrom,expiry,balance,balancetype,cardid,barcodeid,barcodetype,headercolor,starstatus,lastused,archive\n'
      '1,Coffee Club,"gold, member",,,0,,6061234567890123,,QR_CODE,-15132304,1,0,0\n'
      '2,Carrefour,,,,0,,3760012345670,,EAN_13,,0,0,0\n'
      '\ncardId,groupId\n1,1\n';

  test('Catima v2 csv: sections, quoted note, colour', () {
    final r = Importers.parse('catima.csv', Uint8List.fromList(utf8.encode(catimaV2)));
    expect(r.source, ImportSource.catima);
    expect(r.cards, hasLength(2));
    expect(r.cards.first.name, 'Coffee Club');
    expect(r.cards.first.format, 'QR_CODE');
    expect(r.cards.first.note, 'gold, member');
    expect(r.cards.first.color, 0xFF191970);
    expect(r.cards[1].format, 'EAN_13');
    expect(r.cards[1].barcodeValid, isTrue);
  });

  test('Catima zip export', () {
    final r = Importers.parse('export.zip', _zip({'catima.csv': catimaV2}));
    expect(r.source, ImportSource.catima);
    expect(r.cards, hasLength(2));
  });

  test('Stocard data export zip with provider names', () {
    final r = Importers.parse(
      'stocard.zip',
      _zip({
        'u/loyalty-card-providers/42.json': jsonEncode({'name': 'IKEA Family', 'logo_url': 'x'}),
        'u/loyalty-cards/a.json': jsonEncode({
          'input_id': '62759801234567',
          'input_barcode_format': 'CODE128',
          'input_provider_reference': {'identifier': '/loyalty-card-providers/42'},
        }),
        'u/loyalty-cards/b.json': jsonEncode({
          'input_id': '3760012345670',
          'custom_name': 'Supermarket',
        }),
      }),
    );
    expect(r.source, ImportSource.stocard);
    final names = r.cards.map((c) => c.name).toSet();
    expect(names, {'IKEA Family', 'Supermarket'});
    expect(r.cards.firstWhere((c) => c.name == 'Supermarket').format, 'EAN_13');
  });

  test('FidMe-style semicolon csv', () {
    const csv = 'Retailer;Program Name;Card Number;Card Note\n'
        'Sephora;Beauty;5012345678900;\nFnac;Fnac+;123456789;old one\n';
    final r = Importers.parse('fidme.csv', Uint8List.fromList(utf8.encode(csv)));
    expect(r.source, ImportSource.fidme);
    expect(r.cards.map((c) => c.name), ['Sephora', 'Fnac']);
    expect(r.cards.last.note, 'old one');
    expect(r.cards.last.format, 'CODE_128');
  });

  test('pkpass', () {
    final r = Importers.parse(
      'coffee.pkpass',
      _zip({
        'pass.json': jsonEncode({
          'organizationName': 'Coffee Co',
          'backgroundColor': 'rgb(13, 79, 59)',
          'barcodes': [
            {'message': 'ABC-123', 'format': 'PKBarcodeFormatQR'}
          ],
        }),
      }),
    );
    expect(r.source, ImportSource.pkpass);
    expect(r.cards.single.name, 'Coffee Co');
    expect(r.cards.single.format, 'QR_CODE');
    expect(r.cards.single.color, 0xFF0D4F3B);
  });

  test('unreadable input', () {
    expect(() => Importers.parse('x.csv', Uint8List.fromList(utf8.encode('hello\nworld'))),
        throwsA(isA<ImportUnsupported>()));
  });
}
