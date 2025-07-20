import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/feature/settings/widgets/settings_app_bar.dart';
import 'package:wallet_app/feature/settings/widgets/settings_body.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const SettingsAppBar(),
      body: const SettingsBody(),
    );
  }
}
