import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/feature/settings/widgets/settings_body.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/cw_icons.dart';
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
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CwCircleButton(
                    CwIcons.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                    semanticLabel:
                        MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                ),
              ),
              const Expanded(child: SettingsBody()),
            ],
          ),
        ),
      ),
    );
  }
}
