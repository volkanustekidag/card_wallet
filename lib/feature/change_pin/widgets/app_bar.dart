import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/ui/cw_icons.dart';
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
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: true,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const CwIcon(CwIcons.back, color: Colors.white),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text('chanPIN'.tr(),
          style: CwType.headline.copyWith(color: Colors.white)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
