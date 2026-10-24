import 'package:flutter/material.dart';

/// The flying copy of a card between Home and its page. A hero flies in the
/// navigator's overlay, above every Material, so its text would fall back to
/// the debug style (yellow double underline) until it lands. The shuttle
/// gives it a transparent Material, i.e. the app's text style.
Widget cardHeroShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final hero = toHeroContext.widget as Hero;
  return Material(type: MaterialType.transparency, child: hero.child);
}
