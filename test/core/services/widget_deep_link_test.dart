import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/services/widget_deep_link_handler.dart';

String? _id(String uri) =>
    WidgetDeepLinkHandler.loyaltyCardIdFromUri(Uri.parse(uri));

void main() {
  test('reads the card id from widget and quick tile links', () {
    expect(_id('cardwallet://loyalty?id=abc-123'), 'abc-123');
    expect(_id('cardwallet://loyalty?homeWidget=1&id=abc-123'), 'abc-123');
    expect(_id('cardwallet://loyalty?id=a%20b'), 'a b');
  });

  test('rejects other schemes and hosts', () {
    expect(_id('https://loyalty?id=abc'), isNull);
    expect(_id('cardwallet://credit?id=abc'), isNull);
    expect(_id('cardwallet://iban?id=abc'), isNull);
  });

  test('rejects links without an id', () {
    expect(_id('cardwallet://loyalty'), isNull);
    expect(_id('cardwallet://loyalty?homeWidget=1'), isNull);
    expect(_id('cardwallet://loyalty?id='), isNull);
    expect(_id('cardwallet://loyalty?id=%20'), isNull);
  });
}
