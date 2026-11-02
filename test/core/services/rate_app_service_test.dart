import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/services/rate_app_service.dart';

void main() {
  bool ask({int seconds = 5, int checkouts = 3, int days = 2}) =>
      RateAppService.shouldAskAfterCheckout(
        shownFor: Duration(seconds: seconds),
        checkouts: checkouts,
        daysSinceInstall: days,
      );

  test('asks after the third real checkout, two days in', () {
    expect(ask(), isTrue);
    expect(ask(checkouts: 7, days: 30), isTrue);
  });

  test('a peek is not a checkout', () {
    expect(ask(seconds: 1), isFalse);
  });

  test('not before the third checkout', () {
    expect(ask(checkouts: 2), isFalse);
  });

  test('not in the first two days', () {
    expect(ask(days: 1), isFalse);
  });
}
