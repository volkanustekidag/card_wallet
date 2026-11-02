import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

class ChangePinAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChangePinAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      systemOverlayStyle: cwOverlayStyle(context),
      centerTitle: true,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: CwIcon(CwIcons.back, color: CwColors.of(context).ink),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text('chanPIN'.tr(),
          style: CwType.headline.copyWith(color: CwColors.of(context).ink)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
