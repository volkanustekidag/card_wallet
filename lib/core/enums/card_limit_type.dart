enum CardLimitType {
  credit,
  iban,
}

extension CardLimitTypeLocalization on CardLimitType {
  String get localizationKey {
    switch (this) {
      case CardLimitType.credit:
        return 'cardLimitCardTypeCredit';
      case CardLimitType.iban:
        return 'cardLimitCardTypeIban';
    }
  }
}
