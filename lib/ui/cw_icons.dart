import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Deckard's own icon set — 24pt grid, 1.8 stroke, round caps.
/// Never mix with Material/Cupertino icons or emoji: the icon family is
/// part of the product's identity. Source files: `assets/icons/cw/`.
enum CwIcons {
  back('back'),
  backspace('backspace'),
  bank('bank'),
  barcode('barcode'),
  bell('bell'),
  calendar('calendar'),
  camera('camera'),
  card('card'),
  check('check'),
  checkCircle('check-circle'),
  chevronDown('chevron-down'),
  chevronRight('chevron-right'),
  clock('clock'),
  close('close'),
  cloudUp('cloud-up'),
  copy('copy'),
  document('document'),
  edit('edit'),
  external('external'),
  eye('eye'),
  eyeOff('eye-off'),
  faceId('face-id'),
  filter('filter'),
  fingerprint('fingerprint'),
  flash('flash'),
  folder('folder'),
  gem('gem'),
  gift('gift'),
  globe('globe'),
  grip('grip'),
  grid('grid'),
  hash('hash'),
  help('help'),
  import('import'),
  infinity('infinity'),
  info('info'),
  keyboard('keyboard'),
  keypad('keypad'),
  link('link'),
  lock('lock'),
  logout('logout'),
  mail('mail'),
  more('more'),
  note('note'),
  offline('offline'),
  palette('palette'),
  phone('phone'),
  photos('photos'),
  plane('plane'),
  plus('plus'),
  qr('qr'),
  restore('restore'),
  rotate('rotate'),
  scan('scan'),
  search('search'),
  settings('settings'),
  share('share'),
  shield('shield'),
  sort('sort'),
  sparkle('sparkle'),
  stack('stack'),
  star('star'),
  starFill('star-fill'),
  sun('sun'),
  swap('swap'),
  tag('tag'),
  theme('theme'),
  trash('trash'),
  unlock('unlock'),
  user('user'),
  wallet('wallet'),
  walletPass('wallet-pass'),
  warning('warning'),
  ;

  const CwIcons(this.file);
  final String file;
  String get asset => 'assets/icons/cw/$file.svg';
}

/// Icon sizes. Keep to these four so the UI stays rhythmically consistent.
class CwIconSize {
  CwIconSize._();
  static const double s = 16;
  static const double m = 20;
  static const double l = 24;
  static const double xl = 28;
}

class CwIcon extends StatelessWidget {
  final CwIcons icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  const CwIcon(
    this.icon, {
    super.key,
    this.size = CwIconSize.l,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
