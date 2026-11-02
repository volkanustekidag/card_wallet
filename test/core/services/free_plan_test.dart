import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/services/premium_service.dart';

void main() {
  test('free plan: 3 loyalty cards, 1 bank card, 1 IBAN', () {
    expect(PremiumService.freeLimitFor(CardLimitType.loyalty), 3);
    expect(PremiumService.freeLimitFor(CardLimitType.credit), 1);
    expect(PremiumService.freeLimitFor(CardLimitType.iban), 1);

    expect(PremiumService.canAddMoreLoyaltyCards(2), isTrue);
    expect(PremiumService.canAddMoreLoyaltyCards(3), isFalse);
    expect(PremiumService.canAddMoreCreditCards(0), isTrue);
    expect(PremiumService.canAddMoreCreditCards(1), isFalse);
    expect(PremiumService.canAddMoreIbanCards(0), isTrue);
    expect(PremiumService.canAddMoreIbanCards(1), isFalse);
    // Someone who already had 5 (old plan) just can't add a 6th.
    expect(PremiumService.canAddMoreLoyaltyCards(5), isFalse);
  });
}
