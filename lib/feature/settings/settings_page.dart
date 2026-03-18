import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/widgets/premium_banner_ad_widget.dart';
import 'package:wallet_app/feature/settings/widgets/settings_app_bar.dart';
import 'package:wallet_app/feature/settings/widgets/settings_body.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currentLanguage = '';

  @override
  void initState() {
    super.initState();
    _currentLanguage = '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if language changed and force rebuild if needed
    final currentLang = context.locale.languageCode;
    if (_currentLanguage != currentLang) {
      print('Language changed from $_currentLanguage to $currentLang');
      _currentLanguage = currentLang;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        'SettingsPage rebuilding with language: ${context.locale.languageCode}');

    return Scaffold(
      key: ValueKey(
          'settings_${context.locale.languageCode}'), // Force rebuild on language change
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const SettingsAppBar(),
      body: const Column(
        children: [
          Expanded(
            child: SettingsBody(),
          ),
          PremiumBannerAdWidget(),
        ],
      ),
    );
  }
}
