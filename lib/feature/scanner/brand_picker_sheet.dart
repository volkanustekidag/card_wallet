import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/ui/components/cw_field.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Result of [showBrandPicker]: a catalogue brand, or [clear] for "no
/// brand, keep my own name".
class BrandPick {
  final BrandEntry? brand;
  final bool clear;
  const BrandPick.brand(BrandEntry this.brand) : clear = false;
  const BrandPick.none()
      : brand = null,
        clear = true;
}

/// Searchable list of the brand catalogue, local brands first.
Future<BrandPick?> showBrandPicker(BuildContext context, {String initial = ''}) {
  return showCwSheet<BrandPick>(
    context,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _BrandPicker(initial: initial),
    ),
  );
}

class _BrandPicker extends StatefulWidget {
  final String initial;
  const _BrandPicker({required this.initial});

  @override
  State<_BrandPicker> createState() => _BrandPickerState();
}

class _BrandPickerState extends State<_BrandPicker> {
  late final TextEditingController _q =
      TextEditingController(text: widget.initial);

  @override
  void initState() {
    super.initState();
    if (!BrandCatalog.instance.isLoaded) {
      BrandCatalog.instance.load().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final results = BrandCatalog.instance.search(_q.text, limit: 60);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
          child: CwField(
            controller: _q,
            label: 'cwChooseBrand'.tr(),
            hint: 'cwSearchBrands'.tr(),
            icon: CwIcons.search,
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              CwGroup(
                children: [
                  CwRow(
                    leading: CwIconTile(CwIcons.edit, color: c.mute),
                    title: 'cwNoBrand'.tr(),
                    onTap: () =>
                        Navigator.pop(context, const BrandPick.none()),
                  ),
                  for (final b in results)
                    CwRow(
                      key: ValueKey(b.name),
                      leading: _BrandLogo(entry: b),
                      title: b.name,
                      subtitle: b.domain,
                      onTap: () => Navigator.pop(context, BrandPick.brand(b)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final BrandEntry entry;
  const _BrandLogo({required this.entry});

  @override
  Widget build(BuildContext context) {
    final bg = Color(entry.color);
    final fallback = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        entry.name.characters.take(1).toString().toUpperCase(),
        style: CwType.callout.copyWith(
          color: bg.computeLuminance() > 0.55 ? Colors.black : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final px = (32 * MediaQuery.devicePixelRatioOf(context)).round();
    return CachedNetworkImage(
      imageUrl: BankLogo.logoUrlFor(entry.domain),
      memCacheWidth: px,
      width: 32,
      height: 32,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
      imageBuilder: (_, img) => Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: CwColors.of(context).line),
        ),
        child: Image(image: img, fit: BoxFit.contain),
      ),
    );
  }
}
