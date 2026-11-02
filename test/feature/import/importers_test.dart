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
    final r = Importers.parse(
        'catima.csv', Uint8List.fromList(utf8.encode(catimaV2)));
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

  // Paths and JSON as in a real Stocard GDPR export (the sample Catima
  // used for its importer tests), trimmed to the files we read plus a few
  // we must ignore.
  const user = '50e33e49-cfa0-49ad-a297-c1d655f72b01';
  const root = 'extracts/$user/users/$user';
  final stocardExport = {
    '$root/analytics-properties/content.json': '{"os": "android"}',
    '$root/devices/bf54f5e8/content.json': '{"name": "Pixel"}',
    // Catalogue provider, name on the card, DataBar format we can't draw.
    '$root/loyalty-cards/e6b48666/content.json': jsonEncode({
      'input_barcode_format': 'RSS_DATABAR_EXPANDED',
      'input_id': '(01)09010374000019(21)02097564604859211217(10)01231287693',
      'input_provider_reference': {
        'identifier':
            '/loyalty-card-providers/63536738-d64b-48ae-aeb8-82761523fa67'
      },
      'input_type': 'BARCODE_SCANNER',
      'input_provider_name': 'jö',
    }),
    '$root/loyalty-cards/e6b48666/usage-statistics/content.json': jsonEncode({
      'usages': [
        {
          'time': {'value': '2021-06-29T18:30:43.530Z'}
        },
        {
          'time': {'value': '2021-04-03T10:14:17.515Z'}
        },
      ],
    }),
    // Empty label, no format: guessed from the number.
    '$root/loyalty-cards/c380e80b/content.json': jsonEncode({
      'input_id': '4006381333931',
      'input_provider_reference': {'identifier': '/loyalty-card-providers/841'},
      'input_type': 'MANUAL',
      'label': '',
      'input_provider_name': 'GAMMA',
    }),
    // Usage folder without a card: ignored.
    '$root/loyalty-cards/ba981200/usage-statistics/content.json':
        '{"usages": [{"time": {"value": "2021-07-06T19:36:11.041Z"}}]}',
    // Custom provider, single-usage files.
    '$root/loyalty-cards/7f1489b6/content.json': jsonEncode({
      'input_barcode_format': 'ITF',
      'input_id': '1234567895',
      'input_provider_reference': {
        'identifier': '/users/$user/loyalty-card-custom-providers/a0ae58c4'
      },
      'input_type': 'BARCODE_SCANNER',
    }),
    '$root/loyalty-cards/7f1489b6/usages/bd0028c7/content.json': jsonEncode({
      'gps_location': 'none of your business',
      'time': {'value': '2021-06-29T18:30:39.173Z'},
    }),
    '$root/loyalty-card-custom-providers/a0ae58c4/content.json':
        '{"name": "Foo"}',
    // Old export: no provider name, only a label; plus a note.
    '$root/loyalty-cards/8c76762a/content.json': jsonEncode({
      'input_id': '7649484',
      'input_provider_reference': {'identifier': '/loyalty-card-providers/820'},
      'input_type': 'MANUAL',
      'label': 'Miles',
    }),
    '$root/loyalty-cards/8c76762a/notes/default/content.json':
        '{"content": "szjsbs"}',
    '$root/loyalty-cards/8c76762a/points-account/content.json':
        '{"balance": 12}',
  };

  test('Stocard GDPR export', () {
    final r = Importers.parse('stocard.zip', _zip(stocardExport));
    expect(r.source, ImportSource.stocard);
    expect(r.cards.map((c) => c.name), ['Foo', 'Miles', 'GAMMA', 'jö']);

    final foo = r.cards[0];
    expect(foo.barcode, '1234567895');
    expect(foo.format, 'ITF');
    expect(foo.usedAt, [DateTime.utc(2021, 6, 29, 18, 30, 39, 173)]);

    final miles = r.cards[1];
    expect(miles.note, 'szjsbs');
    expect(miles.format, 'CODE_128');
    expect(miles.usedAt, isEmpty);

    final gamma = r.cards[2];
    expect(gamma.format, 'EAN_13');
    expect(gamma.note, isNull);

    final jo = r.cards[3];
    expect(jo.barcode, startsWith('(01)0901'));
    expect(jo.format, 'CODE_128');
    expect(jo.usedAt.first.isBefore(jo.usedAt.last), isTrue);
  });

  test('Stocard label differing from the store goes to the note', () {
    final cards = Importers.stocardFromFiles({
      '$root/loyalty-cards/x/content.json': jsonEncode({
        'input_id': '123',
        'input_provider_name': 'Air Miles',
        'label': 'Mum',
        'input_provider_reference': {
          'identifier': '/loyalty-card-providers/820'
        },
      }),
      '$root/loyalty-cards/x/notes/default/content.json': '{"content": "gold"}',
    });
    expect(cards.single.name, 'Air Miles');
    expect(cards.single.note, 'gold\nMum');
  });

  test('Stocard export behind a password', () {
    final a = Archive();
    stocardExport.forEach((name, text) {
      final data = utf8.encode(text);
      a.addFile(ArchiveFile(name, data.length, data));
    });
    final bytes = Uint8List.fromList(ZipEncoder(password: 'pw').encode(a)!);
    expect(() => Importers.parse('stocard.zip', bytes),
        throwsA(isA<ImportNeedsPassword>()));
    expect(Importers.parse('stocard.zip', bytes, password: 'pw').cards,
        hasLength(4));
  });

  test('FidMe-style semicolon csv', () {
    const csv = 'Retailer;Program Name;Card Number;Card Note\n'
        'Sephora;Beauty;5012345678900;\nFnac;Fnac+;123456789;old one\n';
    final r =
        Importers.parse('fidme.csv', Uint8List.fromList(utf8.encode(csv)));
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
    expect(
        () => Importers.parse(
            'x.csv', Uint8List.fromList(utf8.encode('hello\nworld'))),
        throwsA(isA<ImportUnsupported>()));
  });
}
