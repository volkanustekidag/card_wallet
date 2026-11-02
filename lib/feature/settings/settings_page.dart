import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/feature/settings/widgets/settings_body.dart';
import 'package:wallet_app/ui/tokens.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CwPageStyle(
      child: Scaffold(
        // Rebuild every row when the language changes.
        key: ValueKey('settings_${context.locale.languageCode}'),
        backgroundColor: CwColors.of(context).bg,
        body: const SettingsBody(),
      ),
    );
  }
}
