enum CardLimitType {
  credit,
  iban,
  loyalty,
}

extension CardLimitTypeLocalization on CardLimitType {
  String get localizationKey {
    switch (this) {
      case CardLimitType.credit:
        return 'cardLimitCardTypeCredit';
      case CardLimitType.iban:
        return 'cardLimitCardTypeIban';
      case CardLimitType.loyalty:
        return 'cardLimitCardTypeLoyalty';
    }
  }
}
