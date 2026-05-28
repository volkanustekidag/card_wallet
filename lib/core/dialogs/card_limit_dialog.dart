import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/premium_service.dart';

/// Used to be an AlertDialog with "Maybe later / Go Premium" buttons; now
/// it just opens the paywall directly with the unlimited-cards feature
/// highlighted. Other premium-gated entry points already navigate to
/// `/premium` without an intermediate dialog, so the card-limit path
/// behaves the same way.
///
/// Returns `true` if the user is premium after the paywall closes (i.e.
/// they upgraded), so the caller can resume the add flow without making
/// the user re-click Save.
Future<bool> showCardLimitDialog(
  BuildContext rootContext,
  CardLimitType type,
) async {
  unawaited(AnalyticsService.instance.logCardLimitHit(_analyticsTypeOf(type)));
  await Get.toNamed('/premium', arguments: {
    'feature': 'unlimitedCards',
    'trigger': 'card_limit',
    'card_type': _analyticsTypeOf(type),
  });
  return PremiumService.isPremium;
}

String _analyticsTypeOf(CardLimitType type) {
  switch (type) {
    case CardLimitType.credit:
      return AnalyticsCardType.credit;
    case CardLimitType.iban:
      return AnalyticsCardType.iban;
    case CardLimitType.loyalty:
      return AnalyticsCardType.loyalty;
  }
}
